// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.4.20;
pragma experimental ABIEncoderV2;

/**
* Contract to store the list of ERC20 tokens and their corresponding address on Verus
**/

contract VerusMapping {

    mapping(address => uint160) ethToVerus;
    mapping(address => address) verusToEth;

    function addMap(address ethAddress,address vAddress) public {
        ethToVerus[ethAddress] = vAddress;
        verusToEth[vAddress] = ethAddress;
    }

    function getMapping(address vAddress) public view returns(address){
        return verusToEth[vAddress];
    }

    function getMapping(address eAddress)public view returns(uint160){
        return ethToVerus[eAddress];
    }
}