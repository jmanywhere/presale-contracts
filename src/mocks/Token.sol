//SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint initCap
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, initCap);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
