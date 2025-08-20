// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {
    ICurvyAggregator,
    CurvyAggregator,
    CurvyAggregator_Types,
    CurvyAggregator_Constants,
    ICurvyInsertionVerifier,
    ICurvyAggregationVerifier,
    ICurvyWithdrawVerifier
} from "../../src/aggregator/CurvyAggregator.sol";

import {MockERC20} from "./mocks/MockERC20.sol";

contract BoilerPlate is Test {
    function setUp() public {
        basicSetUp();
    }

    function basicSetUp() public {
        // Roles for Curvy Governance:
        (owner, ownerPk) = makeAddrAndKey("owner");
        (operator, operatorPk) = makeAddrAndKey("operator");
        (feeCollector, feeCollectorPk) = makeAddrAndKey("feeCollector");

        // Fund the accounts with ETH
        vm.deal(owner, 10 ether);
        vm.deal(operator, 10 ether);
        vm.deal(feeCollector, 10 ether);
        vm.deal(m20_deployer, 10 ether);
        vm.deal(MOCKED_CSUC, 1_000 ether);

        // Fund the users' EOA accounts with native tokens
        for (uint256 i = 0; i < N_USER; ++i) {
            address user = makeAddr(string(abi.encodePacked("user_", Strings.toString(i))));
            users.push(user);
            vm.deal(user, 10 ether);
        }

        // Deploy mocked ERC20 tokens
        vm.startBroadcast(m20_deployer);
        for (uint256 i = 0; i < N_ERC20_TOKENS; ++i) {
            uint256 _totalSupply = (i + 1) * 1_000 * 10 ** 18;
            m20Tokens.push(IERC20(new MockERC20(_totalSupply)));
            // half of the total supply is sent to the CSUC
            IERC20(m20Tokens[i]).transfer(MOCKED_CSUC, _totalSupply / 2);
            _totalSupply /= 3;
            for (uint256 j = 0; j < N_USER; ++j) {
                IERC20(m20Tokens[i]).transfer(users[j], _totalSupply / (N_USER * 3) + i);
            }
        }

        vm.stopBroadcast();

        vm.startBroadcast(owner);

        address proxy = Upgrades.deployUUPSProxy("CurvyAggregator.sol", abi.encodeCall(CurvyAggregator.initialize, ()));
        curvyAggregator = ICurvyAggregator(proxy);

        CurvyAggregator_Types.ConfigurationUpdate memory _configUpdate;
        _configUpdate.insertionVerifier = address(0x48575A349bDc3D45591123C0279B8380e36FE93a);
        _configUpdate.aggregationVerifier = address(0x956174eF62D5f213986B42E488CFADaa7a56f187);
        _configUpdate.withdrawVerifier = address(0x6af15047028F8E3Aa9cB7d6e6b6Afa6bDd8Ab166);
        _configUpdate.csuc = MOCKED_CSUC;
        curvyAggregator.updateConfig(_configUpdate);

        vm.stopBroadcast();
    }

    function getBalance(uint256 _token, address _account) public view returns (uint256 _balance) {
        return getBalance(address(uint160(_token)), _account);
    }

    function getBalance(address _token, address _account) public view returns (uint256 _balance) {
        if (_token == CurvyAggregator_Constants.NATIVE_TOKEN) {
            return address(_account).balance;
        } else {
            return IERC20(_token).balanceOf(_account);
        }
    }

    function wrapNative(address _from, CurvyAggregator_Types.Note[] memory _notes) public {
        vm.startBroadcast(_from);

        uint256 _totalAmount = 0;
        uint256 _balanceBefore = 0;
        for (uint256 i = 0; i < _notes.length; ++i) {
            assertEq(_notes[i].token, uint256(uint160(CurvyAggregator_Constants.NATIVE_TOKEN)), "Token mismatch!");
            address _token = address(uint160(_notes[i].token));
            _balanceBefore = getBalance(_token, address(curvyAggregator));
            _totalAmount += _notes[i].amount;
        }

        curvyAggregator.wrapNative{value: _totalAmount}(_notes);
        vm.stopBroadcast();

        // Check balances after wrapping
        uint256 _newBalance = getBalance(_notes[0].token, address(curvyAggregator));
        assertEq(_newBalance, _balanceBefore + _totalAmount, "New Balance mismatch!");

        for (uint256 i = 0; i < _notes.length; ++i) {
            bytes32 _noteHash = keccak256(abi.encode(_notes[i]));
            CurvyAggregator_Types.NoteWithMetaData memory _noteWithMetaData = curvyAggregator.getNoteInfo(_noteHash);

            assertEq(_noteWithMetaData.note.amount, _notes[i].amount, "Note amount mismatch!");
        }
    }

    function approveAndWrapERC20(address _from, CurvyAggregator_Types.Note[] memory _notes) public {
        vm.startBroadcast(_from);
        uint256 _totalAmount = 0;
        address _token = address(uint160(_notes[0].token));
        uint256 _balanceBefore = getBalance(_token, address(curvyAggregator));
        for (uint256 i = 0; i < _notes.length; ++i) {
            assertEq(_notes[i].token, uint256(uint160(_token)), "Only one token can be wrapped!");
            _totalAmount += _notes[i].amount;
        }
        // Note: user must give approval to the aggregator before wrapping
        IERC20(_token).approve(address(curvyAggregator), _totalAmount);

        curvyAggregator.wrapERC20(_notes);
        vm.stopBroadcast();

        // Check balances after wrapping
        uint256 _newBalance = getBalance(_token, address(curvyAggregator));
        assertEq(_newBalance, _balanceBefore + _totalAmount, "New Balance mismatch!");

        for (uint256 i = 0; i < _notes.length; ++i) {
            bytes32 _noteHash = keccak256(abi.encode(_notes[i]));
            CurvyAggregator_Types.NoteWithMetaData memory _noteWithMetaData = curvyAggregator.getNoteInfo(_noteHash);
            assertEq(_noteWithMetaData.note.amount, _notes[i].amount, "Note amount mismatch!");
        }
    }

    // Mock CSUC address:
    address constant MOCKED_CSUC = address(0x1234);

    // ERC20 Roles:
    address m20_deployer = address(0xacab);

    // Curvy Roles:
    address owner;
    uint256 ownerPk;

    address operator;
    uint256 operatorPk;

    address feeCollector;
    uint256 feeCollectorPk;

    // basic setup
    uint256 public constant N_USER = 50;
    uint256 public constant N_ERC20_TOKENS = 5;
    address[] users;
    IERC20[] m20Tokens;

    ICurvyAggregator public curvyAggregator;
}
