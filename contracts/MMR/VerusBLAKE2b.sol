// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;
import "./BLAKE2b/BLAKE2b.sol";
contract VerusBLAKE2b {

    BLAKE2b blake2b;
    bytes verusKey = "VerusDefaultHash";

    constructor() {
        blake2b = new BLAKE2b();
    }
    function createHash(bytes memory toHash,bytes memory personalisation,bool flipped) public view returns(bytes32){
        //uint64[8] memory blakeResult;
        bytes memory testInput = abi.encodePacked(toHash);
        //bytes memory key;
        //bytes memory salt;
        bytes32 bytes32hash = blake2b.blake2b_256(testInput,personalisation);
        //blakeResult = blake2b.blake2b(testInput,key,salt,personalisation,32);
        //bytes memory hashInProgress = abi.encodePacked(blakeResult[0],blakeResult[1],blakeResult[2],blakeResult[3],
        //        blakeResult[4],blakeResult[5],blakeResult[6],blakeResult[7]);

        //we flip the bytes array to match up with Verus Hash    
        //bytes32 bytes32hash = bytesToBytes32(hashInProgress);   
        if(flipped == true) bytes32hash = reverseBytes(bytes32hash);
        return bytes32hash;
    }

    function createHash(bytes memory toHash,bytes memory personalisation) public view returns(bytes32){
        return createHash(toHash,personalisation,false);
    }
    
    function createHash(bytes memory toHash,bool flipped) public view returns(bytes32){
        return createHash(toHash,verusKey,flipped);
    }


    function createHash(bytes memory toHash) public view returns(bytes32){
        return createHash(toHash,verusKey,false);
    }

    function reverseBytes(bytes32 _bytes32) public pure returns (bytes32) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[(31-i)];
        }
        return bytesToBytes32(bytesArray);
    }
/*
    function create64Hash(bytes memory testString,bytes memory key) public returns(bytes memory){
        uint64[8] memory blakeResult;
        bytes memory testInput = abi.encodePacked(testString);
        
        blakeResult = blake2b.blake2b(testInput,key,64);
        bytes memory hashInProgress = abi.encodePacked(blakeResult[0],blakeResult[1],blakeResult[2],blakeResult[3],
                blakeResult[4],blakeResult[5],blakeResult[6],blakeResult[7]);
        return hashInProgress;
    }*/

    function bytesToBytes32(bytes memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    
    }
}