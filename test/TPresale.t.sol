// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../src/TieredPresale.sol";
import {Token} from "../src/mocks/Token.sol";

contract TestPresale is Test {
    TieredPresale presaleWithToken;
    TieredPresale presaleWithNative;
    Token saleToken;
    Token receiveToken;

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    function setUp() public {
        saleToken = new Token("Selling", "SELL", 1_000_000 ether);
        receiveToken = new Token("Receive", "RCV", 1_000_000 ether);

        // setup users
        receiveToken.transfer(user1, 100 ether);
        receiveToken.transfer(user2, 100 ether);
        receiveToken.transfer(user3, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);

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
        vm.prank(user3);
        receiveToken.approve(address(presaleWithToken), 100 ether);

        // WITH NATIVE will be 4 layers
        layerCreateInfo = new uint256[](13);
        gridInfo = new uint8[](13);
        gridInfo[0] = 4; //totalLayers
        gridInfo[1] = 2; //totalGridsPerLayer 2x2
        // tokens to sell = grids of 16 slots
        gridInfo[2] = 99; //liquidityBasisPoints
        gridInfo[3] = 1; //referralBasisPoints
        gridInfo[4] = 50; //liquidityBasisPoints
        gridInfo[5] = 10; //referralBasisPoints
        gridInfo[6] = 20; //previousLayerBasisPoints
        gridInfo[7] = 60; //liquidityBasisPoints
        gridInfo[8] = 10; //referralBasisPoints
        gridInfo[9] = 10; //previousLayerBasisPoints
        gridInfo[10] = 60; //liquidityBasisPoints
        gridInfo[11] = 10; //referralBasisPoints
        gridInfo[12] = 10; //previousLayerBasisPoints
        addressConfig[1] = address(0);
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
        layerCreateInfo[10] = 4000; //blockDuration
        layerCreateInfo[11] = 0.4 ether; //pricePerGrid
        layerCreateInfo[12] = 2500 ether; //tokensPerGrid

        presaleWithNative = new TieredPresale(
            gridInfo,
            layerCreateInfo,
            addressConfig,
            platformConfig
        );
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
        vm.prank(user1);
        presaleWithToken.deposit(address(0));

        // DATA THAT WE WANT TO CHECK
        // 1 USER HAS ALLOCATED 2 GRID'S WORTH OF SELL TOKENS
        // userLayerInfo for 1, user 1 has the correct data
        (
            totalDeposited,
            totalTokensToClaim,
            refRew,
            referral,
            grids,
            claimed
        ) = presaleWithToken.userLayer(1, user1);

        assertEq(totalDeposited, 0.2 ether);
        assertEq(totalTokensToClaim, 2000 ether);
        assertEq(refRew, 0);
        assertEq(referral, address(0));
        assertEq(grids, 2);

        //2 number of totalgrids for user in layer 1 == 2, user has 2 grids
        (, , , , , , , , gridsOccupied, ) = presaleWithToken.layer(1);
        assertEq(gridsOccupied, 2);
        //3 layerUsers 1, 0 == user1
        assertEq(presaleWithToken.layerUsers(1, 1), user1);
        //4 totalTokenssold == 2 grid's worth
        assertEq(presaleWithToken.totalTokensSold(), 2000 ether);
        //5 receiveForLiquidity ==  0.2 ether amount
        assertEq(presaleWithToken.receiveForLiquidity(), 0.2 ether);

        // USER 2 DEPOSITS ON SAME LAYER, SHOULD GET 1 GRIDS ALLOCATED
        vm.prank(user2);
        presaleWithToken.deposit(address(0));

        // DATA THAT WE WANT TO CHECK
        // 1. USER2 HAS ALLOCATED 1 GRID'S WORTH OF SELL TOKENS
        // userLayerInfo for 1, user 2 has the correct data
        (
            totalDeposited,
            totalTokensToClaim,
            refRew,
            referral,
            grids,
            claimed
        ) = presaleWithToken.userLayer(1, user2);

        assertEq(totalDeposited, 0.1 ether);
        assertEq(totalTokensToClaim, 1000 ether);
        assertEq(refRew, 0);
        assertEq(referral, address(0));
        assertEq(grids, 1);
        assertEq(claimed, false);

        //2 - number of grids occupied by the total user in layer 1 == 3, user has 1 grids
        (, , , , , , , , gridsOccupied, ) = presaleWithToken.layer(1);

        assertEq(gridsOccupied, 3);

        //3 - the user position in layer1 should be layerUsers 1, 1 == user2
        // offset of 1 caused by initial deposit reversion
        assertEq(presaleWithToken.layerUsers(1, 2), user2);
        //4 - totalTokenssold == 3 grid's worth
        assertEq(presaleWithToken.totalTokensSold(), 3000 ether);
        //5 - receiveForLiquidity ==  0.3 ether amount
        assertEq(presaleWithToken.receiveForLiquidity(), 0.3 ether);

        // USER 3 DEPOSITS ON SAME LAYER, SHOULD GET 1 GRIDS ALLOCATED
        vm.prank(user3);
        presaleWithToken.deposit(address(0));

        // DATA THAT WE WANT TO CHECK
        // 1. USER2 HAS ALLOCATED 2 GRID'S WORTH OF SELL TOKENS
        // userLayerInfo for 1, user 2 has the correct data
        (
            totalDeposited,
            totalTokensToClaim,
            refRew,
            referral,
            grids,
            claimed
        ) = presaleWithToken.userLayer(1, user3);

        assertEq(totalDeposited, 0.1 ether);
        assertEq(totalTokensToClaim, 1000 ether);
        assertEq(refRew, 0);
        assertEq(referral, address(0));
        assertEq(grids, 1);
        assertEq(claimed, false);

        //2 - number of grids occupied by the total user in layer 1 == 4, user has 2 grids
        (, , , , , , , , gridsOccupied, ) = presaleWithToken.layer(1);

        assertEq(gridsOccupied, 4);
        //3 - the user position in layer1 should be layerUsers 1, 1 == user2. And layerUsers (1,2) should be user3
        assertEq(presaleWithToken.layerUsers(1, 3), user3);
        //4 - totalTokenssold == 4 grid's worth
        assertEq(presaleWithToken.totalTokensSold(), 4000 ether);
        //5 - receiveForLiquidity ==  0.4 ether amount
        assertEq(presaleWithToken.receiveForLiquidity(), 0.4 ether);
    }

    function test_layer_limit() public {
        // Test that when a layer is completely filled, the next deposit, opens up the next layer

        // IF ALL LAYERS FILLED SHOULD FAIL NEXT DEPOSIT.
        vm.expectRevert(); // reason": Sale has not started
        vm.prank(user1);
        presaleWithToken.deposit(address(0));

        // we are in layer 1
        vm.roll(12);

        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));
        vm.prank(user1);
        presaleWithToken.deposit(address(0));

        vm.prank(user2);
        presaleWithToken.deposit(address(0));

        // DATA THAT WE WANT TO CHECK
        // 1 - USER HAS ALLOCATED 1 GRID'S WORTH OF SELL TOKENS
        // userLayerInfo for layer 2, user 1, user2, user 3 has the correct data
        (
            uint totalDeposited,
            uint totalTokensToClaim,
            uint refRew,
            address referral,
            uint8 grids,
            bool claimed
        ) = presaleWithToken.userLayer(1, user1);
        assertEq(totalDeposited, 1.5 ether);
        assertEq(totalTokensToClaim, 15000 ether);
        assertEq(refRew, 0);
        assertEq(referral, address(0));
        assertEq(grids, 15);
        assertEq(claimed, false);

        (
            totalDeposited,
            totalTokensToClaim,
            refRew,
            referral,
            grids,
            claimed
        ) = presaleWithToken.userLayer(1, user2);
        assertEq(totalDeposited, 0.1 ether);
        assertEq(totalTokensToClaim, 1000 ether);
        assertEq(refRew, 0);
        assertEq(referral, address(0));
        assertEq(grids, 1);
        assertEq(claimed, false);

        // 2 - number of grids occupied by the total user in layer 1 == 16, user has 15 grids
        (, , , , , , , , uint8 gridsOccupied, ) = presaleWithToken.layer(1);
        assertEq(gridsOccupied, 16);

        //Total tokens sold == 16000 ether
        assertEq(presaleWithToken.totalTokensSold(), 16000 ether);
        //receiveForLiquidity ==  1.6 ether amount
        assertEq(presaleWithToken.receiveForLiquidity(), 1.6 ether);

        // 17th deposit goes to next layer
        vm.expectRevert(TPresale__NotStarted.selector);
        vm.prank(user3);
        presaleWithToken.deposit(address(0));

        vm.roll(1010);
        vm.prank(user3);
        presaleWithToken.deposit(address(0));
        (
            totalDeposited,
            totalTokensToClaim,
            refRew,
            referral,
            grids,
            claimed
        ) = presaleWithToken.userLayer(2, user3);
        assertEq(grids, 1);
        assertEq(totalDeposited, 0.2 ether);

        // Nobody deposits on layer 3 until end
        vm.roll(6050);

        vm.expectRevert(TPresale__SaleEnded.selector);
        vm.prank(user3);
        presaleWithToken.deposit(address(0));
    }

    function test_deposit_native() public {
        vm.roll(10);

        vm.prank(user1);
        presaleWithNative.deposit{value: 0.1 ether}(user2);

        (, , , address ref, , ) = presaleWithNative.userLayer(1, user1);
        (, , uint refRew, , , ) = presaleWithNative.userLayer(1, user2);

        assertEq(ref, user2);
        assertEq(refRew, 0.001 ether);

        vm.roll(3010);
        assertEq(presaleWithNative.currentLayerId(), 1);
        vm.prank(user1);
        presaleWithNative.deposit{value: 0.3 ether}(address(0));
        (uint userDeposit, , , , , ) = presaleWithNative.userLayer(3, user1);
        assertEq(userDeposit, 0.3 ether);
        (, , , , uint prevRew, , , , , ) = presaleWithNative.layer(1);
        assertEq(prevRew, 0.3 ether / 10);

        vm.roll(6011);
        vm.prank(user1);
        presaleWithNative.deposit{value: 0.4 ether}(address(0));
        (, , , , prevRew, , , , , ) = presaleWithNative.layer(1);
        assertEq(prevRew, (0.3 ether / 10) + (0.4 ether / 100));
        (, , , , prevRew, , , , , ) = presaleWithNative.layer(2);
        assertEq(prevRew, 0);
        (, , , , prevRew, , , , , ) = presaleWithNative.layer(3);
        assertEq(prevRew, 0.036 ether);
    }
}
