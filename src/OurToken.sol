// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {OurToken} from "../src/OurToken.sol";
import {Script} from "forge-std/Script.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract OurToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("OurToken", "OT") {
        _mint(msg.sender, initialSupply);
    }
}