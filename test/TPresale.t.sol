// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../src/TieredPresale.sol";
import "../src/interface/IUniswapV2.sol";
import {Token} from "../src/mocks/Token.sol";

contract TestPresale is Test {
    TieredPresale presaleWithToken;
    TieredPresale presaleWithNative;
    Token saleToken;
    Token receiveToken;
    address router = 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");
    address protocol = makeAddr("protocol");

    receive() external payable {}

    fallback() external payable {}

    function setUp() public {
        saleToken = new Token("Selling", "SELL", 1_000_000 ether);
        receiveToken = new Token("Receive", "RCV", 1_000_000 ether);
        console.log("Sale Token: %s", address(saleToken));
        console.log("Receive Token: %s", address(receiveToken));
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
        vm.prank(protocol);
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
        vm.prank(protocol);
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
        vm.roll(1);
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

        // 17th deposit goes to next layer // next layer starts immediately
        // vm.expectRevert(TPresale__NotStarted.selector);
        // vm.prank(user3);
        // presaleWithToken.deposit(address(0));

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

    function test_finalize() public {
        vm.roll(10);

        vm.startPrank(user1);
        for (uint8 i = 0; i < 16; i++) {
            presaleWithToken.deposit(address(0));
        }

        assertEq(presaleWithToken.canFinalize(), false);

        vm.roll(6050);

        assertEq(presaleWithToken.canFinalize(), true);

        // Only Sale Owner can finalize

        // Failures:
        // Calling finalize not being sale owner
        vm.expectRevert(TPresale__InvalidCaller.selector);
        presaleWithToken.finalizeSale();
        vm.stopPrank();

        // Calling finalize without adding tokensToSell to Contract
        console.log(
            "Sale Token Balance: %s",
            saleToken.balanceOf(address(presaleWithToken))
        );
        console.log(
            "TokensSold: %s, tokensForLiquidity: %s",
            presaleWithToken.totalTokensSold(),
            presaleWithToken.tokensForLiquidity()
        );
        vm.expectRevert(TPresale__NotEnoughTokens.selector);
        presaleWithToken.finalizeSale();

        saleToken.transfer(address(presaleWithToken), 116320.0 ether);

        uint protocolSaleBalance = saleToken.balanceOf(protocol);
        uint protocolReceiveBalance = receiveToken.balanceOf(protocol);
        uint ownerReceiveBalance = receiveToken.balanceOf(address(this));

        presaleWithToken.finalizeSale();
        assertEq(
            saleToken.balanceOf(protocol),
            protocolSaleBalance + 320.0 ether
        );

        // send enough tokens to contract.

        // 1. Liquidity was added successfully
        address pair = IUniswapV2Factory(IUniswapV2Router02(router).factory())
            .getPair(address(saleToken), address(receiveToken));
        assertGt(IUniswapV2Pair(pair).totalSupply(), 0);
        // 2. Receive Tokens were added to the sale owner wallet
        assertEq(
            receiveToken.balanceOf(protocol),
            protocolReceiveBalance + 0.016 ether
        );
        assertEq(receiveToken.balanceOf(address(this)), ownerReceiveBalance);
        // 3. Sale is finalized
        assertEq(
            uint(presaleWithToken.status()),
            uint(ITieredPresale.Status.FINALIZED)
        );
        // 4. There is enough receive tokens for referrals and prevLayer rewards
        assertGe(
            receiveToken.balanceOf(address(presaleWithToken)),
            presaleWithToken.receiveForReferral() +
                presaleWithToken.receiveForPrevLayer()
        );
        // user claims entire sale token
    }

    function test_finalizeNative() public {
        vm.roll(10);
        vm.startPrank(user1);
        for (uint8 i = 0; i < 4; i++) {
            presaleWithNative.deposit{value: 0.1 ether}(address(0));
        }
        assertEq(presaleWithNative.canFinalize(), false);

        vm.roll(10050);
        assertEq(presaleWithNative.canFinalize(), true);

        vm.expectRevert(TPresale__InvalidCaller.selector);
        presaleWithNative.finalizeSale();
        vm.stopPrank();

        // Calling finalize without adding tokensToSell to Contract
        console.log(
            "Sale Token Balance: %s",
            saleToken.balanceOf(address(presaleWithNative))
        );
        console.log(
            "TokensSold: %s, tokensForLiquidity: %s",
            presaleWithNative.totalTokensSold(),
            presaleWithNative.tokensForLiquidity()
        );
        vm.expectRevert(TPresale__NotEnoughTokens.selector);
        presaleWithNative.finalizeSale();

        saleToken.transfer(address(presaleWithNative), 104080 ether);

        uint protocolSaleBalance = saleToken.balanceOf(protocol);
        uint protocolReceiveBalance = protocol.balance;
        uint ownerReceiveBalance = address(this).balance;

        presaleWithNative.finalizeSale();
        assertEq(
            saleToken.balanceOf(protocol),
            protocolSaleBalance + 80.0 ether
        );

        // send enough tokens to contract.
        // 1. Liquidity was added successfully
        address pair = IUniswapV2Factory(IUniswapV2Router02(router).factory())
            .getPair(
                address(saleToken),
                address(IUniswapV2Router02(router).WETH())
            );
        assertGt(IUniswapV2Pair(pair).totalSupply(), 0);

        // 2. Receive Tokens were added to the sale owner wallet
        assertEq(protocol.balance, protocolReceiveBalance + 0.004 ether);
        assertEq(address(this).balance, ownerReceiveBalance);
        // 3. Sale is finalized
        assertEq(
            uint(presaleWithNative.status()),
            uint(ITieredPresale.Status.FINALIZED)
        );
        // 4. There is enough receive tokens for referrals and prevLayer rewards
        assertGe(
            address(presaleWithNative).balance,
            presaleWithNative.receiveForReferral() +
                presaleWithNative.receiveForPrevLayer()
        );
    }

    function test_user_claims() public {
        vm.roll(10);
        vm.startPrank(user1);
        for (uint8 i = 0; i < 4; i++) {
            presaleWithNative.deposit{value: 0.1 ether}(address(0));
        }
        vm.stopPrank();
        vm.roll(1050);
        vm.startPrank(user2);
        for (uint8 i = 0; i < 4; i++) {
            presaleWithNative.deposit{value: 0.2 ether}(user1);
        }

        vm.stopPrank();

        vm.roll(3050);
        vm.prank(user3);
        presaleWithNative.deposit{value: 0.3 ether}(user4);
        vm.roll(10050);

        saleToken.transfer(
            address(presaleWithNative),
            presaleWithNative.totalTokensNeededToFinalize()
        );
        console.log("Receive Balance: %s", address(presaleWithNative).balance);
        presaleWithNative.finalizeSale();
        console.log(
            "Receive Balance After Finalize: %s",
            address(presaleWithNative).balance
        );
        console.log(
            "receive for referrals",
            presaleWithNative.receiveForReferral()
        );
        // We need to know how much trickled down to layer 1 as rewards
        uint prevL2Rewards = uint(0.3 ether) / 10;
        uint prevL1Rewards = prevL2Rewards / 5;
        prevL2Rewards -= prevL1Rewards;
        prevL1Rewards += uint(0.2 ether * 4) / 5;

        (, , , , uint prevRew, , , , , ) = presaleWithNative.layer(1);
        console.log("L1 prevRewards Check");
        assertEq(prevRew, prevL1Rewards);
        (, , , , prevRew, , , , , ) = presaleWithNative.layer(2);
        console.log("L2 prevRewards Check");
        assertEq(prevRew, prevL2Rewards);

        // User 1 claims referral and prevlayer rewards and tokens bought
        uint saleTokenBalance = saleToken.balanceOf(user1);
        uint receiveTokenBalance = user1.balance;

        vm.prank(user1);
        presaleWithNative.claimTokensAndRewards();

        console.log("U1 Sale Balance Check");
        assertEq(saleToken.balanceOf(user1), saleTokenBalance + 4000 ether);
        console.log("U1 Rewards Balance Check");
        assertEq(
            user1.balance,
            receiveTokenBalance +
                // calculate referral rewards
                ((0.2 ether * 4) / 10) +
                // calculate prevLayer rewards
                prevL1Rewards
        );
        // user 1 cant claim twice
        vm.expectRevert(TPresale__CantClaim.selector);
        vm.prank(user1);
        presaleWithNative.claimTokensAndRewards();
        // user 2 should be able to claim tokens bought + prevLayer rewards
        saleTokenBalance = saleToken.balanceOf(user2);
        receiveTokenBalance = user2.balance;

        vm.prank(user2);
        presaleWithNative.claimTokensAndRewards();

        console.log("U2 Sale Balance Check");
        assertEq(saleToken.balanceOf(user2), saleTokenBalance + 6000 ether);
        console.log("U2 Rewards Balance Check");
        assertEq(
            user2.balance,
            receiveTokenBalance +
                // calculate prevLayer rewards
                prevL2Rewards
        );
        // user 3 should be able to claim tokens bought
        saleTokenBalance = saleToken.balanceOf(user3);
        receiveTokenBalance = user3.balance;
        vm.prank(user3);
        presaleWithNative.claimTokensAndRewards();
        console.log("U3 Sale Balance Check");

        assertEq(saleToken.balanceOf(user3), saleTokenBalance + 2000 ether);
        console.log("U3 Rewards Balance Check");
        assertEq(user3.balance, receiveTokenBalance);
        // user 4 should be able to claim referral rewards only
        receiveTokenBalance = user4.balance;
        vm.prank(user4);
        presaleWithNative.claimTokensAndRewards();
        console.log("U4 Sale Balance Check");

        assertEq(saleToken.balanceOf(user4), 0);
        console.log("U4 Rewards Balance Check");
        assertEq(
            user4.balance,
            receiveTokenBalance +
                // calculate referral rewards
                (0.3 ether / 10)
        );
    }
}
