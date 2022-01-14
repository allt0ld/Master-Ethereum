//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract CryptosToken {

    string constant public name = "Cryptos";
    address public owner;
    uint supply;

    constructor (uint _supply) {
        owner = msg.sender;
        supply = _supply;
    }

    function getSupply() external view returns (uint) {
        return supply;
    }

    function setSupply(uint _supply) public {
        supply = _supply;
    }
}