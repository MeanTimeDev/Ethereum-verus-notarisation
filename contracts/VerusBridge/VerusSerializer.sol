// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 < 0.7.0;
pragma experimental ABIEncoderV2;   
import "./VerusObjects.sol";

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
    function serializeUint8(uint8 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }
    
    function serializeUint16(uint16 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }
    
    function serializeUint32(uint32 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }

    function serializeInt64(int64 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }

    function serializeUint64(uint64 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }

    function serializeUint160(uint160 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }

    function serializeUint256(uint256 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }

    function serializeCTransferDestination(VerusObjects.CTransferDestination memory ctd) public pure returns(bytes memory){
         return abi.encodePacked(serializeUint8(uint8(ctd.transferType)),serializeUint160(ctd.destination));
    }
     
    function serializeCCurrencyValueMap(VerusObjects.CCurrencyValueMap memory _ccvm) public pure returns(bytes memory){
         return abi.encodePacked(serializeUint160(_ccvm.currency),serializeUint64(_ccvm.amount));
    }
    
    function serializeCCurrencyValueMaps(VerusObjects.CCurrencyValueMap[] memory _ccvms) public pure returns(bytes memory){
        bytes memory inProgress;
        inProgress = serializeUint256(_ccvms.length);
        for(uint i=0; i < _ccvms.length; i++){
            inProgress = abi.encodePacked(inProgress,serializeCCurrencyValueMap(_ccvms[i]));
        }
        return inProgress;
    }
    
    function serializeCTransfer(VerusObjects.CTransfer memory ct) public pure returns(bytes memory){
        return abi.encodePacked(serializeUint32(ct.flags),
            serializeUint160(ct.feeCurrencyID),
            serializeUint64(ct.nFees),
            serializeCTransferDestination(ct.destination),
            serializeUint64(ct.amount),
            serializeUint160(ct.destCurrencyID),
            serializeUint160(ct.secondReserveID));
    }
    
    function serializeCTransfers(VerusObjects.CTransfer[] memory _bts) public pure returns(bytes memory){
        bytes memory inProgress;
        
        inProgress = serializeUint256(_bts.length);
        for(uint i=0; i < _bts.length; i++){
            inProgress = abi.encodePacked(inProgress,serializeCTransfer(_bts[i]));
        }
        return inProgress;
    }
    
    function serializeCTransferSet(VerusObjects.CTransferSet memory cts) public pure returns(bytes memory){
        return abi.encodePacked(
            serializeUint16(cts.version),
            serializeUint16(cts.flags),
            serializeUint160(cts.sourceSystemID),
            serializeUint32(cts.sourceHeightStart),
            serializeUint32(cts.sourceHeightEnd),
            serializeUint160(cts.destCurrencyId),
            serializeCCurrencyValueMaps(cts.totalAmounts),
            serializeCCurrencyValueMaps(cts.totalFees),
            serializeUint32(cts.numInputs),
            serializeUint256(cts.hashReserveTransfer),
            serializeUint32(cts.firstInput));
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