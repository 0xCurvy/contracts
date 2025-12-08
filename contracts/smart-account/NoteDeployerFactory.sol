// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {INoteDeployer} from "./INoteDeployer.sol";
import {NoteDeployer} from "./NoteDeployer.sol";
import {CurvyTypes} from "../utils/Types.sol";

contract NoteDeployerFactory is Ownable {
    bytes32 private _salt =
        keccak256(abi.encodePacked("curvy-note-deployer-factory-salt"));

    INoteDeployer public noteDeployer;

    address private _curvyVaultProxyAddress;
    address private _curvyAggregatorAlphaProxyAddress;
    address private _lifiDiamondAddress;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function updateConfig(
        CurvyTypes.NoteDeployerFactoryConfigurationUpdate memory _update
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
        bytes memory bytecode = type(NoteDeployer).creationCode;
        bytes memory encodedArgs = abi.encode(ownerHash);
        return abi.encodePacked(bytecode, encodedArgs);
    }

    function getContractAddress(
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
            revert("Shielding not supported on this chain");
        }

        bytes memory creationCodeWithArgs = getCreationCode(note.ownerHash);
        address noteDeployerAddress;

        bytes32 salt = _salt;

        assembly {
            // Deploy using CREATE2: value in wei, data pointer, data length, salt
            noteDeployerAddress := create2(
                callvalue(), // value to send
                add(creationCodeWithArgs, 0x20), // pointer to start of bytecode
                mload(creationCodeWithArgs), // length of bytecode
                salt // the salt
            )
        }
        require(noteDeployerAddress != address(0), "Deployment failed");

        noteDeployer = INoteDeployer(noteDeployerAddress);

        noteDeployer.shield(
            note,
            _curvyAggregatorAlphaProxyAddress,
            _curvyVaultProxyAddress
        );
    }

    function deployAndBridge(
        bytes calldata bridgeData,
        CurvyTypes.Note memory note,
        address tokenAddress
    ) public payable {
        if (_lifiDiamondAddress == address(0)) {
            revert("Bridging not supported on this chain");
        }

        bytes memory creationCodeWithArgs = getCreationCode(note.ownerHash);
        address noteDeployerAddress;

        bytes32 salt = _salt;

        assembly {
            // Deploy using CREATE2: value in wei, data pointer, data length, salt
            noteDeployerAddress := create2(
                callvalue(), // value to send
                add(creationCodeWithArgs, 0x20), // pointer to start of bytecode
                mload(creationCodeWithArgs), // length of bytecode
                salt // the salt
            )
        }
        require(noteDeployerAddress != address(0), "Deployment failed");

        noteDeployer = INoteDeployer(noteDeployerAddress);

        noteDeployer.bridge(
            _lifiDiamondAddress,
            bridgeData,
            note,
            tokenAddress
        );
    }
}
