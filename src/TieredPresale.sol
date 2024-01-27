// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./interface/ITieredPresale.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "forge-std/console.sol";

error TPresale__InvalidSetup();
error TPresale__CouldNotTransfer(address _token, uint amount);

contract TieredPresale is ITieredPresale, Ownable, ReentrancyGuard {
    //-----------------------------------------------------------------------------------
    // GLOBAL STATE
    //-----------------------------------------------------------------------------------
    mapping(uint8 layerId => LayerInfo) public layer;
    uint256 public totalTokensToSell;
    address public saleToken;
    address public receiveToken;
    address public saleoOwnerWallet;
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
     */
    constructor(
        uint8[] memory gridInfo,
        uint256[] memory layerCreateInfo,
        address[] memory addressConfig
    ) Ownable(msg.sender) {
        saleToken = addressConfig[0];
        receiveToken = addressConfig[1];
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
        setupLayer.usersOnGrid = new address[](totalGridsPerLayer);
        setupLayer.liquidityBasisPoints = gridInfo[2];
        setupLayer.referralBasisPoints = gridInfo[3];
        setupLayer.previousLayerBasisPoints = 0;
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
            setupLayer.usersOnGrid = new address[](totalGridsPerLayer);
            setupLayer.liquidityBasisPoints = gridInfo[offset];
            setupLayer.referralBasisPoints = gridInfo[offset + 1];
            setupLayer.previousLayerBasisPoints = gridInfo[offset + 2];
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

        //If receiveToken == address(0) receive NATIVE
        //    require msg.value to be amount else msg.value = 0;
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

    //-----------------------------------------------------------------------------------
    // INTERNAL/PRIVATE VIEW PURE FUNCTIONS
    //-----------------------------------------------------------------------------------

    function checkForNextLayer() private {
        uint8 currentLayer = currentLayerId();
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

    function refund(uint8 gridId) external {}

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

    function cancelRaise() external {}

    function refund(uint8 gridId, uint8 layerId) external {}

    function nextLayerId() external view returns (uint8) {}

    function totalTokensToClaim() external view returns (uint256) {}

    function tokensToClaimPerLayer(
        uint8 layerId
    ) external view returns (uint256) {}

    function rewardsToClaim(
        uint8 layerId,
        address user
    )
        external
        view
        returns (uint256 allTokens, uint referral, uint referralTokens)
    {}
}
