// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITieredPresale {
    /// @dev to change from PENDING to IN_PROGRESS, status has to check if startBlock is reached and currentLayerId == 0
    enum Status {
        PENDING, // sale is not started yet
        IN_PROGRESS, // sale is in progress
        COMPLETED, // sale is completed
        CANCELLED // sale is cancelled
    }
    struct LayerInfo {
        address[] usersOnGrid; // users participating
        uint256 tokensSold;
        uint256 pricePerGrid;
        uint256 startBlock;
        uint256 endBlock;
        uint8 liquidityBasisPoints;
        uint8 referralBasisPoints;
        uint8 previousLayerBasisPoints;
        uint8 gridsOccupied; // number of grids occupied in this layer
        uint8 prevLayerId;
    }

    struct UserLayerInfo {
        uint8[] layerPositions;
        uint256 totalDeposit;
        uint256 totalTokensToClaim;
        address referral;
    }

    function deposit(uint8 gridId, uint amount, address referral) external;

    function refund(uint8 gridId) external;

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

    //----------------------------------
    // VIEW FUNCTIONS
    //----------------------------------

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
        returns (uint256 allTokens, uint referral, uint referralTokens);

    /*---------------------------------------
     *  EVENTS
     *--------------------------------------*/

    event Deposit(address indexed user, uint amount);

    event ClaimTokens(address indexed user, uint amount);

    event Refund(address indexed user, uint amount);

    event OwnerClaimRaise(uint amount);

    event LayerCompleted(uint8 indexed layerId);
}
