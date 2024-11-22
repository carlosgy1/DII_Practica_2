// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CS_token is ERC20 {
    constructor() ERC20("Case", "CS") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}