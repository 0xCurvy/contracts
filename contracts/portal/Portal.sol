// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { CurvyTypes } from "../utils/Types.sol";
import { ICurvyAggregatorAlpha } from "../aggregator-alpha/ICurvyAggregatorAlpha.sol";
import { ICurvyVault } from "../vault/ICurvyVault.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPortal } from "./IPortal.sol";
import { SingleUse } from "../utils/SingleUse.sol";

contract Portal is IPortal, SingleUse {
    using SafeERC20 for IERC20;

    uint256 private _ownerHash;
    address constant private NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 constant private AGGREGATOR_CHAIN_ID = 42161; // added this here @lazar said this may be problematic, should i move this to the end?

    ICurvyAggregatorAlpha public curvyAggregator;
    ICurvyVault public curvyVault;

    address public recovery;

    modifier onlyRecovery() {
        require(msg.sender == recovery, "Portal: Only recovery");
        _;
    }

    constructor(uint256 ownerHash, address _recovery) {
        // TODO: add fee for deployment

        _ownerHash = ownerHash;
        recovery = _recovery;
    }

    /**
    * @dev Use this if the bridgeCallData is purely the ABI-encoded struct
     * (e.g., it was encoded using abi.encode(bridgeData))
     */
    function _decodeBridgeDataStruct(bytes calldata bridgeCallData) internal pure returns (LiFiBridgeData memory) {
        return abi.decode(bridgeCallData, (LiFiBridgeData));
    }

    /**
        * @dev Use this if the bridgeCallData is a full transaction payload
     * where the struct is the very first parameter after the 4-byte function selector.
     */
    function _decodeBridgeData(bytes calldata txData) internal pure returns (LiFiBridgeData memory) {
        // The first 4 bytes are the function selector, so we skip them
        return abi.decode(txData[4:], (LiFiBridgeData));
    }

    function shield(
        CurvyTypes.Note memory note,
        address curvyAggregatorAlphaProxyAddress,
        address curvyVaultProxyAddress
    ) external onlyOnce {
        if (note.ownerHash != _ownerHash) {
            revert InvalidOwnerHash();
        }

        curvyAggregator = ICurvyAggregatorAlpha(curvyAggregatorAlphaProxyAddress);
        curvyVault = ICurvyVault(curvyVaultProxyAddress);

        address tokenAddress;
        try curvyVault.getTokenAddress(note.token) returns (address _tokenAddress) {
            tokenAddress = _tokenAddress;
        } catch {
            // TODO: Emit shielding failed and if that event is detected in the simulation, then we will mark the shielding as failed.
            return; // Here we just do a return because we want the deployment to pass so that the user can call the recover method.
        }
        if (tokenAddress != address(0) && tokenAddress != NATIVE_ETH) {
            IERC20(tokenAddress).forceApprove(address(curvyAggregator), note.amount);
            curvyAggregator.autoShield(note, tokenAddress);
        } else {
            curvyAggregator.autoShield{ value: note.amount }(note, tokenAddress);
        }
    }

    function recover(address tokenAddress, address to) external onlyRecovery {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        if (tokenAddress == NATIVE_ETH) {
            (bool success, ) = to.call{ value: balance }("");
            require(success, "Portal: ETH transfer failed");
        } else {
            token.safeTransfer(to, balance);
        }
    }

    function bridge(
        address lifiDiamondAddress,
        bytes calldata bridgeData,
        CurvyTypes.Note memory note
    ) external onlyOnce {
        if (lifiDiamondAddress == address(0)) {
            revert InvalidLiFiAddress();
        }

        LiFiBridgeData memory data = _decodeBridgeData(bridgeData);

        if (data.receiver != address(this)) {
            revert InvalidReceiver();
        }

        if (data.destinationChainId != AGGREGATOR_CHAIN_ID) {
            revert InvalidDestinationChain();
        }

        if (note.ownerHash != _ownerHash) {
            revert InvalidOwnerHash();
        }

        if (note.amount < data.minAmount) {
            revert InsufficientAmountForBridging();
        }

        if (data.sendingAssetId != address(0) && data.sendingAssetId != NATIVE_ETH) {
            IERC20 token = IERC20(data.sendingAssetId);

            uint256 balance = token.balanceOf(address(this));
            if (balance < note.amount) {
                revert InsufficientBalanceForBridging();
            }

            token.forceApprove(lifiDiamondAddress, note.amount);
            (bool success, bytes memory returnData) = lifiDiamondAddress.call(bridgeData);

            if (!success) {
                assembly {
                    revert(add(returnData, 32), mload(returnData))
                }
            }
        } else {
            uint256 balance = address(this).balance;
            if (balance < note.amount) {
                revert InsufficientBalanceForBridging();
            }

            (bool success, bytes memory returnData) = lifiDiamondAddress.call{ value: note.amount }(bridgeData);

            if (!success) {
                assembly {
                    revert(add(returnData, 32), mload(returnData))
                }
            }
        }
    }

    function exitBridge(address lifiDiamondAddress, uint256 amountToBridge, bytes calldata bridgeData, bytes memory signature) external onlyOnce {
        if (lifiDiamondAddress == address(0)) {
            revert InvalidLiFiAddress();
        }

        LiFiBridgeData memory data = _decodeBridgeDataStruct(bridgeData);


        bytes32 messageHash = keccak256(
            abi.encodePacked(data.transactionId, data.receiver, data.destinationChainId, amountToBridge)
        );

        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);

        address recoveredSigner = ECDSA.recover(ethSignedMessageHash, signature);

        if (recoveredSigner != recovery) {
            revert InvalidSignatureOrTamperedData();
        }

        if (data.sendingAssetId != address(0) && data.sendingAssetId != NATIVE_ETH) {
            IERC20 token = IERC20(data.sendingAssetId);

            uint256 balance = token.balanceOf(address(this));
            if (balance < amountToBridge) {
                revert InsufficientBalanceForBridging();
            }

            token.forceApprove(lifiDiamondAddress, amountToBridge);
            (bool success, bytes memory returnData) = lifiDiamondAddress.call(bridgeData);

            if (!success) {
                assembly {
                    revert(add(returnData, 32), mload(returnData))
                }
            }
        } else {
            uint256 balance = address(this).balance;
            if (balance < amountToBridge) {
                revert InsufficientBalanceForBridging();
            }

            (bool success, bytes memory returnData) = lifiDiamondAddress.call{ value: amountToBridge }(bridgeData);

            if (!success) {
                assembly {
                    revert(add(returnData, 32), mload(returnData))
                }
            }
        }
    }
}
