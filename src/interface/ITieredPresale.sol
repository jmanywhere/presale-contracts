// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITieredPresale {
    struct LayerInfo {
        address[] usersOnGrid;
        uint256 tokensSold;
        uint256 pricePerGrid;
        uint8 liquidityBasisPoints;
        uint8 referralBasisPoints;
        uint8 previousLayerBasisPoints;
        uint8 grids;
        uint8 prevLayerId;
    }

    struct UserLayerInfo {
        uint8[] layerPositions;
        uint256 totalDeposit;
        uint256 totalTokensToClaim;
    }

    function deposit(uint8 gridId, uint amount) external;

    function refund(uint8 gridId) external;

    function claimTokens() external;

    function currentLayerId() external view returns (uint8);

    function nextLayerId() external view returns (uint8);

    function totalTokensToClaim() external view returns (uint256);

    function tokensToClaimPerLayer(
        uint8 layerId
    ) external view returns (uint256);

    function saleToken() external view returns (address);

    function receiveToken() external view returns (address);

    /*---------------------------------------
     *  EVENTS
     *--------------------------------------*/

    event Deposit(address indexed user, uint amount);

    event ClaimTokens(address indexed user, uint amount);

    event Refund(address indexed user, uint amount);

    event OwnerClaimRaise(uint amount);

    event LayerCompleted(uint8 indexed layerId);
}
