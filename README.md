# Multi-Party-Lottery

## How to play game
### Stage 1
   - Only N users can join game
   - Commit number by using number and salt (required 0.001 ETH)
   - Go to stage 2 after T1 sec
### Stage 2
   - Player reveal number by using number and salt
   - Users who do not reveal their choices within T2 seconds cannot win this game
   - Go to stage 2 after T2 sec
### Stage 3
   - Determine the winner by using XOR and modulo
   - Winner get reward `0.001 ETH * num_participants * 0.98`
   - Owner get `0.001 ETH * num_participants * 0.02`
   - If no winner, owner get all reward
   - Go to stage 2 after T3 sec
### Stage 4
   - Players who participate in the game can submit transactions to get back the ETH.
  
## Code detail
### Stage 1
- Player number store in `hashAns`
- When first player join `startTime` will count and set deadline
```solidity
    function stage1(bytes32 hash32) public payable {
        require(playerCount < N, "Sorry, We already have maximum player");
        require(msg.value == 0.001 ether, "value must be 0.001 ETH");
        require(!startGame || (block.timestamp <= startTime + T1), "We're not in stage1");
        
        rewards += msg.value;
        // commit(hash32);
        if (playerCount == 0) {
            startGame = true;
            startTime = block.timestamp;
        }

        playerCount += 1;

        registered[msg.sender] = true;
        hashAns[msg.sender] = hash32;
    }
```

### Stage 2
   - Players reveal their number by checking with number and salt
```solidity
    function stage2(uint ans, string memory salt) public payable {
        require(block.timestamp > startTime + T1 && block.timestamp <= startTime + T1 + T2, "We're not in stage2");
        require(ans >= 0 && ans <= 999, "ans must in range 0 - 999");
        require(hashAns[msg.sender] == getBytes32(ans, salt));

        // revealAnswer(ans, salt);
        // answer[msg.sender] = ans;
        answer[revealNum] = ans;
        playerAddress[revealNum] = msg.sender;
        revealNum += 1;
    }
```
### Stage 3
   - Find winner by XOR and modulo
   - The winner receives 98% and the owner receives 2% of reward
   - If no winner, owner get all reward
```solidity
    function stage3() public payable {
        require(block.timestamp > startTime + T1 + T2 && block.timestamp <= startTime + T1 + T2 + T3, "We're not in stage3");
        require(msg.sender == owner, "You're not owner >:(");
        require(!winnerAnnounced, "Winner has announced");
        
        uint result = answer[0];
        if (revealNum != 0) {
            for (uint i = 1; i < N; i++){
                result ^= answer[1];

            }
            winnerIdx = uint256(keccak256(abi.encodePacked(result))) % N;
            winnerAnnounced = true;

            address payable winnerAddress = payable(playerAddress[winnerIdx]);
            address payable ownerAddress = payable(owner);

            winnerAddress.transfer(rewards * 98 / 100);
            ownerAddress.transfer(rewards * 2 / 100);
        }
        else {
            payable(owner).transfer(rewards);
        }
        resetGame();
```
### Stage 4
   - Players must in contract
   - If all players withdraw, game will reset
```solidity
    function stage4() public payable{
        require(block.timestamp > startTime + T1 + T2 + T3, "Not in stage 4");
        require(registered[msg.sender], "You're not in this contract");

        payable(msg.sender).transfer(0.001 ether);
        registered[msg.sender] = false;

        playerCount -= 1;

        if (playerCount == 0){
            resetGame();
        }
```
