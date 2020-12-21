// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 < 0.7.0;
pragma experimental ABIEncoderV2;   

contract VerusSerializer {

    function serializeAddress(address anyAddress) public pure returns(bytes memory){
        //naturally littleEndian
        return flipArray(abi.encodePacked(anyAddress));
    }
    
    function serializeString(string memory anyString) public pure returns(bytes memory){
        //naturally BigEndian
        return abi.encodePacked(anyString);
    }
    
    function serializeUint256(uint256 anyUint256) public pure returns(bytes memory){
        return abi.encodePacked(anyUint256);
    }
    
    function serializeUInt32(uint32 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }
    
    function serializeUInt64(uint64 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }
    
    function flipArray(bytes memory incoming) public pure returns(bytes memory){
        uint256 len;
        len = incoming.length;
        bytes memory output = new bytes(len);
        uint256 pos = 0;
        while(pos < len){
            output[pos] = incoming[len - pos - 1];
            pos++;
        }
        return output;
    }
}