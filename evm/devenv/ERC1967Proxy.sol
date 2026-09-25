// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC1967Proxy as OZERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ERC1967Proxy is OZERC1967Proxy {
    constructor(address implementation, bytes memory data) OZERC1967Proxy(implementation, data) {}
}
