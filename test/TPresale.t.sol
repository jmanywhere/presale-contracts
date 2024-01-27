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

    function setUp() public {
        saleToken = new Token("Selling", "SELL", 1_000_000 ether);
        receiveToken = new Token("Receive", "RCV", 1_000_000 ether);

        address[] memory addressConfig = new address[](3);
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

        // WITH TOKEN will be 3 layers
        presaleWithToken = new TieredPresale(
            gridInfo,
            layerCreateInfo,
            addressConfig
        );
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
        uint[] memory compareVales,
        uint8 layerId
    ) private {
        (
            uint tokensToSell,
            uint pricePerGrid,
            uint startBlock,
            uint endBlock,
            uint8 liquidityBasisPoints,
            uint8 referralBasisPoints,
            uint8 previousLayerBasisPoints,
            uint8 gridsOccupied,
            uint8 prevLayerId
        ) = presaleWithToken.layer(layerId);

        assertEq(tokensToSell, compareVales[0]);
        assertEq(pricePerGrid, compareVales[1]);
        assertEq(startBlock, compareVales[2]);
        assertEq(endBlock, compareVales[3]);
        assertEq(liquidityBasisPoints, uint8(compareVales[4]));
        assertEq(referralBasisPoints, uint8(compareVales[5]));
        assertEq(previousLayerBasisPoints, uint8(compareVales[6]));
        assertEq(gridsOccupied, uint8(compareVales[7]));
        assertEq(prevLayerId, uint8(compareVales[8]));
    }

    function test_presale_with_token_setup() public {
        assertEq(presaleWithToken.currentLayerId(), 0);
        assertEq(presaleWithToken.totalLayers(), 3);
        assertEq(presaleWithToken.totalTokensToSell(), 72000 ether);

        uint[] memory compareVales = new uint[](9);
        compareVales[0] = 16000 ether; //tokensToSell
        compareVales[1] = 0.1 ether; //pricePerGrid
        compareVales[2] = 10; //startBlock
        compareVales[3] = 1010; //endBlock
        compareVales[4] = 100; //liquidityBasisPoints
        compareVales[5] = 0; //referralBasisPoints
        compareVales[6] = 0; //previousLayerBasisPoints
        compareVales[7] = 0; //gridsOccupied
        compareVales[8] = 0; //prevLayerId
        checkLayerValues(compareVales, 1);

        compareVales[0] = 24000 ether; //tokensToSell
        compareVales[1] = 0.2 ether; //pricePerGrid
        compareVales[2] = 1010; //startBlock
        compareVales[3] = 3010; //endBlock
        compareVales[4] = 50; //liquidityBasisPoints
        compareVales[5] = 10; //referralBasisPoints
        compareVales[6] = 20; //previousLayerBasisPoints
        compareVales[7] = 0; //gridsOccupied
        compareVales[8] = 1; //prevLayerId
        checkLayerValues(compareVales, 2);

        compareVales[0] = 32000 ether; //tokensToSell
        compareVales[1] = 0.3 ether; //pricePerGrid
        compareVales[2] = 3010; //startBlock
        compareVales[3] = 6010; //endBlock
        compareVales[4] = 60; //liquidityBasisPoints
        compareVales[5] = 10; //referralBasisPoints
        compareVales[6] = 10; //previousLayerBasisPoints
        compareVales[7] = 0; //gridsOccupied
        compareVales[8] = 2; //prevLayerId
        checkLayerValues(compareVales, 3);

        compareVales[0] = 0;
        compareVales[1] = 0;
        compareVales[2] = 0;
        compareVales[3] = 0;
        compareVales[4] = 0;
        compareVales[5] = 0;
        compareVales[6] = 0;
        compareVales[7] = 0;
        compareVales[8] = 0;
        checkLayerValues(compareVales, 4);
        compareVales[0] = 0;
        compareVales[1] = 0;
        compareVales[2] = 0;
        compareVales[3] = 0;
        compareVales[4] = 0;
        compareVales[5] = 0;
        compareVales[6] = 0;
        compareVales[7] = 0;
        compareVales[8] = 0;
        checkLayerValues(compareVales, 0);
    }

    function test_deposit_multiple_users() public {
        // Single user deposits and gets 1 grid allocated
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
