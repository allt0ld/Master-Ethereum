// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    address payable[] public players; 
    address payable public manager;

    constructor() {
        manager = payable (msg.sender); 
        players.push(manager); //automatically include manager in lottery without payment
    }

    receive() external payable {
        require(msg.value == 0.1 ether, "Entry fee is 0.1 ETH.");
        require(msg.sender != manager); //manager is not allowed to participate
        players.push(payable (msg.sender));
    }

    function getBalance() public view returns (uint) {
        require(msg.sender == manager, "Only Manager can check balance.");
        return address(this).balance;
    }

    function random() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty + block.timestamp + players.length)));
    }

    function pickWinner() public {
        //require(msg.sender == manager, "Only manager can call this function.");
        require(players.length >= 10, "Need at least 10 players before picking a winner.");
        
        uint r = random();
        address payable winner;

        uint index = r % players.length;
        winner = players[index];

        uint managerFee = (getBalance() * 10) / 100; //manager gets 10% of winnings
        uint winnerPrize = (getBalance() * 90) /100; //winner gets 90% of winnings

        manager.transfer(managerFee); 
        winner.transfer(winnerPrize); 
        
        players = new address payable[](0); //reset the lottery
    }
}