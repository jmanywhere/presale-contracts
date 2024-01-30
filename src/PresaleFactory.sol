//SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./interface/ITieredPresaleFactory.sol";

contract Factory is ITieredPresaleFactory {
    function createPresale() external payable returns (address) {
        // Make sure to get the creation fee from the user
        // Creation fee is in NATIVE
        return address(0);
    }

    function getInProgress() external view returns (address[] memory) {}

    function getCompleted() external view returns (address[] memory) {}

    function getAll() external view returns (address[] memory) {}
}
