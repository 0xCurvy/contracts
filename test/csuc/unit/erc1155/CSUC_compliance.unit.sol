// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {CSUC_BoilerPlate, Strings} from "../../_BoilerPlate.t.sol";

import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {CSUC, CSUC_Types, CSUC_Constants} from "../../../../src/csuc/CSUC.sol";

contract CSUC_ERC1155_Compliance_UnitTest is CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();
    }

    function test_balanceOfAfterNativeWrap() public {
        address _from = user_EOA_0;
        address _to = CSA_0;
        address _token = CSUC_Constants.NATIVE_TOKEN;
        uint256 _amount = _from.balance / 2;

        _wrap(_from, _to, _token, _amount);

        uint256 _tokenAsUint256 = uint256(uint160(_token));
        uint256 _balance = IERC1155(address(csuc)).balanceOf(_to, _tokenAsUint256);

        assertEq(_balance, _amount, "Balance mismatch after wrap!");
    }

    function test_balanceOfAfterERC20Wrap() public {
        address _from = user_EOA_0;
        address _to = CSA_0;
        address _token = address(m20[0]);
        uint256 _amount = IERC20(_token).balanceOf(_from) / 2;

        _wrap(_from, _to, _token, _amount);

        uint256 _tokenAsUint256 = uint256(uint160(_token));
        uint256 _balance = IERC1155(address(csuc)).balanceOf(_to, _tokenAsUint256);

        assertEq(_balance, _amount, "Balance mismatch after wrap!");
    }

    function test_balanceOfBatch() public {
        address[] memory _csa = new address[](m20.length);
        uint256[] memory _amounts = new uint256[](m20.length);

        for (uint256 i = 0; i < m20.length; ++i) {
            address _from = users[i % users.length];
            (address _to,) = getUnusedCSA();
            _csa[i] = _to;
            address _token = address(m20[i]);
            _amounts[i] = IERC20(_token).balanceOf(_from) / 2 + i;

            _wrap(_from, _to, _token, _amounts[i]);
        }

        uint256[] memory _tokenAsUint256 = new uint256[](m20.length);

        for (uint256 i = 0; i < m20.length; ++i) {
            _tokenAsUint256[i] = uint256(uint160(address(m20[i])));
        }

        for (uint256 i = 0; i < m20.length; ++i) {
            address[] memory _owner = new address[](1);
            uint256[] memory _tokens = new uint256[](1);
            _owner[0] = _csa[i];
            _tokens[0] = _tokenAsUint256[i];

            uint256[] memory _balance = IERC1155(address(csuc)).balanceOfBatch(_owner, _tokens);
            assertEq(_balance[0], _amounts[i], "Balance mismatch for token at index ");
        }
    }

    function test_setApproval() public {
        address[] memory _csa = new address[](m20.length);
        uint256[] memory _amounts = new uint256[](m20.length);

        for (uint256 i = 0; i < m20.length; ++i) {
            address _from = users[i % users.length];
            (address _to,) = getUnusedCSA();
            _csa[i] = _to;
            address _token = address(m20[i]);
            _amounts[i] = IERC20(_token).balanceOf(_from) / 2 + i;

            _wrap(_from, _to, _token, _amounts[i]);

            address _randomAddress = vm.randomAddress();
            vm.startBroadcast(_csa[i]);
            IERC1155(address(csuc)).setApprovalForAll(_randomAddress, true);
            require(IERC1155(address(csuc)).isApprovedForAll(_csa[i], _randomAddress), "Approval failed!");
            vm.stopBroadcast();

            vm.startBroadcast(_csa[i]);
            IERC1155(address(csuc)).setApprovalForAll(_randomAddress, false);
            require(
                IERC1155(address(csuc)).isApprovedForAll(_csa[i], _randomAddress) == false, "Approval revoke failed!"
            );
            vm.stopBroadcast();
        }
    }

    function test_safeTransferFrom() public {
        address[] memory _csa = new address[](m20.length);
        uint256[] memory _amounts = new uint256[](m20.length);

        for (uint256 i = 0; i < m20.length; ++i) {
            address _from = users[i % users.length];
            (address _to,) = getUnusedCSA();
            _csa[i] = _to;
            address _token = address(m20[i]);
            _amounts[i] = IERC20(_token).balanceOf(_from) / 2 + i;

            _wrap(_from, _to, _token, _amounts[i]);

            vm.startBroadcast(_csa[i]);
            IERC1155(address(csuc)).setApprovalForAll(_csa[i], true);
            IERC1155(address(csuc)).safeTransferFrom(_csa[i], users[i], uint256(uint160(_token)), _amounts[i] / 3, "");
            vm.stopBroadcast();

            address _randomAddress = vm.randomAddress();
            vm.startBroadcast(_randomAddress);
            vm.expectRevert(bytes("CSUC: caller is not approved!"));
            IERC1155(address(csuc)).safeTransferFrom(_csa[i], users[i], uint256(uint160(_token)), _amounts[i] / 3, "");
            vm.stopBroadcast();
        }

        uint256[] memory _tokenAsUint256 = new uint256[](m20.length);

        for (uint256 i = 0; i < m20.length; ++i) {
            _tokenAsUint256[i] = uint256(uint160(address(m20[i])));
        }

        for (uint256 i = 0; i < m20.length; ++i) {
            address[] memory _owner = new address[](1);
            uint256[] memory _tokens = new uint256[](1);
            _owner[0] = users[i];
            _tokens[0] = _tokenAsUint256[i];

            uint256[] memory _balance = IERC1155(address(csuc)).balanceOfBatch(_owner, _tokens);
            assertEq(_balance[0], _amounts[i] / 3, "Balance mismatch for token!");
        }
    }

    function test_safeBatchTransferFrom() public {
        address[] memory _csa = new address[](m20.length);
        uint256[] memory _amounts = new uint256[](m20.length);

        for (uint256 i = 0; i < m20.length; ++i) {
            address _from = users[i % users.length];
            (address _to,) = getUnusedCSA();
            _csa[i] = _to;
            address _token = address(m20[i]);
            _amounts[i] = IERC20(_token).balanceOf(_from) / 2 + i;

            _wrap(_from, _to, _token, _amounts[i]);

            vm.startBroadcast(_csa[i]);
            IERC1155(address(csuc)).setApprovalForAll(_csa[i], true);
            uint256[] memory _tokensUint256 = new uint256[](1);
            _tokensUint256[0] = uint256(uint160(_token));
            uint256[] memory _amountsUint256 = new uint256[](1);
            _amountsUint256[0] = _amounts[i] / 3;
            IERC1155(address(csuc)).safeBatchTransferFrom(_csa[i], users[i], _tokensUint256, _amountsUint256, "");
            vm.stopBroadcast();

            address _randomAddress = vm.randomAddress();
            vm.startBroadcast(_randomAddress);
            vm.expectRevert(bytes("CSUC: caller is not approved!"));
            IERC1155(address(csuc)).safeBatchTransferFrom(_csa[i], users[i], _tokensUint256, _amountsUint256, "");
            vm.stopBroadcast();
        }

        uint256[] memory _tokenAsUint256 = new uint256[](m20.length);

        for (uint256 i = 0; i < m20.length; ++i) {
            _tokenAsUint256[i] = uint256(uint160(address(m20[i])));
        }

        for (uint256 i = 0; i < m20.length; ++i) {
            address[] memory _owner = new address[](1);
            uint256[] memory _tokens = new uint256[](1);
            _owner[0] = users[i];
            _tokens[0] = _tokenAsUint256[i];

            uint256[] memory _balance = IERC1155(address(csuc)).balanceOfBatch(_owner, _tokens);
            assertEq(_balance[0], _amounts[i] / 3, "Balance mismatch for token!");
        }
    }
}
