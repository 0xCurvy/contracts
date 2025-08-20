// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {CSUC, CSUC_Types, CSUC_Constants} from "../../src/csuc/CSUC.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockActionHandler} from "./mocks/MockActionHandler.sol";

contract CSUC_BoilerPlate is Test {
    function basicSetUp() public {
        // Roles for Curvy Governance:
        (owner, ownerPk) = makeAddrAndKey("owner");
        (operator, operatorPk) = makeAddrAndKey("operator");
        (feeCollector, feeCollectorPk) = makeAddrAndKey("feeCollector");

        // Curvy Users (EOA)
        vm.deal(user_EOA_0, 10 ether);

        // Curvy Users (Curvy Stealth Address (CSA)):
        (CSA_0, CSA_0_pk) = makeAddrAndKey("CSA_0");
        (CSA_1, CSA_1_pk) = makeAddrAndKey("CSA_1");

        vm.startBroadcast(owner);

        CSUC_Types.ConfigUpdate memory _configUpdate = _buildConfig();

        address proxy = Upgrades.deployUUPSProxy("CSUC.sol", abi.encodeCall(CSUC.initialize, ()));
        csuc = CSUC(proxy);
        csuc.updateConfig(_configUpdate);

        vm.stopBroadcast();

        vm.startBroadcast(m20_deployer);
        for (uint256 i = 0; i < N_ERC20_TOKENS; ++i) {
            m20.push(new MockERC20((10 ** 13) * (10 ** (6 + i))));
            m20[i].transfer(user_EOA_0, 2 * (10 ** 5));
        }
        vm.stopBroadcast();

        vm.startBroadcast(user_EOA_0);

        // csuc.wrapER20(address(m20), user_EOA_0, m20.balanceOf(user_EOA_0));

        vm.stopBroadcast();
    }

    function multipleSetUp() public {
        basicSetUp();

        for (uint256 i = 0; i < N_CSA; ++i) {
            (address _csa, uint256 _pk) = makeAddrAndKey(string(abi.encode(i + 1)));
            CSA.push(_csa);
            CSA_pk.push(_pk);
        }

        for (uint256 i = 0; i < N_USER; ++i) {
            users.push(address(uint160(i + 1)));
            vm.deal(users[i], 1 ether + i * (10 ** 18));
            for (uint256 j = 0; j < N_ERC20_TOKENS; ++j) {
                fundERC20(users[i], address(m20[j]), m20[j].totalSupply() / 10_000 + (i * 1_000_000));
            }
        }

        CSA_unusedCount = N_USER;
    }

    function _buildConfig() internal returns (CSUC_Types.ConfigUpdate memory) {
        actionHandlingInfoUpdate.push(
            CSUC_Types.ActionHandlingInfoUpdate({
                actionId: CSUC_Constants.DEPOSIT_ACTION_ID,
                info: CSUC_Types.ActionHandlingInfo({
                    mandatoryFeePoints: uint16(0), // 0.0%
                    handler: CSUC_Constants.CORE_ACTION_HANDLER
                })
            })
        );

        actionHandlingInfoUpdate.push(
            CSUC_Types.ActionHandlingInfoUpdate({
                actionId: CSUC_Constants.TRANSFER_ACTION_ID,
                info: CSUC_Types.ActionHandlingInfo({
                    mandatoryFeePoints: uint16(CSUC_Constants.FEE_PRECISION / 1000), // 0.1%
                    handler: CSUC_Constants.CORE_ACTION_HANDLER
                })
            })
        );

        actionHandlingInfoUpdate.push(
            CSUC_Types.ActionHandlingInfoUpdate({
                actionId: CSUC_Constants.WITHDRAWAL_ACTION_ID,
                info: CSUC_Types.ActionHandlingInfo({
                    mandatoryFeePoints: uint16(8 * (CSUC_Constants.FEE_PRECISION / 1000)), // 0.8%
                    handler: CSUC_Constants.CORE_ACTION_HANDLER
                })
            })
        );

        MockActionHandler mockActionHandler = new MockActionHandler();

        actionHandlingInfoUpdate.push(
            CSUC_Types.ActionHandlingInfoUpdate({
                actionId: CSUC_Constants.GENERIC_CUSTOM_ACTION_ID,
                info: CSUC_Types.ActionHandlingInfo({
                    mandatoryFeePoints: uint16(13 * (CSUC_Constants.FEE_PRECISION / 1000)), // 0.13%
                    handler: address(mockActionHandler)
                })
            })
        );

        CSUC_Types.ConfigUpdate memory _configUpdate = CSUC_Types.ConfigUpdate({
            newOperator: operator,
            newFeeCollector: feeCollector,
            newAggregator: address(0),
            actionHandlingInfoUpdate: actionHandlingInfoUpdate
        });

        return _configUpdate;
    }

    function getUnusedCSA() public returns (address _csa, uint256 _pk) {
        CSA_unusedCount += 1;
        return (CSA[CSA_unusedCount - 1], CSA_pk[CSA_unusedCount - 1]);
    }

    function fundERC20(address _to, address _token, uint256 _amount) public {
        vm.startBroadcast(m20_deployer);
        IERC20(_token).transfer(_to, _amount);
        vm.stopBroadcast();
    }

    function _wrap(address _from, address _to, address _token, uint256 _amount) public returns (uint256) {
        uint256 _gasUsed;

        vm.startBroadcast(_from);

        if (_token == CSUC_Constants.NATIVE_TOKEN) {
            uint256 _balanceBefore = csuc.balanceOf(_to, CSUC_Constants.NATIVE_TOKEN);
            uint256 _totalBefore = address(csuc).balance;

            uint256 gasLeftPreCall = gasleft();
            csuc.wrapNative{value: _amount}(_to);
            _gasUsed = gasLeftPreCall - gasleft();

            uint256 _balanceAfter = csuc.balanceOf(_to, CSUC_Constants.NATIVE_TOKEN);
            uint256 _totalAfter = address(csuc).balance;

            assertEq(_balanceAfter - _balanceBefore, _amount);
            assertEq(_totalAfter - _totalBefore, _amount);
        } else {
            uint256 _balanceBefore = csuc.balanceOf(_to, _token);
            uint256 _totalBefore = IERC20(_token).balanceOf(address(csuc));

            uint256 _gasLeftPreCall = gasleft();
            IERC20(_token).approve(address(csuc), _amount);
            csuc.wrapERC20(_to, _token, _amount);
            _gasUsed = _gasLeftPreCall - gasleft();

            uint256 _balanceAfter = csuc.balanceOf(_to, _token);
            uint256 _totalAfter = IERC20(_token).balanceOf(address(csuc));

            assertEq(_balanceAfter - _balanceBefore, _amount);
            assertEq(_totalAfter - _totalBefore, _amount);
        }

        vm.stopBroadcast();

        return _gasUsed;
    }

    function _createTransferAction(address _from, address _token, uint256 _amount)
        public
        returns (CSUC_Types.Action memory)
    {
        (address _csa, uint256 _csaPk) = getUnusedCSA();
        _wrap(_from, _csa, _token, _amount);

        (address _to,) = getUnusedCSA();
        uint256 _transferAmount = csuc.balanceOf(_csa, _token) / 3;
        uint256 _totalFee = csuc.getMandatoryFee(CSUC_Constants.TRANSFER_ACTION_ID, _transferAmount);

        CSUC_Types.Action memory _action = _prepareTransferAction(_csa, _csaPk, _to, _token, _transferAmount, _totalFee);

        actions.push(_action);

        return _action;
    }

    function _createWithdrawAction(address _csa, uint256 _csaPk, address _to, address _token, uint256 _amount)
        public
        returns (CSUC_Types.Action memory)
    {
        uint256 _totalFee = csuc.getMandatoryFee(CSUC_Constants.WITHDRAWAL_ACTION_ID, _amount);

        CSUC_Types.Action memory _action = _prepareWithdrawAction(_csa, _csaPk, _to, _token, _amount, _totalFee);

        actions.push(_action);

        return _action;
    }

    function _prepareTransferAction(
        address _fromCSA,
        uint256 _fromCSA_pk,
        address _to,
        address _token,
        uint256 _amount,
        uint256 _totalFee
    ) public view returns (CSUC_Types.Action memory) {
        CSUC_Types.ActionPayload memory _payload = CSUC_Types.ActionPayload({
            actionId: CSUC_Constants.TRANSFER_ACTION_ID,
            token: _token,
            amount: _amount,
            parameters: abi.encode(_to),
            totalFee: _totalFee,
            limit: block.number + 10
        });

        bytes32 _hash = csuc._hashActionPayload(_fromCSA, _payload);

        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(_fromCSA_pk, _hash);

        CSUC_Types.Action memory _action =
            CSUC_Types.Action({from: _fromCSA, payload: _payload, signature_v: _v, signature_r: _r, signature_s: _s});

        return _action;
    }

    function _prepareWithdrawAction(
        address _fromCSA,
        uint256 _fromCSA_pk,
        address _to,
        address _token,
        uint256 _amount,
        uint256 _totalFee
    ) public view returns (CSUC_Types.Action memory) {
        CSUC_Types.ActionPayload memory _payload = CSUC_Types.ActionPayload({
            actionId: CSUC_Constants.WITHDRAWAL_ACTION_ID,
            token: _token,
            amount: _amount,
            parameters: abi.encode(_to),
            totalFee: _totalFee,
            limit: block.number + 10
        });

        bytes32 _hash = csuc._hashActionPayload(_fromCSA, _payload);

        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(_fromCSA_pk, _hash);

        CSUC_Types.Action memory _action =
            CSUC_Types.Action({from: _fromCSA, payload: _payload, signature_v: _v, signature_r: _r, signature_s: _s});

        return _action;
    }

    function _operatorExecute() public returns (uint256) {
        (uint256 _totalGasCost,) = _operatorExecuteWithReturn();
        return _totalGasCost;
    }

    function _operatorExecuteWithReturn() public returns (uint256, uint256) {
        uint256 _gasUsed;

        vm.startBroadcast(operator);
        // Mandatory CLEAR_ACTION
        CSUC_Types.ActionPayload memory _payload = CSUC_Types.ActionPayload({
            actionId: CSUC_Constants.CLEAR_ACTION_ID,
            token: CSUC_Constants.NATIVE_TOKEN,
            amount: 0,
            parameters: hex"",
            totalFee: 0,
            limit: block.number + 10
        });

        CSUC_Types.Action memory _action = CSUC_Types.Action({
            from: operator,
            payload: _payload,
            // note: no valid signature required since `onlyOperator` can call it
            signature_v: uint8(0),
            signature_r: bytes32(0),
            signature_s: bytes32(0)
        });

        actions.push(_action);

        uint256 _gasLeftPreCall = gasleft();
        uint256 _actionsExecuted = csuc.operatorExecute(actions);
        _gasUsed = _gasLeftPreCall - gasleft();

        vm.stopBroadcast();

        return (_gasUsed, _actionsExecuted);
    }

    function _shuffleActions() public {
        uint256[] memory _actionIndices = new uint256[](actions.length);
        for (uint256 i = 0; i < actions.length; ++i) {
            _actionIndices[i] = i;
        }
        _actionIndices = vm.sort(_actionIndices);

        CSUC_Types.Action[] memory _sortedActions = new CSUC_Types.Action[](actions.length);
        for (uint256 i = 0; i < actions.length; ++i) {
            _sortedActions[_actionIndices[i]] = actions[i];
        }
        for (uint256 i = 0; i < actions.length; ++i) {
            actions[i] = _sortedActions[i];
        }
    }

    function _snapshotGas(string memory _id, uint256 _totalGasUsed, uint256 _nCalls) public {
        vm.snapshotValue(string.concat(_id, ":#Calls"), _nCalls);
        vm.snapshotValue(string.concat(_id, ":TotalGasUsed"), _totalGasUsed);
        vm.snapshotValue(string.concat(_id, ":AverageGasPerCall"), _totalGasUsed / _nCalls);
    }

    function _getBalance(address _user, address _token) public view returns (uint256) {
        uint256 _balance;
        if (_token == CSUC_Constants.NATIVE_TOKEN) {
            _balance = _user.balance;
        } else {
            _balance = IERC20(_token).balanceOf(_user);
        }

        return _balance;
    }

    function _getCSUCBalance(address _user, address _token) public view returns (uint256) {
        uint256 _balance = csuc.balanceOf(_user, _token);

        for (uint256 i = 0; i < 5; ++i) {
            address[] memory _owners = new address[](i + 1);
            uint256[] memory _tokens = new uint256[](i + 1);

            for (uint256 j = 0; j < _owners.length; ++j) {
                _owners[j] = _user;
                _tokens[j] = uint256(uint160(_token));
            }

            for (uint256 j = 0; j < _owners.length; ++j) {
                assertEq(
                    IERC1155(address(csuc)).balanceOfBatch(_owners, _tokens)[j],
                    _balance,
                    "Balance mismatch in CSUC: balanceOfBatch != balanceOf!"
                );
            }
        }

        return _balance;
    }

    // ERC20 Roles:
    address m20_deployer = address(0xacab);

    uint256 constant N_ERC20_TOKENS = 30;

    // Curvy Roles:

    address owner;
    uint256 ownerPk;

    address operator;
    uint256 operatorPk;

    address feeCollector;
    uint256 feeCollectorPk;

    // basic setup

    address user_EOA_0 = address(0x1000);
    address user_EOA_1 = address(0x1001);

    address CSA_0;
    uint256 CSA_0_pk;

    address CSA_1;
    uint256 CSA_1_pk;

    // multi setup
    uint256 public constant N_USER = 50;
    address[] users;

    uint256 public constant N_CSA = 20_000;
    address[] CSA;
    uint256[] CSA_pk;

    uint256 CSA_unusedCount;
    address[] usedCSA;
    address[] usedToken;

    mapping(address => mapping(address => uint256)) m20WithdrawAmounts;
    mapping(address => mapping(address => uint256)) m20BalancesBeforeWithdraw;
    CSUC_Types.Action[] actions;
    CSUC_Types.ActionHandlingInfoUpdate[] actionHandlingInfoUpdate;

    CSUC csuc;
    MockERC20[] m20;
}
