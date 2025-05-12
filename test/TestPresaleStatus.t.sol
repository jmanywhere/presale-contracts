// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {TieredPresale} from "../src/TieredPresale.sol";

contract TestPresaleStatus is Test {
    TieredPresale public presale;

    function setUp() public {
        presale = TieredPresale(0x545564Cf7f422796346A6F34843Aa087e533bFde);
    }

    function test_GetPresaleStatus() public view {
        _printBasicInfo();
        _printTokenInfo();
        _printLayerInfo();
    }

    function _printBasicInfo() private view {
        console.log("=== Basic Presale Information ===");
        console.log("Sale Token:", presale.saleToken());
        console.log("Receive Token:", presale.receiveToken());
        console.log("Sale Owner:", presale.saleOwnerWallet());
        console.log("Router:", presale.router());
        console.log("Total Layers:", presale.totalLayers());
        console.log("Grids Per Layer:", presale.gridsPerLayer());
        console.log("Current Layer ID:", presale.currentLayerId());
        console.log("Next Layer ID:", presale.nextLayerId());
        console.log("Sale Status:", uint8(presale.status()));
        console.log("Can Finalize:", presale.canFinalize());
    }

    function _printTokenInfo() private view {
        console.log("\n=== Token Information ===");
        console.log("Total Tokens To Sell:", presale.totalTokensToSell());
        console.log("Total Tokens Sold:", presale.totalTokensSold());
        console.log("Tokens For Liquidity:", presale.tokensForLiquidity());
        console.log(
            "Total Tokens Needed To Finalize:",
            presale.totalTokensNeededToFinalize()
        );

        console.log("\n=== Receive Token Information ===");
        console.log("Receive For Liquidity:", presale.receiveForLiquidity());
        console.log("Receive For Referral:", presale.receiveForReferral());
        console.log(
            "Receive For Previous Layer:",
            presale.receiveForPrevLayer()
        );
    }

    function _printLayerInfo() private view {
        console.log("\n=== Layer Information ===");
        for (uint8 i = 1; i <= presale.totalLayers(); i++) {
            _printLayerDetails(i);
        }
    }

    function _printLayerDetails(uint8 layerId) private view {
        (
            uint256 tokensToSell,
            uint256 pricePerGrid,
            uint256 startBlock,
            uint256 endBlock,
            uint256 prevRewardAmount,
            uint8 liquidityBasisPoints,
            uint8 referralBasisPoints,
            uint8 previousLayerBasisPoints,
            uint8 gridsOccupied,
            uint8 prevLayerId
        ) = presale.layer(layerId);

        console.log(string.concat("\nLayer ", vm.toString(layerId), ":"));
        console.log("  Tokens To Sell:", tokensToSell);
        console.log("  Price Per Grid:", pricePerGrid);
        console.log("  Start Block:", startBlock);
        console.log("  End Block:", endBlock);
        console.log("  Previous Reward Amount:", prevRewardAmount);
        console.log("  Liquidity Basis Points:", liquidityBasisPoints);
        console.log("  Referral Basis Points:", referralBasisPoints);
        console.log("  Previous Layer Basis Points:", previousLayerBasisPoints);
        console.log("  Grids Occupied:", gridsOccupied);
        console.log("  Previous Layer ID:", prevLayerId);

        _printLayerUsers(layerId);
    }

    function _printLayerUsers(uint8 layerId) private view {
        address[] memory users = presale.usersOnLayer(layerId);
        console.log("  Users in Layer:", users.length);

        for (uint j = 0; j < users.length; j++) {
            if (users[j] != address(0)) {
                _printUserInfo(layerId, j, users[j]);
            }
        }
    }

    function _printUserInfo(
        uint8 layerId,
        uint userIndex,
        address user
    ) private view {
        (
            uint256 depositClaim,
            uint256 referralTokens,
            uint256 layerTokens
        ) = presale.rewardsToClaim(layerId, user);

        console.log(string.concat("    User ", vm.toString(userIndex), ":"));
        console.log("      Address:", user);
        console.log("      Deposit Claim:", depositClaim);
        console.log("      Referral Tokens:", referralTokens);
        console.log("      Layer Tokens:", layerTokens);
    }
}
