// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./interface/ITieredPresale.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error TPresale__InvalidSetup();

contract TieredPresale is ITieredPresale, Ownable, ReentrancyGuard {
    //-----------------------------------------------------------------------------------
    // GLOBAL STATE
    //-----------------------------------------------------------------------------------
    mapping(uint8 layerId => LayerInfo) public layer;
    uint256 public totalTokensToSell;
    uint8 public immutable totalLayers;
    uint8 public immutable gridsPerLayer;

    //-----------------------------------------------------------------------------------
    // CONSTRUCTOR
    //-----------------------------------------------------------------------------------
    /**
     * @notice CONSTRUCTOR
     * @param gridInfo Grid settings
     * [0] totalLayers
     * [1] totalGridsPerLayer
     * LAYER ONE
     * [2] liquidityBasisPoints
     * [3] referralBasisPoints
     * OTHER LAYERS
     * [4] liquidityBasisPoints
     * [5] referralBasisPoints
     * [6] previousLayerBasisPoints
     * @param layerCreateInfo Layer settings
     * LAYER ONE
     * [0] startBlock
     * [1] blockDuration
     * [2] pricePerGrid
     * [3] tokensPerGrid
     * OTHER LAYERS
     * [4] blockDuration
     * [5] pricePerGrid
     * [6] tokensPerGrid
     */
    constructor(
        uint8[] memory gridInfo,
        uint256[] memory layerCreateInfo
    ) Ownable(msg.sender) {
        totalLayers = gridInfo[0];
        gridsPerLayer = gridInfo[1];
        // Check the Grid Info has the correct length
        uint256 configLength = gridInfo.length;
        configLength -= 4;
        if (totalLayers > 1 && configLength % 3 != 0) {
            revert TPresale__InvalidSetup();
        }
        // Check that layerCreateInfo has the correct length
        configLength = layerCreateInfo.length;
        configLength -= 4;
        if (totalLayers > 1 && configLength % 3 != 0) {
            revert TPresale__InvalidSetup();
        }

        LayerInfo storage setupLayer = layer[0];
        // Setup LAYER 1
        setupLayer.startBlock = layerCreateInfo[0];
        setupLayer.endBlock = layerCreateInfo[0] + layerCreateInfo[1];
        setupLayer.pricePerGrid = layerCreateInfo[2];
        setupLayer.tokensToSell = layerCreateInfo[3] * uint256(gridsPerLayer);
        setupLayer.usersOnGrid = new address[](gridsPerLayer);
        setupLayer.liquidityBasisPoints = gridInfo[2];
        setupLayer.referralBasisPoints = gridInfo[3];
        setupLayer.previousLayerBasisPoints = 0;
        // Setup LAYER 2 and above
        for (uint8 i = 2; i <= totalLayers; i++) {
            setupLayer = layer[i];
            uint8 offset = (3 * i) - 2;
            setupLayer.startBlock = layer[i - 1].endBlock;
            setupLayer.endBlock =
                setupLayer.startBlock +
                layerCreateInfo[offset];
            setupLayer.pricePerGrid = layerCreateInfo[offset + 1];
            setupLayer.tokensToSell =
                layerCreateInfo[offset + 2] *
                uint256(gridsPerLayer);
            setupLayer.usersOnGrid = new address[](gridsPerLayer);
            setupLayer.liquidityBasisPoints = gridInfo[offset];
            setupLayer.referralBasisPoints = gridInfo[offset + 1];
            setupLayer.previousLayerBasisPoints = gridInfo[offset + 2];
        }
    }
}
