// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ReentrancyGuardWithInitializer} from "../utils/ReentrancyGuardWithInitializer.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICSUC} from "./interfaces/ICSUC.sol";
import {ICSUC_ActionHandler} from "./interfaces/ICSUC_ActionHandler.sol";

import {CSUC_Types} from "./utils/_Types.sol";
import {CSUC_Constants} from "./utils/_Constants.sol";

/**
 * @title CSUC (Curvy Single User Contract)
 * @author Curvy Protocol (https://curvy.box)
 * @dev CSUC main contract.
 */
contract CSUC is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardWithInitializer,
    ERC1155Upgradeable,
    ICSUC
{
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ERC1155_init(CSUC_Constants.CSUC_URI);
        __ReentrancyGuardWithInitializer_init();
    }

    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

    /// @inheritdoc ICSUC
    function updateConfig(CSUC_Types.ConfigUpdate memory _update) public onlyOwner returns (bool) {
        if (_update.newOperator != address(0)) {
            operator = _update.newOperator;
        }
        if (_update.newFeeCollector != address(0)) {
            feeCollector = _update.newFeeCollector;
        }
        if (_update.newAggregator != address(0)) {
            aggregator = _update.newAggregator;
        }

        for (uint256 i = 0; i < _update.actionHandlingInfoUpdate.length; ++i) {
            CSUC_Types.ActionHandlingInfoUpdate memory _aUpdate = _update.actionHandlingInfoUpdate[i];
            actionInfo[_aUpdate.actionId] = _aUpdate.info;
            actionBecomesActiveAt[_aUpdate.actionId] = block.number + CSUC_Constants.ACTION_BECOMES_ACTIVE_AFTER_BLOCKS;
        }

        emit ConfigUpdated(_update);

        return true;
    }

    /// @inheritdoc ICSUC
    function operatorExecute(CSUC_Types.Action[] memory _actions)
        public
        onlyOperator
        nonReentrant
        returns (uint256 _actionsExecuted)
    {
        address _token;
        uint256 _total;

        for (uint256 i = 0; i < _actions.length; ++i) {
            // Note: the fee is not taken in the action handler
            _token = _actions[i].payload.token;
            _total += _actions[i].payload.totalFee;

            if (i == _actions.length - 1 || _actions[i].payload.actionId == CSUC_Constants.CLEAR_ACTION_ID) {
                // Used to enable multiple actions using different tokens in a single call
                (uint256 _balance, uint256 _nonce) = _unpackBalanceAndNonce(balanceAndNonce[_token][feeCollector]);
                balanceAndNonce[_token][feeCollector] = _packBalanceAndNonce(_balance + _total, _nonce);

                _token = _actions[i].payload.token;
                _total = 0;

                if (i != _actions.length - 1) {
                    // If this is not the last action, we continue to the next iteration
                    continue;
                }
            }

            if (_actionIsValid(_actions[i]) != true) {
                continue;
            }

            if (_actions[i].payload.actionId == CSUC_Constants.TRANSFER_ACTION_ID) {
                require(_coreActionTransfer(_actions[i]), "CSUC: core action transfer failed!");
            } else if (_actions[i].payload.actionId == CSUC_Constants.WITHDRAWAL_ACTION_ID) {
                require(_coreActionWithdrawal(_actions[i]), "CSUC: core action withdrawal failed!");
            } else {
                if (actionIsActive(_actions[i].payload.actionId) == false) continue;

                address _handler = actionInfo[_actions[i].payload.actionId].handler;
                require(_handler != address(0), "CSUC: action handler not set!");

                (, uint256 _nonceBefore) = _unpackBalanceAndNonce(balanceAndNonce[_token][_actions[i].from]);

                /// @custom:oz-upgrades-unsafe-allow delegatecall
                (bool _success, bytes memory _returnData) = _handler.delegatecall(
                    abi.encodeWithSelector(ICSUC_ActionHandler.handleAction.selector, _actions[i])
                );
                require(_success, "CSUC: custom action handler call failed!");
                bool _result = abi.decode(_returnData, (bool));
                require(_result, "CSUC: custom action handler returned false!");

                (, uint256 _nonceAfter) = _unpackBalanceAndNonce(balanceAndNonce[_token][_actions[i].from]);

                require(_nonceAfter == _nonceBefore + 1, "CSUC: custom action handler nonce not incremented!");
            }

            ++_actionsExecuted;
            emit ActionExecuted(_actions[i]);
        }

        return _actionsExecuted;
    }

    function actionHandlerCallback(CSUC_Types.Action[] memory _actions) public returns (uint256 _actionsExecuted) {
        require(msg.sender == aggregator, "CSUC: Only Aggregator can run this callback.");

        for (uint256 i = 0; i < _actions.length; ++i) {
            // Note: No fees are applied for the Aggregator actions
            if (_actions[i].payload.actionId == CSUC_Constants.TRANSFER_ACTION_ID) {
                require(_coreActionTransfer(_actions[i]), "CSUC: core action transfer failed!");
            } else {
                revert("CSUC: Unsupported action in Aggregator callback!");
            }
        }

        _actionsExecuted = _actions.length;
    }

    /// @inheritdoc ICSUC
    function actionIsActive(uint256 _actionId) public view returns (bool) {
        return actionBecomesActiveAt[_actionId] <= block.number;
    }

    /// @inheritdoc ERC1155Upgradeable
    function balanceOf(address _owner, uint256 _token) public view override(ERC1155Upgradeable) returns (uint256) {
        return balanceOf(_owner, address(uint160(_token)));
    }

    /// @inheritdoc ERC1155Upgradeable
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes memory)
        public
        override(ERC1155Upgradeable)
    {
        require(isApprovedForAll(_from, msg.sender) || msg.sender == _from, "CSUC: caller is not approved!");
        address _token = address(uint160(_id));
        uint256 _fee = getMandatoryFee(CSUC_Constants.TRANSFER_ACTION_ID, _value);
        uint256 _neededAmount = _value + _fee;
        _assertBalanceIsEnough(_token, _from, _neededAmount);

        (uint256 _balance, uint256 _nonce) = _unpackBalanceAndNonce(balanceAndNonce[_token][_from]);
        balanceAndNonce[_token][_from] = _packBalanceAndNonce(_balance - _neededAmount, _nonce + 1);

        (_balance, _nonce) = _unpackBalanceAndNonce(balanceAndNonce[_token][_to]);
        balanceAndNonce[_token][_to] = _packBalanceAndNonce(_balance + _value, _nonce);

        (_balance, _nonce) = _unpackBalanceAndNonce(balanceAndNonce[_token][feeCollector]);
        balanceAndNonce[_token][feeCollector] = _packBalanceAndNonce(_balance + _fee, _nonce);

        emit TransferSingle(msg.sender, _from, _to, _id, _value);
    }

    /// @inheritdoc ERC1155Upgradeable
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    ) public override(ERC1155Upgradeable) {
        require(_ids.length == _values.length, "CSUC: ids and values length mismatch!");
        require(_ids.length != 0, "CSUC: arrays cannot be empty!");

        for (uint256 i = 0; i < _ids.length; ++i) {
            safeTransferFrom(_from, _to, _ids[i], _values[i], _data);
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
    }

    /// @inheritdoc ICSUC
    function balanceOf(address _owner, address _token) public view returns (uint256) {
        (uint256 _balance,) = _unpackBalanceAndNonce(balanceAndNonce[_token][_owner]);
        return _balance;
    }

    /// @inheritdoc ICSUC
    function nonceOf(address _owner, address _token) public view returns (uint256) {
        (, uint256 _nonce) = _unpackBalanceAndNonce(balanceAndNonce[_token][_owner]);
        return _nonce;
    }

    /// @inheritdoc ICSUC
    function wrap(address _to, address _token, uint256 _amount) public payable returns (bool) {
        if (msg.value != 0) {
            require(wrapNative(_to), "CSUC: native token wrapping failed!");
        }

        require(wrapERC20(_to, _token, _amount), "CSUC: ERC20 token wrapping failed!");

        return true;
    }

    /// @inheritdoc ICSUC
    function wrapNative(address _to) public payable returns (bool) {
        require(msg.value != 0, "CSUC: wrapping 0 value not allowed!");

        (uint256 _balance, uint256 _nonce) = _unpackBalanceAndNonce(balanceAndNonce[CSUC_Constants.NATIVE_TOKEN][_to]);
        balanceAndNonce[CSUC_Constants.NATIVE_TOKEN][_to] = _packBalanceAndNonce(_balance + msg.value, _nonce);

        emit WrappingToken(_to, CSUC_Constants.NATIVE_TOKEN, msg.value);

        return true;
    }

    /// @inheritdoc ICSUC
    function wrapERC20(address _to, address _token, uint256 _amount) public returns (bool) {
        require(_amount != 0, "CSUC: wrapping 0 value not allowed!");

        uint256 _totalBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _totalAfter = IERC20(_token).balanceOf(address(this));
        require(_totalAfter - _totalBefore == _amount, "CSUC: ERC20 transfer failed!");

        (uint256 _balance, uint256 _nonce) = _unpackBalanceAndNonce(balanceAndNonce[_token][_to]);
        balanceAndNonce[_token][_to] = _packBalanceAndNonce(_balance + _amount, _nonce);

        emit WrappingToken(_to, _token, _amount);

        return true;
    }

    /// @inheritdoc ICSUC
    function unwrap(CSUC_Types.Action memory _action) public nonReentrant returns (bool) {
        require(_action.payload.actionId == CSUC_Constants.WITHDRAWAL_ACTION_ID, "CSUC: wrong action id!");

        require(_actionIsValid(_action), "CSUC: withdrawal action is invalid!");

        require(_coreActionWithdrawal(_action), "CSUC: core action withdrawal failed!");

        (uint256 _balance, uint256 _nonce) =
            _unpackBalanceAndNonce(balanceAndNonce[_action.payload.token][_action.from]);
        balanceAndNonce[_action.payload.token][feeCollector] =
            _packBalanceAndNonce(_balance + _action.payload.totalFee, _nonce);

        address _to = abi.decode(_action.payload.parameters, (address));

        emit UnwrappingToken(_to, _action.payload.token, _action.payload.amount);

        return true;
    }

    /// @inheritdoc ICSUC
    function getMandatoryFee(uint256 _actionId, uint256 _amount) public view returns (uint256) {
        return 1 + (actionInfo[_actionId].mandatoryFeePoints * _amount) / CSUC_Constants.FEE_PRECISION;
    }

    /// @inheritdoc ICSUC
    function getActionHandlingInfo(uint256 _actionId) public view returns (CSUC_Types.ActionHandlingInfo memory) {
        return actionInfo[_actionId];
    }

    /// @inheritdoc ICSUC
    function batchCSAInfo(address[] memory _owners, address[] memory _tokens)
        external
        view
        returns (CSUC_Types.CSAInfo[] memory _csaInfos)
    {
        _csaInfos = new CSUC_Types.CSAInfo[](_owners.length * _tokens.length);
        for (uint256 i = 0; i < _owners.length; ++i) {
            _csaInfos[i] = CSUC_Types.CSAInfo({
                owner: _owners[i],
                token: _tokens[i],
                balance: balanceOf(_owners[i], _tokens[i]),
                nonce: nonceOf(_owners[i], _tokens[i])
            });
        }

        return _csaInfos;
    }

    /**
     * @notice Checks if the action is valid.
     * @param _action The action to be checked.
     * @return _isValid Returns whether the action is valid or not.
     */
    function _actionIsValid(CSUC_Types.Action memory _action) internal view returns (bool _isValid) {
        address _signer = ecrecover(
            _hashActionPayload(_action.from, _action.payload),
            _action.signature_v,
            _action.signature_r,
            _action.signature_s
        );

        bool _signerIsCorrect = _signer == _action.from;

        bool _blockNumberIsCorrect = _action.payload.limit >= block.number;

        bool _totalFeeIsCorrectlyComputed =
            _action.payload.totalFee >= getMandatoryFee(_action.payload.actionId, _action.payload.amount);

        return _signerIsCorrect && _blockNumberIsCorrect && _totalFeeIsCorrectlyComputed;
    }

    /**
     * @notice Hashes the action payload with the User's address and the current nonce.
     * @dev This function is used to create a unique hash for the action payload, that
     *      can be signed by the User's CSA. Its visibility is public to allow for easier
     *      testing and debugging.
     * @param _from The address of the User's CSA.
     * @param _payload The action payload containing the action details.
     * @return _hash Returns the hash of the action payload.
     */
    function _hashActionPayload(address _from, CSUC_Types.ActionPayload memory _payload)
        public
        view
        returns (bytes32 _hash)
    {
        (, uint256 _nonce) = _unpackBalanceAndNonce(balanceAndNonce[_payload.token][_from]);
        return keccak256(abi.encode(block.chainid, _payload, _nonce));
    }

    /**
     * @notice Hashes the action payload with the User's address and a custom nonce.
     * @dev This function is used to create a unique hash for the action payload, that
     *      can be signed by the User's CSA. Its visibility is public to allow for easier
     *      testing and debugging.
     * @param _payload The action payload containing the action details.
     * @param _nonce The custom nonce to be used in the hash.
     * @return _hash Returns the hash of the action payload.
     */
    function _hashActionPayloadWithCustomNonce(CSUC_Types.ActionPayload memory _payload, uint256 _nonce)
        public
        view
        returns (bytes32 _hash)
    {
        return keccak256(abi.encode(block.chainid, _payload, _nonce));
    }

    /**
     * @notice Handles the core transfer action.
     * @dev This function is used to transfer tokens from one User's CSA to another.
     *      It checks if the balance is enough, updates the balances and nonces accordingly,
     *      and returns true if the transfer was successful.
     * @param _action The action containing all of the necessary info.
     * @return _success Returns whether the call was successful.
     */
    function _coreActionTransfer(CSUC_Types.Action memory _action) internal returns (bool _success) {
        uint256 _neededAmount = _action.payload.totalFee + _action.payload.amount;
        if (!_fromHasEnoughAssets(_action.payload.token, _action.from, _neededAmount)) {
            return false;
        }

        (uint256 _balance, uint256 _nonce) =
            _unpackBalanceAndNonce(balanceAndNonce[_action.payload.token][_action.from]);
        balanceAndNonce[_action.payload.token][_action.from] =
            _packBalanceAndNonce(_balance - _neededAmount, _nonce + 1);

        address _to = abi.decode(_action.payload.parameters, (address));

        (_balance, _nonce) = _unpackBalanceAndNonce(balanceAndNonce[_action.payload.token][_to]);
        balanceAndNonce[_action.payload.token][_to] = _packBalanceAndNonce(_balance + _action.payload.amount, _nonce);

        return true;
    }

    /**
     * @notice Handles the core withdrawal action.
     * @dev This function is used to withdraw tokens from a User's CSA to a specified address.
     *      It checks if the balance is enough, updates the balances and nonces accordingly,
     *      and returns true if the withdrawal was successful.
     * @param _action The action containing all of the necessary info.
     * @return _success Returns whether the call was successful.
     */
    function _coreActionWithdrawal(CSUC_Types.Action memory _action) internal returns (bool _success) {
        uint256 _neededAmount = _action.payload.totalFee + _action.payload.amount;
        if (!_fromHasEnoughAssets(_action.payload.token, _action.from, _neededAmount)) {
            return false;
        }

        (uint256 _balance, uint256 _nonce) =
            _unpackBalanceAndNonce(balanceAndNonce[_action.payload.token][_action.from]);
        balanceAndNonce[_action.payload.token][_action.from] =
            _packBalanceAndNonce(_balance - _neededAmount, _nonce + 1);

        address _to = abi.decode(_action.payload.parameters, (address));

        uint256 _balanceBefore;
        uint256 _balanceAfter;
        if (_action.payload.token == CSUC_Constants.NATIVE_TOKEN) {
            _balanceBefore = _to.balance;
            (_success,) = _to.call{value: _action.payload.amount}("");
            require(_success, "CSUC: native token transfer failed!");
            _balanceAfter = _to.balance;
        } else {
            _balanceBefore = IERC20(_action.payload.token).balanceOf(_to);
            IERC20(_action.payload.token).safeTransfer(_to, _action.payload.amount);
            _balanceAfter = IERC20(_action.payload.token).balanceOf(_to);
        }

        _success = _balanceAfter - _action.payload.amount == _balanceBefore;
        require(_success, "CSUC: withdrawal failed - amounts don't match!");

        return true;
    }

    /**
     * @notice Asserts that the balance of the User's CSA is enough to cover the full cost of the action.
     * @dev This function checks if the balance is enough, and reverts if it is not.
     * @param _token The token address.
     * @param _from The User's CSA address.
     * @param _amount The amount to be checked.
     */
    function _assertBalanceIsEnough(address _token, address _from, uint256 _amount) internal view {
        require(_fromHasEnoughAssets(_token, _from, _amount), "CSUC: balance is not enough to cover cost!");
    }

    /**
     * @notice Checks that the balance of the User's CSA is enough to cover the full cost of the action.
     * @param _token The token address.
     * @param _from The User's CSA address.
     * @param _amount The amount to be checked.
     * @return hasEnough Returns whether the User's CSA has enough balance to cover the cost of the action.
     */
    function _fromHasEnoughAssets(address _token, address _from, uint256 _amount)
        internal
        view
        returns (bool hasEnough)
    {
        (uint256 _balance,) = _unpackBalanceAndNonce(balanceAndNonce[_token][_from]);
        hasEnough = _balance >= _amount;
    }

    /**
     * @notice Packs the balance and nonce into a single uint256 value.
     * @dev This function is used to pack the balance and nonce into a single value for storage efficiency.
     * @param _balance The balance to be packed.
     * @param _nonce The nonce to be packed.
     * @return _packed Returns the packed value.
     */
    function _packBalanceAndNonce(uint256 _balance, uint256 _nonce) internal pure returns (uint256 _packed) {
        require(_balance <= CSUC_Constants.MAX_BALANCE, "CSUC: balance is too big to pack!");
        require(_nonce <= CSUC_Constants.MAX_NONCE, "CSUC: nonce is too big to pack!");
        _packed = uint256((_balance << CSUC_Constants.BITS_FOR_NONCE) | _nonce);
        (uint256 _unpackedBalance, uint256 _unpackedNonce) = _unpackBalanceAndNonce(_packed);
        require(_unpackedBalance == _balance, "CSUC: checking balance unpacking failed!");
        require(_unpackedNonce == _nonce, "CSUC: checking nonce unpacking failed!");

        return _packed;
    }

    /**
     * @notice Unpacks the balance and nonce from a packed uint256 value.
     * @dev This function is used to unpack the balance and nonce from a single value for easier access.
     * @param _all The packed value containing both balance and nonce.
     * @return _balance Returns the unpacked balance.
     * @return _nonce Returns the unpacked nonce.
     */
    function _unpackBalanceAndNonce(uint256 _all) internal pure returns (uint256 _balance, uint256 _nonce) {
        return ((_all >> CSUC_Constants.BITS_FOR_NONCE) & CSUC_Constants.MASK_BALANCE, _all & CSUC_Constants.MASK_NONCE);
    }

    /// notice The fee collector address that receives all action fees.
    address public feeCollector;

    /// notice The operator address that can execute actions on behalf of Users.
    address public operator;

    /// notice The address of the Aggregator contract that interacts with CSUC.
    address public aggregator;

    /// notice The mapping of User's CSA balances and nonces.
    /// dev The mapping is structured as mapping[token][owner] = packedBalanceAndNonce.
    mapping(address => mapping(address => uint256)) public balanceAndNonce;

    /// notice The mapping of action IDs to their handling info.
    mapping(uint256 => CSUC_Types.ActionHandlingInfo) public actionInfo;

    /// notice The mapping of action IDs to the block number when they become active.
    mapping(uint256 => uint256) public actionBecomesActiveAt;

    /// notice Access control modifier that allows only the operator to execute certain functions.
    modifier onlyOperator() {
        require(msg.sender == operator, "CSUC: only operator can execute this call!");
        _;
    }

    using SafeERC20 for IERC20;
}
