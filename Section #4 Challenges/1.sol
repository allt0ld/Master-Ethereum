//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract CryptosToken{
    string constant public name = "Cryptos";
    uint supply;
    
    
    function setSupply(uint s) public{
        supply = s;
    }
    
    function getSupply() public view returns(uint){
        return supply;
    }
}