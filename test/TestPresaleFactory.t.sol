// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Factory} from "../src/PresaleFactory.sol";
import {TieredPresale} from "../src/TieredPresale.sol";
import {Token} from "../src/mocks/Token.sol";

contract TestPresaleFactory is Test {
    Factory public factory;
    Token public saleToken;
    address public router = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address public user = makeAddr("user");
    address public owner = makeAddr("owner");

    function setUp() public {
        // Deploy factory
        factory = Factory(payable(0xBca2415C12f94983f0Af370A1f719d1ca64E4c16));

        // Setup user with ETH
        vm.deal(user, 100 ether);
        vm.deal(owner, 100 ether);
    }

    function test_CreatePresale() public {
        // Create grid info array
        uint8[] memory gridInfo = new uint8[](13);
        gridInfo[0] = 5; // totalLayers
        gridInfo[1] = 4; // gridSize (2x2 = 4 grids per layer)

        // Layer 1: 80/20 split
        gridInfo[2] = 80; // liquidityBasisPoints
        gridInfo[3] = 20; // referralBasisPoints

        // Layer 2-5: 60/20/20 split
        for (uint8 i = 1; i < 5; i++) {
            uint8 offset = i * 3 + 2;
            gridInfo[offset] = 60; // liquidityBasisPoints
            gridInfo[offset + 1] = 20; // referralBasisPoints
            gridInfo[offset + 2] = 20; // previousLayerBasisPoints
        }

        // Create layer info array
        uint256[] memory layerCreateInfo = new uint256[](16);
        layerCreateInfo[0] = block.number; // startBlock
        layerCreateInfo[1] = 8062; // blockDuration
        layerCreateInfo[2] = 0.01 ether; // pricePerGrid
        layerCreateInfo[3] = 15000000000000000000000; // tokensPerGrid

        // Layer 2
        layerCreateInfo[4] = 8062; // blockDuration
        layerCreateInfo[5] = 0.04 ether; // pricePerGrid
        layerCreateInfo[6] = 15000000000000000000000; // tokensPerGrid

        // Layer 3
        layerCreateInfo[7] = 8062; // blockDuration
        layerCreateInfo[8] = 0.08 ether; // pricePerGrid
        layerCreateInfo[9] = 15000000000000000000000; // tokensPerGrid

        // Layer 4
        layerCreateInfo[10] = 8062; // blockDuration
        layerCreateInfo[11] = 0.16 ether; // pricePerGrid
        layerCreateInfo[12] = 15000000000000000000000; // tokensPerGrid

        // Layer 5
        layerCreateInfo[13] = 8062; // blockDuration
        layerCreateInfo[14] = 0.32 ether; // pricePerGrid
        layerCreateInfo[15] = 15000000000000000000000; // tokensPerGrid

        // Create presale
        vm.startPrank(user);
        address presaleAddress = factory.createPresale{value: 0.4 ether}(
            gridInfo,
            layerCreateInfo,
            0x2A75Ebc9A2341Ae3a8F63e2C1DB350776CE9FE00, // sellToken
            address(0), // receiveToken (native)
            router,
            10000000000000000000000 // liquidityAmount
        );
        vm.stopPrank();

        // Verify presale was created
        assertTrue(
            factory.isPresale(presaleAddress),
            "Presale not registered in factory"
        );

        // Get presale contract
        TieredPresale presale = TieredPresale(presaleAddress);

        // Verify presale parameters
        assertEq(presale.totalLayers(), 5, "Incorrect total layers");
        assertEq(presale.gridsPerLayer(), 4, "Incorrect grids per layer");
        assertEq(
            presale.saleToken(),
            0x2A75Ebc9A2341Ae3a8F63e2C1DB350776CE9FE00,
            "Incorrect sale token"
        );
        assertEq(presale.receiveToken(), address(0), "Incorrect receive token");
        assertEq(presale.router(), router, "Incorrect router");
        assertEq(presale.saleOwnerWallet(), user, "Incorrect sale owner");

        // Verify layer 1 parameters
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint8 liquidityBP1,
            uint8 referralBP1,
            uint8 prevLayerBP1
        ) = presale.layer(1);
        assertEq(liquidityBP1, 80, "Incorrect layer 1 liquidity basis points");
        assertEq(referralBP1, 20, "Incorrect layer 1 referral basis points");
        assertEq(
            prevLayerBP1,
            0,
            "Incorrect layer 1 previous layer basis points"
        );

        // Verify layer 2-5 parameters
        for (uint8 i = 2; i <= 5; i++) {
            (
                ,
                ,
                ,
                ,
                ,
                ,
                ,
                uint8 liquidityBP,
                uint8 referralBP,
                uint8 prevLayerBP
            ) = presale.layer(i);
            assertEq(
                liquidityBP,
                60,
                string.concat(
                    "Incorrect layer ",
                    vm.toString(i),
                    " liquidity basis points"
                )
            );
            assertEq(
                referralBP,
                20,
                string.concat(
                    "Incorrect layer ",
                    vm.toString(i),
                    " referral basis points"
                )
            );
            assertEq(
                prevLayerBP,
                20,
                string.concat(
                    "Incorrect layer ",
                    vm.toString(i),
                    " previous layer basis points"
                )
            );
        }
    }
}
