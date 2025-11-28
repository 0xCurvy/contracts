pragma solidity ^0.8.28;
import { NoteDeployer } from "./NoteDeployer.sol";
import { CurvyTypes } from "../utils/Types.sol";

// Salt: 0x1230000000000000000000000000000012300000000000000000000000000000

contract NoteDeployerFactory {
    function getCreationCode(CurvyTypes.Note memory note, address curvyAggregatorAlphaProxyAddress, address curvyVaultProxyAddress) public pure returns (bytes memory) {
        bytes memory bytecode = type(NoteDeployer).creationCode;
        bytes memory encodedArgs = abi.encode(note.ownerHash, note.token, note.amount, curvyAggregatorAlphaProxyAddress, curvyVaultProxyAddress);
        return abi.encodePacked(bytecode, encodedArgs); 
    }

    function getContractAddress(CurvyTypes.Note memory note, address curvyAggregatorAlphaProxyAddress, address  curvyVaultProxyAddress, bytes32 salt) public view returns (address) {
        bytes memory code = getCreationCode(note, curvyAggregatorAlphaProxyAddress, curvyVaultProxyAddress);
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), 
                address(this), 
                salt, 
                keccak256(code)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function deploy(CurvyTypes.Note memory note, address curvyAggregatorAlphaProxyAddress, address curvyVaultProxyAddress, bytes32 salt) public payable {
        bytes memory creationCodeWithArgs = getCreationCode(note, curvyAggregatorAlphaProxyAddress, curvyVaultProxyAddress);
        address addr;

        assembly {
            // Deploy using CREATE2: value in wei, data pointer, data length, salt
            addr := create2(
                callvalue(),                     // value to send
                add(creationCodeWithArgs, 0x20), // pointer to start of bytecode
                mload(creationCodeWithArgs),     // length of bytecode
                salt                             // the salt
            )
        }
        require(addr != address(0), "Deployment failed");
    }
}