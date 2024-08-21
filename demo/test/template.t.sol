// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/interface.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

// Interface

contract ProtocolTest is Test {
    // Environment Configuration
    uint256 constant forkBlock = 19196685;
    address constant fundToken = address(0);

    // Variable

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
        vm.createSelectFork("", forkBlock);
        vm.deal(address(this), 0);
    }

    function testExploit() public BalanceLog {}
}
