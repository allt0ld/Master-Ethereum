//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Concatenate {
    function concatenate (string memory _s1, string memory _s2) public pure returns (string memory) {
        return string(abi.encodePacked(_s1, _s2));
    }
}