//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Deposit{

    address public immutable admin;

    constructor () {
        admin = msg.sender;
    }

    receive() external payable  {}

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function transferBalance(address payable _to) public payable {
        require(msg.sender == admin, "Must be owner to transfer contract balance.");
        _to.transfer(address(this).balance);
    }
    
}