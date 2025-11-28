pragma solidity 0.8.30;
import { WalletDummy } from "./WalletDummy.sol";
import { CurvyTypes } from "../utils/Types.sol";

// Salt: 0x1230000000000000000000000000000012300000000000000000000000000000

contract WalletFactory {
    function getCreationCode(CurvyTypes.Note memory note, address curvyAggregatorAlphaProxyAddress) public pure returns (bytes memory) {
        bytes memory bytecode = type(WalletDummy).creationCode; 
        bytes memory encodedArgs = abi.encode(note.ownerHash, note.amount, note.token, curvyAggregatorAlphaProxyAddress);
        return abi.encodePacked(bytecode, encodedArgs); 
    }

    function getContractAddress(CurvyTypes.Note memory note, address curvyAggregatorAlphaProxyAddress, bytes32 salt) public view returns (address) {
        bytes memory code = getCreationCode(note, curvyAggregatorAlphaProxyAddress);
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

    function deploy(CurvyTypes.Note memory note, address curvyAggregatorAlphaProxyAddress, bytes32 salt) public payable returns (address) {
        bytes memory creationCodeWithArgs = getCreationCode(note, curvyAggregatorAlphaProxyAddress);
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
        return addr;
    }
}