// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { INoteDeployer } from "./INoteDeployer.sol";
import { NoteDeployer } from "./NoteDeployer.sol";
import { CurvyTypes } from "../utils/Types.sol";

contract NoteDeployerFactory {
    bytes32 private _salt = keccak256(abi.encodePacked("curvy-note-deployer-factory-salt"));

    INoteDeployer public noteDeployer;

    address private _curvyVaultProxyAddress;
    address private _curvyAggregatorAlphaProxyAddress;

    constructor (address curvyAggregatorAlphaProxyAddress, address curvyVaultProxyAddress) {
        _curvyAggregatorAlphaProxyAddress = curvyAggregatorAlphaProxyAddress;
        _curvyVaultProxyAddress = curvyVaultProxyAddress;
    }

    function getCreationCode(uint256 ownerHash) public pure returns (bytes memory) {
        bytes memory bytecode = type(NoteDeployer).creationCode;
        bytes memory encodedArgs = abi.encode(ownerHash);
        return abi.encodePacked(bytecode, encodedArgs); 
    }

    function getContractAddress(uint256 ownerHash) public view returns (address) {
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

    function deploy(CurvyTypes.Note memory note) public payable {
        bytes memory creationCodeWithArgs = getCreationCode(note.ownerHash);
        address noteDeployerAddress;

        bytes32 salt = _salt;

        assembly {
            // Deploy using CREATE2: value in wei, data pointer, data length, salt
            noteDeployerAddress := create2(
                callvalue(),                     // value to send
                add(creationCodeWithArgs, 0x20), // pointer to start of bytecode
                mload(creationCodeWithArgs),     // length of bytecode
                salt                             // the salt
            )
        }
        require(noteDeployerAddress != address(0), "Deployment failed");

        noteDeployer = INoteDeployer(noteDeployerAddress);
        noteDeployer.shield(note, _curvyAggregatorAlphaProxyAddress, _curvyVaultProxyAddress);
    }
}