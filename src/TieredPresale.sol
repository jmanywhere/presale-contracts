// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./interface/ITieredPresale.sol";
import "./interface/IUniswapV2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "forge-std/console.sol";

error TPresale__InvalidSetup();
error TPresale__CouldNotTransfer(address _token, uint amount);
error TPresale__SaleEnded();
error TPresale__InvalidDepositAmount();

contract TieredPresale is ITieredPresale, Ownable, ReentrancyGuard {
    //-----------------------------------------------------------------------------------
    // GLOBAL STATE
    //-----------------------------------------------------------------------------------
    mapping(uint8 layerId => LayerInfo) public layer;
    mapping(uint8 layerId => address[] users) public layerUsers;
    mapping(uint8 layerId => mapping(address user => UserLayerInfo))
        public userLayer;
    uint256 public constant BASIS_POINTS = 100;
    uint256 public totalTokensToSell;
    uint256 public receiveForLiquidity;
    uint256 public receiveForReferral;
    uint256 public receiveForPrevLayer;
    address public saleToken;
    address public receiveToken;
    address public saleoOwnerWallet;
    address public router;
    uint256 public uniqueInvestorCount;
    uint8 public immutable totalLayers;
    uint8 public immutable gridsPerLayer;
    uint8 private offsetLayer = 1;
    Status private status = Status.PENDING;

    //-----------------------------------------------------------------------------------
    // CONSTRUCTOR
    //-----------------------------------------------------------------------------------
    /**
     * @notice CONSTRUCTOR
     * @param gridInfo Grid settings
     * [0] totalLayers
     * [1] totalGridsPerLayer
     * LAYER ONE
     * [2] liquidityBasisPoints
     * [3] referralBasisPoints
     * OTHER LAYERS
     * [4] liquidityBasisPoints
     * [5] referralBasisPoints
     * [6] previousLayerBasisPoints
     * @param layerCreateInfo Layer settings
     * LAYER ONE
     * [0] startBlock
     * [1] blockDuration
     * [2] pricePerGrid
     * [3] tokensPerGrid
     * OTHER LAYERS
     * [4] blockDuration
     * [5] pricePerGrid
     * [6] tokensPerGrid
     * @param addressConfig Addresses relevant for configurations
     * [0] saleToken
     * [1] receiveToken
     * [2] saleOwner
     * [3] routerToUse
     */
    constructor(
        uint8[] memory gridInfo,
        uint256[] memory layerCreateInfo,
        address[] memory addressConfig
    ) Ownable(msg.sender) {
        saleToken = addressConfig[0];
        receiveToken = addressConfig[1];
        router = addressConfig[3];
        if (IUniswapV2Router02(router).WETH() == address(0))
            revert TPresale__InvalidSetup();
        totalLayers = gridInfo[0];
        gridsPerLayer = gridInfo[1];
        // Check the Grid Info has the correct length
        uint256 configLength = gridInfo.length;

        configLength -= 4;
        if (totalLayers > 1 && configLength % 3 != 0) {
            revert TPresale__InvalidSetup();
        }
        // Check that layerCreateInfo has the correct length
        configLength = layerCreateInfo.length;
        configLength -= 4;
        if (totalLayers > 1 && configLength % 3 != 0) {
            revert TPresale__InvalidSetup();
        }

        // SETUP LAYER 1 - Layer 0 is always empty
        LayerInfo storage setupLayer = layer[1];
        uint256 totalGridsPerLayer = uint256(gridsPerLayer) ** 2;
        uint tokensToSell = layerCreateInfo[3] * totalGridsPerLayer;
        uint totalTokens = tokensToSell;
        // Setup LAYER 1
        setupLayer.startBlock = layerCreateInfo[0];
        setupLayer.endBlock = layerCreateInfo[0] + layerCreateInfo[1];
        setupLayer.pricePerGrid = layerCreateInfo[2];
        setupLayer.tokensToSell = tokensToSell;
        layerUsers[1] = new address[](totalGridsPerLayer);
        setupLayer.liquidityBasisPoints = gridInfo[2];
        setupLayer.referralBasisPoints = gridInfo[3];
        setupLayer.previousLayerBasisPoints = 0;
        uint addedBasis = gridInfo[2] + gridInfo[3];
        if (addedBasis > BASIS_POINTS) revert TPresale__InvalidSetup();
        // Setup LAYER 2 and above
        for (uint8 i = 2; i <= totalLayers; i++) {
            setupLayer = layer[i];
            uint8 offset = (3 * i) - 2;
            tokensToSell = layerCreateInfo[offset + 2] * totalGridsPerLayer;
            totalTokens += tokensToSell;

            setupLayer.startBlock = layer[i - 1].endBlock;
            setupLayer.endBlock =
                setupLayer.startBlock +
                layerCreateInfo[offset];
            setupLayer.pricePerGrid = layerCreateInfo[offset + 1];
            setupLayer.tokensToSell = tokensToSell;
            layerUsers[i] = new address[](totalGridsPerLayer);
            setupLayer.liquidityBasisPoints = gridInfo[offset];
            setupLayer.referralBasisPoints = gridInfo[offset + 1];
            setupLayer.previousLayerBasisPoints = gridInfo[offset + 2];
            addedBasis =
                gridInfo[offset] +
                gridInfo[offset + 1] +
                gridInfo[offset + 2];
            if (addedBasis > BASIS_POINTS) revert TPresale__InvalidSetup();
            setupLayer.prevLayerId = i - 1;
        }
        // Factory should transfer this amount of tokens, to this contract
        totalTokensToSell = totalTokens;
    }

    //-----------------------------------------------------------------------------------
    // EXTERNAL/PUBLIC FUNCTIONS
    //-----------------------------------------------------------------------------------

    function deposit(address referral) external payable {
        if (currentLayerId() == 0 || saleStatus() != Status.IN_PROGRESS) {
            revert TPresale__InvalidSetup();
        }
        // checks that the offset is shifted to the next layer
        checkForNextLayer(true);
        LayerInfo storage currentLayerInfo = layer[offsetLayer];
        UserLayerInfo storage userInfo = userLayer[offsetLayer][msg.sender];

        currentLayerInfo.gridsOccupied++;
        layerUsers[offsetLayer][currentLayerInfo.gridsOccupied - 1] = msg
            .sender;
        userInfo.totalDeposit += currentLayerInfo.pricePerGrid;
        userInfo.totalTokensToClaim +=
            currentLayerInfo.tokensToSell /
            (gridsPerLayer ** 2);
        // Save the liquidity and referral amounts so they're not claimed by owner
        uint liquidityAmount = (currentLayerInfo.pricePerGrid *
            currentLayerInfo.liquidityBasisPoints) / BASIS_POINTS;
        receiveForLiquidity += liquidityAmount;
        spreadToReferral(offsetLayer, msg.sender, referral);

        // Set the Reward amount for the previous layer
        if (offsetLayer > 1) {
            // get the amount to assign the previous layer
            LayerInfo storage prevLayer = layer[offsetLayer - 1];
            uint prevLayerRewardAmount = (currentLayerInfo.pricePerGrid *
                currentLayerInfo.previousLayerBasisPoints) / BASIS_POINTS;
            if (prevLayerRewardAmount > 0 && prevLayer.gridsOccupied > 0) {
                prevLayer.prevRewardAmount += prevLayerRewardAmount;
                receiveForPrevLayer += prevLayerRewardAmount;
            }
        }

        // Check that enough tokens where sent to buy a grid with native
        if (receiveToken == address(0)) {
            if (msg.value != currentLayerInfo.pricePerGrid)
                revert TPresale__InvalidDepositAmount();
        } else {
            if (msg.value > 0) revert TPresale__InvalidDepositAmount();
            _safeTokenTransferFrom(
                receiveToken,
                msg.sender,
                address(this),
                currentLayerInfo.pricePerGrid
            );
        }
        emit Deposit(msg.sender, offsetLayer);
        checkForNextLayer(false);
    }

    //-----------------------------------------------------------------------------------
    // INTERNAL/PRIVATE FUNCTIONS
    //-----------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------
    // EXTERNAL/PUBLIC VIEW PURE FUNCTIONS
    //-----------------------------------------------------------------------------------
    function currentLayerId() public view returns (uint8) {
        if (block.number < layer[0].startBlock) return 0;
        return offsetLayer;
    }

    function saleStatus() public view returns (Status) {
        if (status == Status.PENDING && block.number >= layer[0].startBlock) {
            return Status.IN_PROGRESS;
        }
        return status;
    }

    function usersOnLayer(
        uint8 layerId
    ) external view returns (address[] memory) {
        return layerUsers[layerId];
    }

    function rewardsToClaim(
        uint8 layerId,
        address user
    )
        public
        view
        returns (uint256 depositClaim, uint referralTokens, uint layerTokens)
    {
        UserLayerInfo storage userInfo = userLayer[layerId][user];
        LayerInfo storage layerStatus = layer[layerId];
        depositClaim = userInfo.totalTokensToClaim;
        referralTokens = userInfo.totalReferralRewards;
        if (layerStatus.gridsOccupied == 0) layerTokens = 0;
        else
            layerTokens =
                (layerStatus.prevRewardAmount * userInfo.gridsOccupied) /
                layerStatus.gridsOccupied;
    }

    //-----------------------------------------------------------------------------------
    // INTERNAL/PRIVATE VIEW PURE FUNCTIONS
    //-----------------------------------------------------------------------------------

    function checkForNextLayer(bool _before) private {
        uint8 currentLayer = currentLayerId();
        // dont really need to check for currentLayer == 0 since this function only gets called when currentLayer > 0
        LayerInfo storage currentLayerInfo = layer[currentLayer];
        //Advance a layer if all grids are occupied or if the endBlock is reached
        if (
            currentLayerInfo.gridsOccupied == gridsPerLayer ||
            block.number >= currentLayerInfo.endBlock
        ) {
            if (currentLayer < totalLayers) {
                emit LayerCompleted(currentLayer);
                offsetLayer++;
            } else {
                if (_before) revert TPresale__SaleEnded();
                status = Status.COMPLETED;
                emit SaleEnded(block.timestamp);
            }
        }
    }

    function spreadToReferral(
        uint8 layerId,
        address user,
        address referral
    ) private {
        LayerInfo storage currentLayerInfo = layer[layerId];
        UserLayerInfo storage userInfo = userLayer[layerId][user];
        // If referral is not set, set it
        if (
            userInfo.referral == address(0) &&
            referral != address(0) &&
            referral != user
        ) {
            userInfo.referral = referral;
        }
        if (userInfo.referral == address(0)) return;
        // If referral is set, spread the referral rewards
        UserLayerInfo storage referralInfo = userLayer[layerId][referral];
        uint referralAmount = (currentLayerInfo.pricePerGrid *
            currentLayerInfo.referralBasisPoints) / BASIS_POINTS;
        referralInfo.totalReferralRewards += referralAmount;
        receiveForReferral += referralAmount;
    }

    function _safeTokenTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) private {
        (bool succ, ) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, from, to, amount)
        );
        if (!succ) revert TPresale__CouldNotTransfer(token, amount);
    }

    function _safeTokenTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) private {
        (bool succ, ) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                amount
            )
        );
        if (!succ) revert TPresale__CouldNotTransfer(token, amount);
    }

    //-----------------------------------------------------------------------------------
    // @TODO FUNCTIONS
    //-----------------------------------------------------------------------------------

    function claimTokensAndRewards() external {}

    function setLayerStartBlock(uint8 layerId, uint256 startBlock) external {}

    function setLayerDuration(uint8 layerId, uint256 duration) external {}

    function setLayerPricePerGrid(
        uint8 layerId,
        uint256 pricePerGrid
    ) external {}

    function setLayerLiquidityBasisPoints(
        uint8 layerId,
        uint8 liquidityBasisPoints
    ) external {}

    function setLayerReferralBasisPoints(
        uint8 layerId,
        uint8 referralBasisPoints
    ) external {}

    function setLayerPreviousLayerBasisPoints(
        uint8 layerId,
        uint8 previousLayerBasisPoints
    ) external {}

    function nextLayerId() external view returns (uint8) {}

    function totalTokensToClaim() external view returns (uint256) {}

    function tokensToClaimPerLayer(
        uint8 layerId
    ) external view returns (uint256) {}

    function finalizeSale() external {}
}
