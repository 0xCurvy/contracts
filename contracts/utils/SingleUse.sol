// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SingleUse {
    bool internal _used;

    modifier onlyOnce() {
        require(!_used, "SingleUse: Already used");
        _;
        _used = true;
    }
}
