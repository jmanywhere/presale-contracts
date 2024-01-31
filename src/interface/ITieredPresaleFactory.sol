// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITieredPresaleFactory {
    /**
     * @dev Creates a new presale contract and registers it in the factory.
     */
    function createPresale(
        uint8[] memory gridInfo,
        uint256[] memory layerCreateInfo,
        address sellToken,
        address receiveToken,
        address router,
        uint liquidityAmount
    ) external payable returns (address);

    function getInProgress() external view returns (address[] memory);

    function getCompleted() external view returns (address[] memory);

    function getAll() external view returns (address[] memory);

    /*---------------------------------------
     *  EVENTS
     *--------------------------------------*/

    event CreatePresale(
        address indexed presale,
        address indexed owner,
        address indexed tokenToSell
    );
}
