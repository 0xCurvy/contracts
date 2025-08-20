// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {CSUC_BoilerPlate, Strings, IERC20} from "../_BoilerPlate.t.sol";

import {CSUC, CSUC_Types, CSUC_Constants} from "../../../src/csuc/CSUC.sol";

contract CSUC_Reference is CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();
    }

    function test_Native_Transfer() public {
        uint256 _totalGasUsed = 0;

        address _from = users[0];
        address _to = CSA_0;
        // address _token = CSUC_Constants.NATIVE_TOKEN;
        uint256 _amount = _from.balance / 2;

        vm.startBroadcast(_from);

        _totalGasUsed = gasleft();
        (bool _success,) = _to.call{value: _amount}("");
        require(_success, "Native transfer failed!");
        _totalGasUsed -= gasleft();

        vm.stopBroadcast();

        uint256 _n = 1;
        string memory _snapId = string.concat("test_Native_Transfer:#Actions=", Strings.toString(_n));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _n);
    }

    function test_ERC20_Transfer() public {
        uint256 _totalGasUsed = 0;

        address _from = users[0];
        address _to = CSA_0;
        address _token = address(m20[0]);
        uint256 _amount = IERC20(_token).balanceOf(_from) / 2;

        vm.startBroadcast(_from);

        _totalGasUsed = gasleft();
        IERC20(_token).transfer(_to, _amount);
        _totalGasUsed -= gasleft();

        vm.stopBroadcast();

        uint256 _n = 1;
        string memory _snapId = string.concat("test_ERC20_Transfer:#Actions=", Strings.toString(_n));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _n);
    }

    function test_ERC20_Approve() public {
        uint256 _totalGasUsed = 0;

        address _from = users[0];
        address _spender = users[1];
        address _token = address(m20[0]);
        uint256 _amount = IERC20(_token).balanceOf(_from) / 2;

        vm.startBroadcast(_from);

        _totalGasUsed = gasleft();
        IERC20(_token).approve(_spender, _amount);
        _totalGasUsed -= gasleft();

        vm.stopBroadcast();

        uint256 _n = 1;
        string memory _snapId = string.concat("test_ERC20_Approve:#Actions=", Strings.toString(_n));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _n);
    }

    function test_ERC20_TransferFrom() public {
        uint256 _totalGasUsed = 0;

        address _from = users[0];
        address _spender = users[1];
        address _to = CSA_0;
        address _token = address(m20[0]);
        uint256 _amount = IERC20(_token).balanceOf(_from) / 2;

        vm.startBroadcast(_from);
        IERC20(_token).approve(_spender, _amount);
        vm.stopBroadcast();

        vm.startBroadcast(_spender);

        _totalGasUsed = gasleft();
        IERC20(_token).transferFrom(_from, _to, _amount);
        _totalGasUsed -= gasleft();

        vm.stopBroadcast();

        uint256 _n = 1;
        string memory _snapId = string.concat("test_ERC20_TransferFrom:#Actions=", Strings.toString(_n));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _n);
    }

    function test_ZK_VerifierLimits() public {
        address _operator = address(0xadefedaefdaedfeadedae13);
        vm.deal(_operator, 1 ether);

        vm.startBroadcast(_operator);

        ZK_Verifier zkVerifier = new ZK_Verifier();

        uint256[300] memory _dummyData;
        uint256 _totalGasUsed = gasleft();
        zkVerifier.dummyVerify(_dummyData);
        _totalGasUsed -= gasleft();

        vm.stopBroadcast();

        uint256 _n = 1;
        string memory _snapId = string.concat("test_ZK_VerifierLimits:#Actions=", Strings.toString(_n));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _n);
    }
}

contract ZK_Verifier {
    uint256 noteRoot;
    uint256 nullifierRoot;

    function dummyVerify(uint256[300] calldata _data) public {
        noteRoot = _data[0];
        nullifierRoot = _data[1];
    }
}
