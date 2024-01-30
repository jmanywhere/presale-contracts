// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITieredPresale {
    /// @dev to change from PENDING to IN_PROGRESS, status has to check if startBlock is reached and currentLayerId == 0
    enum Status {
        PENDING, // sale is not started yet
        IN_PROGRESS, // sale is in progress
        COMPLETED, // sale is completed
        FINALIZED, // sale is already finalized and tokens claimed and added for liquidity
    }
    struct LayerInfo {
        uint256 tokensToSell;
        uint256 pricePerGrid;
        uint256 startBlock;
        uint256 endBlock;
        uint256 prevRewardAmount; // rewards assigned to this layer from next layer
        uint8 liquidityBasisPoints;
        uint8 referralBasisPoints;
        uint8 previousLayerBasisPoints;
        uint8 gridsOccupied; // number of grids occupied in this layer
        uint8 prevLayerId;
    }

    struct UserLayerInfo {
        uint256 totalDeposit;
        uint256 totalTokensToClaim;
        uint256 totalReferralRewards;
        address referral;
        uint8 gridsOccupied;
        bool claimed;
    }

    function deposit(address referral) external payable;

    function claimTokensAndRewards() external;

    // ----------------------------------
    // OWNER FUNCTIONS
    // ----------------------------------
    function setLayerStartBlock(uint8 layerId, uint256 startBlock) external;

    function setLayerDuration(uint8 layerId, uint256 duration) external;

    function setLayerPricePerGrid(uint8 layerId, uint256 pricePerGrid) external;

    function setLayerLiquidityBasisPoints(
        uint8 layerId,
        uint8 liquidityBasisPoints
    ) external;

    function setLayerReferralBasisPoints(
        uint8 layerId,
        uint8 referralBasisPoints
    ) external;

    function setLayerPreviousLayerBasisPoints(
        uint8 layerId,
        uint8 previousLayerBasisPoints
    ) external;

    function finalizeSale() external;

    //----------------------------------
    // VIEW FUNCTIONS
    //----------------------------------

    function totalLayers() external view returns (uint8);

    function currentLayerId() external view returns (uint8);

    function nextLayerId() external view returns (uint8);

    function totalTokensToClaim() external view returns (uint256);

    function tokensToClaimPerLayer(
        uint8 layerId
    ) external view returns (uint256);

    function saleToken() external view returns (address);

    function receiveToken() external view returns (address);

    function saleStatus() external view returns (Status);

    function rewardsToClaim(
        uint8 layerId,
        address user
    )
        external
        view
        returns (uint256 depositClaim, uint referralTokens, uint layerTokens);

    function usersOnLayer(
        uint8 layerId
    ) external view returns (address[] memory);

    function uniqueInvestorCount() external view returns (uint256);

    function canFinalize() external view returns (bool);

    /*---------------------------------------
     *  EVENTS
     *--------------------------------------*/

    event Deposit(address indexed user, uint8 layerId);

    event ClaimTokens(
        address indexed user,
        uint saleTokenAmount,
        uint referralAmount,
        uint layerRewardAmount
    );

    event OwnerClaimRaise(uint amount);

    event LayerCompleted(uint8 indexed layerId);

    event SaleEnded(uint timestamp);
}
