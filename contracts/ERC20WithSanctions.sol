// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20Base.sol";

contract ERC20WithSanctions is ERC20Base {
    constructor() ERC20Base("Black List", "BLKL") {}
}