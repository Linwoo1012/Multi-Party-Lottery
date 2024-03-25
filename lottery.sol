// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// import "./CommitReveal.sol";

contract MultiPartyLottery {
    address owner;
    uint public N;
    uint public T1;
    uint public T2;
    uint public T3;
    uint public startTime;
    bool public startGame = false;
    uint public rewards;

    mapping(address => bool) registered;
    // mapping(address => uint) answer;
    uint[] answer;
    mapping(address => bool) isReveal;
    mapping(uint => address) playerAddress;
    mapping (address => bytes32) hashAns;

    uint revealNum = 0;
    bool winnerAnnounced = false;
    uint256 winnerIdx = 0;
    
    constructor(uint n, uint t1, uint t2, uint t3) payable {
        N = n;
        T1 = t1;
        T2 = t2;
        T3 = t3;
        owner = msg.sender;
    }

    function getBytes32(uint ans, string memory salt) public pure returns (bytes32){
        require(ans >= 0 && ans <= 999);
        return keccak256(abi.encodePacked(ans, salt));
    }
    
    uint public playerCount = 0;
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
    }

    function stage4() public payable{
        require(block.timestamp > startTime + T1 + T2 + T3, "Not in stage 4");
        require(registered[msg.sender], "You're not in this contract");

        payable(msg.sender).transfer(0.001 ether);
        registered[msg.sender] = false;

        playerCount -= 1;

        if (playerCount == 0){
            resetGame();
        }
    }

    function resetGame() private {
        for (uint i = 0; i < playerCount; i++){
            address addr = playerAddress[i];
            isReveal[addr] = false;
            hashAns[addr] = 0;
        }
        playerCount = 0;
        revealNum = 0;
        delete answer;
        answer = new uint8[](N);
        startGame = false;
    }

    function gameState() external view returns (uint) {
        if (startGame == false){
            return 0;
        }
        else if (block.timestamp <= startTime + T1){
            return 1;
        }
        else if (block.timestamp <= startTime + T1 + T2){
            return 2;
        }
        else if (block.timestamp <= startTime + T1 + T2 + T3){
            return 3;
        }
        else{
            return 4;
        }
    }


}


