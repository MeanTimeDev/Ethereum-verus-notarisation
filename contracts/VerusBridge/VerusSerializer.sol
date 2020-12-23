// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 < 0.7.0;
pragma experimental ABIEncoderV2;   

contract VerusSerializer {

    //serialize functions

    function serializeAddress(address anyAddress) public pure returns(bytes memory){
        //naturally littleEndian
        return flipArray(abi.encodePacked(anyAddress));
    }
    
    function serializeString(string memory anyString) public pure returns(bytes memory){
        //naturally BigEndian
        return abi.encodePacked(anyString);
    }

    function serializeBytes20(bytes20 anyBytes20) public pure returns(bytes memory){
        //naturally BigEndian
        return abi.encodePacked(anyBytes20);
    }
    
    function serializeUint256(uint256 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }

    function serializeUint160(uint160 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }

    function serializeUInt32(uint32 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }
    
    function serializeUInt64(uint64 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }

    //deserialize functions    

    function deSerializeAddress(bytes memory encoded) public pure returns(address){
        //naturally littleEndian
        return abi.decodePacked("address",flipArray(encoded));
    }
    
    function deSerializeString(bytes memory encoded) public pure returns(string){
        //naturally BigEndian
        return abi.decodePacked("string",encoded);
    }

    function deSerializeBytes20(bytes memory encoded) public pure returns(bytes20){
        //naturally BigEndian
        return abi.decodePacked("Bytes20",encoded);
    }
    
    function deSerializeUint256(bytes memory encoded) public pure returns(uint256){
        return abi.decodePacked("uint256",flipArray(encoded));    
    }

    function deSerializeUint160(bytes memory encoded) public pure returns(uint160){
        return abi.decodePacked("uint160",flipArray(encoded));    
    }

    function deSerializeUInt32(bytes memory encoded) public pure returns(uint32){
        return abi.decodePacked("uint32",flipArray(encoded));    
    }
    
    function deSerializeUInt64(bytes memory encoded) public pure returns(uint64){
        return abi.decodePacked("uint32",flipArray(encoded));    
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