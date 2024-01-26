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

    function test_presale_with_token_setup() public {
        assertEq(presaleWithToken.currentLayerId(), 0);
        assertEq(presaleWithToken.totalLayers(), 3);
        assertEq(presaleWithToken.totalTokensToSell(), 72000 ether);
    }
}
