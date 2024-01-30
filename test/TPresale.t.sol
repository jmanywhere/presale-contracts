// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {TieredPresale} from "../src/TieredPresale.sol";
import {Token} from "../src/mocks/Token.sol";

contract TestPresale is Test {
    TieredPresale presaleWithToken;
    TieredPresale presaleWithNative;
    Token saleToken;
    Token receiveToken;

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        saleToken = new Token("Selling", "SELL", 1_000_000 ether);
        receiveToken = new Token("Receive", "RCV", 1_000_000 ether);

        // setup users
        receiveToken.transfer(user1, 100 ether);
        receiveToken.transfer(user2, 100 ether);

        address[] memory addressConfig = new address[](4);
        // Base layerConfig Addreses EAch exra layer is +3 more items in the number arrays
        uint256[] memory layerCreateInfo = new uint256[](10);
        uint8[] memory gridInfo = new uint8[](10);
        gridInfo[0] = 3; //totalLayers
        gridInfo[1] = 4; //totalGridsPerLayer 4x4
        // tokens to sell = grids of 16 slots
        gridInfo[2] = 100; //liquidityBasisPoints
        gridInfo[3] = 0; //referralBasisPoints
        gridInfo[4] = 50; //liquidityBasisPoints
        gridInfo[5] = 10; //referralBasisPoints
        gridInfo[6] = 20; //previousLayerBasisPoints
        gridInfo[7] = 60; //liquidityBasisPoints
        gridInfo[8] = 10; //referralBasisPoints
        gridInfo[9] = 10; //previousLayerBasisPoints

        layerCreateInfo[0] = 10; //startBlock
        layerCreateInfo[1] = 1000; //blockDuration
        layerCreateInfo[2] = 0.1 ether; //pricePerGrid
        layerCreateInfo[3] = 1000 ether; //tokensPerGrid
        layerCreateInfo[4] = 2000; //blockDuration
        layerCreateInfo[5] = 0.2 ether; //pricePerGrid
        layerCreateInfo[6] = 1500 ether; //tokensPerGrid
        layerCreateInfo[7] = 3000; //blockDuration
        layerCreateInfo[8] = 0.3 ether; //pricePerGrid
        layerCreateInfo[9] = 2000 ether; //tokensPerGrid

        addressConfig[0] = address(saleToken);
        addressConfig[1] = address(receiveToken);
        addressConfig[2] = address(this);
        addressConfig[3] = 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;

        uint[] memory platformConfig = new uint[](3);
        platformConfig[0] = 1; //receiveFee;
        platformConfig[1] = 2; //tokensFee;
        platformConfig[2] = 100_000 ether; //all tokens to add to liquidity;

        // WITH TOKEN will be 3 layers
        presaleWithToken = new TieredPresale(
            gridInfo,
            layerCreateInfo,
            addressConfig,
            platformConfig
        );

        // approve USERS
        vm.prank(user1);
        receiveToken.approve(address(presaleWithToken), 100 ether);
        vm.prank(user2);
        receiveToken.approve(address(presaleWithToken), 100 ether);
        // WITH NATIVE will be 4 layers
        // uint256[] memory layerCreateInfo = new uint256[](13);
        // uint8[] memory gridInfo = new uint8[](13);
        // presaleWithNative = new TieredPresale(
        //     gridInfo,
        //     layerCreateInfo,
        //     addressConfig
        // );
    }

    function checkLayerValues(
        uint[] memory compareValues,
        uint8 layerId
    ) private {
        (
            uint tokensToSell,
            uint pricePerGrid,
            uint startBlock,
            uint endBlock,
            uint prevRew,
            uint8 liquidityBasisPoints,
            uint8 referralBasisPoints,
            uint8 previousLayerBasisPoints,
            uint8 gridsOccupied,
            uint8 prevLayerId
        ) = presaleWithToken.layer(layerId);
        assertEq(tokensToSell, compareValues[0]);
        assertEq(pricePerGrid, compareValues[1]);
        assertEq(startBlock, compareValues[2]);
        assertEq(endBlock, compareValues[3]);
        assertEq(prevRew, 0);
        assertEq(liquidityBasisPoints, uint8(compareValues[4]));
        assertEq(referralBasisPoints, uint8(compareValues[5]));
        assertEq(previousLayerBasisPoints, uint8(compareValues[6]));
        assertEq(gridsOccupied, uint8(compareValues[7]));
        assertEq(prevLayerId, uint8(compareValues[8]));
    }

    function test_presale_with_token_setup() public {
        assertEq(presaleWithToken.currentLayerId(), 0);
        assertEq(presaleWithToken.totalLayers(), 3);
        assertEq(presaleWithToken.totalTokensToSell(), 72000 ether);

        uint[] memory compareValues = new uint[](9);
        compareValues[0] = 16000 ether; //tokensToSell
        compareValues[1] = 0.1 ether; //pricePerGrid
        compareValues[2] = 10; //startBlock
        compareValues[3] = 1010; //endBlock
        compareValues[4] = 100; //liquidityBasisPoints
        compareValues[5] = 0; //referralBasisPoints
        compareValues[6] = 0; //previousLayerBasisPoints
        compareValues[7] = 0; //gridsOccupied
        compareValues[8] = 0; //prevLayerId
        checkLayerValues(compareValues, 1);

        compareValues[0] = 24000 ether; //tokensToSell
        compareValues[1] = 0.2 ether; //pricePerGrid
        compareValues[2] = 1010; //startBlock
        compareValues[3] = 3010; //endBlock
        compareValues[4] = 50; //liquidityBasisPoints
        compareValues[5] = 10; //referralBasisPoints
        compareValues[6] = 20; //previousLayerBasisPoints
        compareValues[7] = 0; //gridsOccupied
        compareValues[8] = 1; //prevLayerId
        checkLayerValues(compareValues, 2);

        compareValues[0] = 32000 ether; //tokensToSell
        compareValues[1] = 0.3 ether; //pricePerGrid
        compareValues[2] = 3010; //startBlock
        compareValues[3] = 6010; //endBlock
        compareValues[4] = 60; //liquidityBasisPoints
        compareValues[5] = 10; //referralBasisPoints
        compareValues[6] = 10; //previousLayerBasisPoints
        compareValues[7] = 0; //gridsOccupied
        compareValues[8] = 2; //prevLayerId
        checkLayerValues(compareValues, 3);

        compareValues[0] = 0;
        compareValues[1] = 0;
        compareValues[2] = 0;
        compareValues[3] = 0;
        compareValues[4] = 0;
        compareValues[5] = 0;
        compareValues[6] = 0;
        compareValues[7] = 0;
        compareValues[8] = 0;
        checkLayerValues(compareValues, 4);
        compareValues[0] = 0;
        compareValues[1] = 0;
        compareValues[2] = 0;
        compareValues[3] = 0;
        compareValues[4] = 0;
        compareValues[5] = 0;
        compareValues[6] = 0;
        compareValues[7] = 0;
        compareValues[8] = 0;
        checkLayerValues(compareValues, 0);
    }

    function test_deposit_multiple_users() public {
        // Single user deposits and gets 1 grid allocated
        vm.expectRevert(); // reason": Sale has not started
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        // we are in layer 1
        vm.roll(11);

        vm.prank(user1);
        presaleWithToken.deposit(address(0));

        // DATA THAT WE WANT TO CHECK
        // 1 USER HAS ALLOCATED 1 GRID'S WORTH OF SELL TOKENS
        // userLayerInfo for 1, user 1 has the correct data
        (
            uint totalDeposited,
            uint totalTokensToClaim,
            uint refRew,
            address referral,
            uint8 grids,
            bool claimed
        ) = presaleWithToken.userLayer(1, user1);
        assertEq(totalDeposited, 0.1 ether);
        assertEq(totalTokensToClaim, 1000 ether);
        assertEq(refRew, 0);
        assertEq(referral, address(0));
        assertEq(grids, 1);
        assertEq(claimed, false);
        // 2 users in grid for layer 1 == 1
        (, , , , , , , , uint8 gridsOccupied, ) = presaleWithToken.layer(1);
        assertEq(gridsOccupied, 1);
        // 3 layerUsers 1, 0 == user1
        assertEq(presaleWithToken.layerUsers(1, 0), user1);
        // 4 totalTokenssold == 1 grid's worth
        assertEq(presaleWithToken.totalTokensSold(), 1000 ether);
        // 5 receiveForLiquidity ==  0.1 ether amount
        assertEq(presaleWithToken.receiveForLiquidity(), 0.1 ether);

        // User deposits on same layer, should get 2 grids allocated
        // User 2 deposits on same layer, should get 1 grids allocated
    }

    function test_layer_limit() public {
        // Test that when a layer is completely filled, the next deposit, opens up the next layer
        // If all layers are filled, should fail next deposit.
    }

    function test_refund() public {
        // Test that a user can refund their deposit
        // Test that a user cant refund when layer is full
        // test that a user cant refund when timer is 15 min prior to over
        //  15 min or 10% of block durtaion since start to finish
    }
}
