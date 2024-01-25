// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITieredPresaleFactory {
    /**
     * @dev Creates a new presale contract and registers it in the factory.
     */
    function createPresale() external returns (address);

    /**
     * @notice Ends the sale of a presale contract.
     * this one should be called by owner of presale contract to end the sale.
     */
    function endSale(address presale) external;

    /*---------------------------------------
     *  EVENTS
     *--------------------------------------*/

    event CreatePresale(
        address indexed presale,
        address indexed owner,
        address indexed tokenToSell
    );
}
