// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./interface/ITieredPresale.sol";
import "./interface/IUniswapV2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error TPresale__InvalidSetup();
error TPresale__InvalidCaller();
error TPresale__InProgress();
error TPresale__NotStarted();
error TPresale__CouldNotTransfer(address _token, uint amount);
error TPresale__SaleEnded();
error TPresale__SaleNotEnded();
error TPresale__CantClaim();
error TPresale__InvalidDepositAmount();
error TPresale__NotEnoughTokens();

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
    uint256 public totalTokensSold;
    uint256 public tokensForLiquidity;
    //-----------------------
    uint256 public platformFeeReceive;
    // percentage that goes to the platform in form of tokens TO SELL
    uint256 public platformFeeSell;
    //-----------------------

    address public saleToken;
    address public receiveToken;
    address public saleOwnerWallet;
    address public router;
    uint256 public uniqueInvestorCount;
    uint8 public immutable totalLayers;
    uint8 public immutable gridsPerLayer;
    uint8 private offsetLayer = 1;
    Status public status = Status.PENDING;

    //-----------------------------------------------------------------------------------
    // MODIFIERS
    //-----------------------------------------------------------------------------------
    modifier onlySaleOwner() {
        if (msg.sender != saleOwnerWallet) revert TPresale__InvalidCaller();
        _;
    }

    //-----------------------------------------------------------------------------------
    // CONSTRUCTOR
    //-----------------------------------------------------------------------------------
    /**
     * @notice CONSTRUCTOR
     * @param gridInfo Grid settings
     * [0] totalLayers
     * [1] gridSize
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
     * @param platformConfig Configurations for fees and token amount used for liquidity
     * [0] platformFeeReceive
     * [1] platformFeeSell
     * [2] tokensToAddForLiquidity
     */
    constructor(
        uint8[] memory gridInfo,
        uint256[] memory layerCreateInfo,
        address[] memory addressConfig,
        uint256[] memory platformConfig
    ) Ownable(msg.sender) {
        saleToken = addressConfig[0];
        receiveToken = addressConfig[1];
        saleOwnerWallet = addressConfig[2];
        router = addressConfig[3];
        platformFeeReceive = platformConfig[0];
        platformFeeSell = platformConfig[1];
        tokensForLiquidity = platformConfig[2];
        if (
            IUniswapV2Router02(router).WETH() == address(0) ||
            gridInfo[1] > 10 ||
            gridInfo[1] < 1
        ) revert TPresale__InvalidSetup();
        totalLayers = gridInfo[0];
        gridsPerLayer = gridInfo[1] ** 2;
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
        uint256 totalGridsPerLayer = uint256(gridsPerLayer);
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

    function deposit(address referral) external payable nonReentrant {
        if (
            currentLayerId() == 0 ||
            saleStatus() != Status.IN_PROGRESS ||
            canFinalize()
        ) {
            revert TPresale__SaleEnded();
        }
        // checks that the offset is shifted to the next layer
        checkForNextLayer(true);
        LayerInfo storage currentLayerInfo = layer[offsetLayer];
        // checks that layer has started
        if (currentLayerInfo.startBlock > block.number)
            revert TPresale__NotStarted();

        UserLayerInfo storage userInfo = userLayer[offsetLayer][msg.sender];

        currentLayerInfo.gridsOccupied++;
        layerUsers[offsetLayer][currentLayerInfo.gridsOccupied - 1] = msg
            .sender;
        userInfo.totalDeposit += currentLayerInfo.pricePerGrid;
        uint tokensSold = currentLayerInfo.tokensToSell / gridsPerLayer;
        totalTokensSold += tokensSold;
        userInfo.totalTokensToClaim += tokensSold;
        userInfo.gridsOccupied++;
        // Save the liquidity and referral amounts so they're not claimed by owner
        uint liquidityAmount = (currentLayerInfo.pricePerGrid *
            currentLayerInfo.liquidityBasisPoints) / BASIS_POINTS;
        receiveForLiquidity += liquidityAmount;
        spreadToReferral(offsetLayer, msg.sender, referral);

        // Set the Reward amount for the previous layer
        // only works for layer 2 and above
        if (offsetLayer > 1) {
            _spreadPrev(
                (currentLayerInfo.pricePerGrid *
                    currentLayerInfo.previousLayerBasisPoints) / BASIS_POINTS,
                offsetLayer - 1
            );
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

    function claimTokensAndRewards() external nonReentrant {
        if (status != Status.FINALIZED) revert TPresale__SaleNotEnded();
        uint256 totalPrizeTokens = 0;
        uint256 totalReferralTokens = 0;
        uint256 totalLayerRewards = 0;
        for (uint8 i = 1; i <= totalLayers; i++) {
            if (userLayer[i][msg.sender].claimed) continue;
            (
                uint256 depositClaim,
                uint256 referralTokens,
                uint256 layerTokens
            ) = rewardsToClaim(i, msg.sender);
            totalPrizeTokens += depositClaim;
            totalReferralTokens += referralTokens;
            totalLayerRewards += layerTokens;
            userLayer[i][msg.sender].claimed = true;
        }
        if (
            totalPrizeTokens == 0 &&
            totalReferralTokens == 0 &&
            totalLayerRewards == 0
        ) revert TPresale__CantClaim();
        emit ClaimTokens(
            msg.sender,
            totalPrizeTokens,
            totalReferralTokens,
            totalLayerRewards
        );
        if (totalPrizeTokens > 0) {
            _safeTokenTransfer(saleToken, msg.sender, totalPrizeTokens);
        }
        uint totalReceive = totalReferralTokens + totalLayerRewards;
        if (receiveToken == address(0)) {
            (bool succ, ) = msg.sender.call{value: totalReceive}("");
            if (!succ)
                revert TPresale__CouldNotTransfer(address(0), totalReceive);
        } else {
            _safeTokenTransfer(receiveToken, msg.sender, totalReceive);
        }
    }

    function finalizeSale() external onlySaleOwner nonReentrant {
        if (!canFinalize()) revert TPresale__SaleNotEnded();
        uint256 fees = (totalTokensSold * platformFeeSell) / BASIS_POINTS;

        if (
            totalTokensSold + tokensForLiquidity + fees >
            IERC20(saleToken).balanceOf(address(this))
        ) revert TPresale__NotEnoughTokens();

        status = Status.FINALIZED;
        // Send tokens to platform
        if (fees > 0) {
            _safeTokenTransfer(saleToken, owner(), fees);
        }
        // SAFE APPROVE
        safeApprove(saleToken, router, tokensForLiquidity);
        // Send receive fees to platform
        if (receiveToken == address(0)) {
            fees = address(this).balance;
            fees -= receiveForPrevLayer + receiveForReferral;
            uint saleOwnerAmount = fees - receiveForLiquidity;
            fees = (fees * platformFeeReceive) / BASIS_POINTS;
            if (saleOwnerAmount < fees) {
                receiveForLiquidity -= fees - saleOwnerAmount;
            }
            (bool succ, ) = owner().call{value: fees}("");
            if (!succ) revert TPresale__CouldNotTransfer(address(0), fees);
            // create liquidity
            IUniswapV2Router02(router).addLiquidityETH{
                value: receiveForLiquidity
            }(
                saleToken,
                tokensForLiquidity,
                tokensForLiquidity,
                receiveForLiquidity,
                saleOwnerWallet,
                block.timestamp
            );
            uint totalReceived = address(this).balance;
            totalReceived -= receiveForPrevLayer + receiveForReferral;
            if (totalReceived > 0) {
                (succ, ) = saleOwnerWallet.call{value: totalReceived}("");
                if (!succ)
                    revert TPresale__CouldNotTransfer(
                        address(0),
                        totalReceived
                    );
            }
        } else {
            safeApprove(receiveToken, router, receiveForLiquidity);
            fees = IERC20(receiveToken).balanceOf(address(this));
            fees -= receiveForPrevLayer + receiveForReferral;

            uint saleOwnerAmount = fees - receiveForLiquidity;
            fees = (fees * platformFeeReceive) / BASIS_POINTS;
            if (saleOwnerAmount < fees) {
                receiveForLiquidity -= fees - saleOwnerAmount;
            }
            if (fees > 0) _safeTokenTransfer(receiveToken, owner(), fees);
            // create liquidity
            IUniswapV2Router02(router).addLiquidity(
                saleToken,
                receiveToken,
                tokensForLiquidity,
                receiveForLiquidity,
                tokensForLiquidity,
                receiveForLiquidity,
                saleOwnerWallet,
                block.timestamp
            );
            uint totalReceived = IERC20(receiveToken).balanceOf(address(this));
            totalReceived -= receiveForPrevLayer + receiveForReferral;
            if (totalReceived > 0)
                _safeTokenTransfer(
                    receiveToken,
                    saleOwnerWallet,
                    totalReceived
                );
        }

        // transfer rest of tokens to owner
        emit SaleEnded(block.timestamp);
    }

    function setLayerStartBlock(
        uint8 layerId,
        uint256 startBlock
    ) external onlySaleOwner {
        LayerInfo storage layerInfo = layer[layerId];
        if (layerInfo.startBlock < block.number) revert TPresale__InProgress();
        layerInfo.startBlock = startBlock;
        emit LayerStartBlockChanged(layerId, startBlock);
    }

    function setLayerDuration(
        uint8 layerId,
        uint256 duration
    ) external onlySaleOwner {
        LayerInfo storage layerInfo = layer[layerId];
        if (layerInfo.startBlock < block.number) revert TPresale__InProgress();
        layerInfo.endBlock = layerInfo.startBlock + duration;
        emit LayerDurationChanged(layerId, duration);
    }

    function setLayerPricePerGrid(
        uint8 layerId,
        uint256 pricePerGrid
    ) external onlySaleOwner {
        LayerInfo storage layerInfo = layer[layerId];
        if (layerInfo.startBlock < block.number) revert TPresale__InProgress();
        layerInfo.pricePerGrid = pricePerGrid;
        emit LayerPricePerGridChanged(layerId, pricePerGrid);
    }

    function setLayerLiquidityBasisPoints(
        uint8 layerId,
        uint8 liquidityBasisPoints
    ) external onlySaleOwner {
        LayerInfo storage layerInfo = layer[layerId];
        if (layerInfo.startBlock < block.number) revert TPresale__InProgress();
        layerInfo.liquidityBasisPoints = liquidityBasisPoints;
        emit LayerLiquidityBasisPointsChanged(layerId, liquidityBasisPoints);
    }

    function setLayerReferralBasisPoints(
        uint8 layerId,
        uint8 referralBasisPoints
    ) external onlySaleOwner {
        LayerInfo storage layerInfo = layer[layerId];
        if (layerInfo.startBlock < block.number) revert TPresale__InProgress();
        layerInfo.referralBasisPoints = referralBasisPoints;
        emit LayerReferralBasisPointsChanged(layerId, referralBasisPoints);
    }

    function setLayerPreviousLayerBasisPoints(
        uint8 layerId,
        uint8 previousLayerBasisPoints
    ) external onlySaleOwner {
        LayerInfo storage layerInfo = layer[layerId];
        if (layerInfo.startBlock < block.number) revert TPresale__InProgress();
        layerInfo.previousLayerBasisPoints = previousLayerBasisPoints;
        emit LayerPreviousLayerBasisPointsChanged(
            layerId,
            previousLayerBasisPoints
        );
    }

    function setTotalTokensForLiquity(uint256 amount) external onlySaleOwner {
        tokensForLiquidity = amount;
        emit TotalTokensForLiquidityChanged(amount);
    }

    //-----------------------------------------------------------------------------------
    // INTERNAL/PRIVATE FUNCTIONS
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
                currentLayerInfo = layer[offsetLayer];
                if (currentLayerInfo.endBlock <= block.number)
                    checkForNextLayer(_before);
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
        address to,
        uint256 amount
    ) private {
        (bool succ, ) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
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

    function _spreadPrev(uint amount, uint8 receiveLayer) private {
        if (amount == 0) return;
        LayerInfo storage layerInfo = layer[receiveLayer];
        if (layerInfo.gridsOccupied > 0) {
            // If the layer has deposits, spread the amount to the previous layer
            if (receiveLayer > 1) {
                uint nextRoundAmount = (amount *
                    layerInfo.previousLayerBasisPoints) / BASIS_POINTS;
                amount -= nextRoundAmount;
                _spreadPrev(nextRoundAmount, receiveLayer - 1);
            }
            layerInfo.prevRewardAmount += amount;
            receiveForPrevLayer += amount;
        }
        // If the layer has no deposits, send the amount to the next layer
        else {
            if (receiveLayer > 1) _spreadPrev(amount, receiveLayer - 1);
            else receiveForPrevLayer += amount;
        }
    }

    function safeApprove(
        address _token,
        address _spender,
        uint amount
    ) private {
        (bool succ, ) = _token.call(
            abi.encodeWithSelector(IERC20.approve.selector, _spender, amount)
        );
        if (!succ) revert TPresale__CouldNotTransfer(_token, amount);
    }

    //-----------------------------------------------------------------------------------
    // EXTERNAL/PUBLIC VIEW PURE FUNCTIONS
    //-----------------------------------------------------------------------------------
    function currentLayerId() public view returns (uint8) {
        if (block.number < layer[1].startBlock) return 0;
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

    function canFinalize() public view returns (bool) {
        return
            status != Status.FINALIZED &&
            (status == Status.COMPLETED ||
                block.number > layer[totalLayers].endBlock);
    }

    function nextLayerId() external view returns (uint8) {
        if (offsetLayer == totalLayers) return offsetLayer;
        return offsetLayer + 1;
    }

    function totalTokensNeededToFinalize() external view returns (uint256) {
        return
            totalTokensSold +
            tokensForLiquidity +
            ((totalTokensSold * platformFeeSell) / BASIS_POINTS);
    }
}
