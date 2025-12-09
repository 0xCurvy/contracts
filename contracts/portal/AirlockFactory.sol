// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IAirlock} from "./IAirlock.sol";
import {Airlock} from "./Airlock.sol";
import {CurvyTypes} from "../utils/Types.sol";

contract AirlockFactory is Ownable {
    bytes32 private _salt =
        keccak256(abi.encodePacked("curvy-airlock-factory-salt"));

    IAirlock public airlock;

    address private _curvyVaultProxyAddress;
    address private _curvyAggregatorAlphaProxyAddress;
    address private _lifiDiamondAddress;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function updateConfig(
        CurvyTypes.AirlockFactoryConfigurationUpdate memory _update
    ) external onlyOwner returns (bool) {
        if (_update.curvyVaultProxyAddress != address(0)) {
            _curvyVaultProxyAddress = _update.curvyVaultProxyAddress;
        }
        if (_update.curvyAggregatorAlphaProxyAddress != address(0)) {
            _curvyAggregatorAlphaProxyAddress = _update
                .curvyAggregatorAlphaProxyAddress;
        }
        if (_update.lifiDiamondAddress != address(0)) {
            _lifiDiamondAddress = _update.lifiDiamondAddress;
        }

        return true;
    }

    function getCreationCode(
        uint256 ownerHash
    ) public pure returns (bytes memory) {
        bytes memory bytecode = type(Airlock).creationCode;
        bytes memory encodedArgs = abi.encode(ownerHash);
        return abi.encodePacked(bytecode, encodedArgs);
    }

    function getAirlockAddress(
        uint256 ownerHash
    ) public view returns (address) {
        bytes memory code = getCreationCode(ownerHash);
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(code)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function deployAndShield(CurvyTypes.Note memory note) public payable {
        if (
            _curvyVaultProxyAddress == address(0) ||
            _curvyAggregatorAlphaProxyAddress == address(0)
        ) {
            revert("Airlock: Shielding not supported on this chain");
        }

        bytes memory creationCodeWithArgs = getCreationCode(note.ownerHash);
        address airlockAddress;

        bytes32 salt = _salt;

        assembly {
            // Deploy using CREATE2: value in wei, data pointer, data length, salt
            airlockAddress := create2(
                callvalue(), // value to send
                add(creationCodeWithArgs, 0x20), // pointer to start of bytecode
                mload(creationCodeWithArgs), // length of bytecode
                salt // the salt
            )
        }
        if (airlockAddress == address(0)) {
            revert("AirlockFactory: Deployment failed");
        }

        airlock = IAirlock(airlockAddress);

        airlock.shield(
            note,
            _curvyAggregatorAlphaProxyAddress,
            _curvyVaultProxyAddress
        );
    }

    function deployAndBridge(
        bytes calldata bridgeData,
        CurvyTypes.Note memory note,
        address tokenAddress
    ) public {
        if (_lifiDiamondAddress == address(0)) {
            revert("Bridging not supported on this chain");
        }

        bytes memory creationCodeWithArgs = getCreationCode(note.ownerHash);
        address airlockAddress;

        bytes32 salt = _salt;

        assembly {
            // Deploy using CREATE2: value in wei, data pointer, data length, salt
            airlockAddress := create2(
                callvalue(), // value to send
                add(creationCodeWithArgs, 0x20), // pointer to start of bytecode
                mload(creationCodeWithArgs), // length of bytecode
                salt // the salt
            )
        }
        if (airlockAddress == address(0)) {
            revert("AirlockFactory: Deployment failed");
        }

        airlock = IAirlock(airlockAddress);

        airlock.bridge(_lifiDiamondAddress, bridgeData, note, tokenAddress);
    }
}
