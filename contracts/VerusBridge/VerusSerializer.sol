// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 < 0.9.0;
pragma experimental ABIEncoderV2;   
import "./VerusObjects.sol";

contract VerusSerializer {

    //hashing functions

    function writeVarInt(uint256 incoming) public pure returns(bytes memory) {
        bytes1 inProgress;
        bytes memory output;
        uint len = 0;
        while(true){
            inProgress = bytes1(uint8(incoming & 0x7f) | (len!=0 ? 0x80:0x00));
            output = abi.encodePacked(output,inProgress);
            if(incoming <= 0x7f) break;
            incoming = (incoming >> 7) -1;
            len++;
        }
        return flipArray(output);
    }
    
    function writeCompactSize(uint newNumber) public pure returns(bytes memory) {
        bytes memory output;
        if (newNumber < uint8(253))
        {   
            output = abi.encodePacked(uint8(newNumber));
        }
        else if (newNumber <= 0xFFFF)
        {   
            output = abi.encodePacked(uint8(253),uint16(newNumber));
            //output[0] = uint8(253);
            //let secondBuffer = Buffer.alloc(2);
            //secondBuffer.writeUInt16LE(newNumber);
            //outBuffer = Buffer.concat([outBuffer,secondBuffer]);
        }
        else if (newNumber <= 0xFFFFFFFF)
        {   
            //outBuffer.writeUInt8(254);
            output = abi.encodePacked(uint8(254),uint32(newNumber));
            //let secondBuffer = Buffer.alloc(4);
            //secondBuffer.writeUInt32LE(newNumber);        
            //outBuffer = Buffer.concat([outBuffer,secondBuffer]);
        }
        else
        {
            output = abi.encodePacked(uint8(255),uint64(newNumber));
            //outBuffer.writeUInt8(255);
            //let secondBuffer = Buffer.alloc(8);
            //secondBuffer.writeUInt32LE(newNumber);        
            //outBuffer = Buffer.concat([outBuffer,secondBuffer]);
        }
        return output;
    }

    
    function verusHashPrefix(string memory prefix,address systemID,int64 blockHeight,address signingID, bytes memory messageToHash) public pure returns(bytes memory){
        return abi.encodePacked(serializeString(prefix),serializeAddress(systemID),serializeInt64(blockHeight),serializeAddress(signingID),messageToHash);    
    }
    
    //serialize functions

    function serializeBool(bool anyBool) public pure returns(bytes memory){
        return abi.encodePacked(anyBool);
    }
    
    function serializeString(string memory anyString) public pure returns(bytes memory){
        //naturally BigEndian
        return abi.encodePacked(anyString);
    }

    function serializeBytes20(bytes20 anyBytes20) public pure returns(bytes memory){
        //naturally BigEndian
        return abi.encodePacked(anyBytes20);
    }
    function serializeBytes32(bytes32 anyBytes32) public pure returns(bytes memory){
        //naturally BigEndian
        return abi.encodePacked(anyBytes32);
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

    function serializeInt16(int16 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }
    
    function serializeInt32(int32 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }
    
    function serializeInt64(int64 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }

    function serializeInt32Array(int32[] memory numbers) public pure returns(bytes memory){
        bytes memory be;
        be = serializeUint256(numbers.length);
        for(uint i = 0;i < numbers.length; i++){
            be = abi.encodePacked(be,numbers[i]);
        }
        return be;
    }

    function serializeInt64Array(int64[] memory numbers) public pure returns(bytes memory){
        bytes memory be;
        be = serializeUint256(numbers.length);
        for(uint i = 0;i < numbers.length; i++){
            be = abi.encodePacked(be,flipArray(abi.encodePacked(numbers[i])));
        }
        return be;
    }

    function serializeUint64(uint64 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }

    function serializeAddress(address number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return be;
        
    }
    
    function serializeUint160Array(uint160[] memory numbers) public pure returns(bytes memory){
        bytes memory be;
        be = serializeUint256(numbers.length);
        for(uint i = 0;i < numbers.length; i++){
            be = abi.encodePacked(be,flipArray(abi.encodePacked(numbers[i])));
        }
        return(be);
    }


    function serializeUint256(uint256 number) public pure returns(bytes memory){
        bytes memory be = abi.encodePacked(number);
        return(flipArray(be));
    }
/*
    function serializeCTransferDestination(VerusObjects.CTransferDestination memory ctd) public pure returns(bytes memory){
         return abi.encodePacked(serializeUint8(uint8(ctd.CTDType)),
            serializeAddress(ctd.destination),
            serializeAddress(ctd.gatewayID),
            serializeAddress(ctd.gatewayCode),
            serializeInt64(ctd.fees));
    }
*/
    function serializeCTransferDestination(VerusObjects.CTransferDestination memory ctd) public pure returns(bytes memory){
        return abi.encodePacked(serializeUint8(ctd.destinationtype),writeCompactSize(20),serializeAddress(ctd.destinationaddress));
    }   

    function serializeCCurrencyValueMap(VerusObjects.CCurrencyValueMap memory _ccvm) public pure returns(bytes memory){
         return abi.encodePacked(serializeAddress(_ccvm.currency),serializeUint64(_ccvm.amount));
    }
    
    function serializeCCurrencyValueMaps(VerusObjects.CCurrencyValueMap[] memory _ccvms) public pure returns(bytes memory){
        bytes memory inProgress;
        inProgress = writeVarInt(_ccvms.length);
        for(uint i=0; i < _ccvms.length; i++){
            inProgress = abi.encodePacked(inProgress,serializeCCurrencyValueMap(_ccvms[i]));
        }
        return inProgress;
    }

    function serializeCReserveTransfer(VerusObjects.CReserveTransfer memory ct) public pure returns(bytes memory){
        
        bytes memory output =  abi.encodePacked(
            writeVarInt(ct.version),
            serializeCCurrencyValueMap(ct.currencyvalue),
            writeVarInt(ct.flags),
            serializeAddress(ct.feecurrencyid),
            writeVarInt(ct.fees),
            serializeCTransferDestination(ct.destination),
            serializeAddress(ct.destCurrencyID)
           );
        if(ct.destSystemID != 0x0000000000000000000000000000000000000000) output = abi.encodePacked(output,serializeAddress(ct.destSystemID));
        return output;
    }
    
    function serializeCReserveTransfers(VerusObjects.CReserveTransfer[] memory _bts) public pure returns(bytes memory){
        bytes memory inProgress;
        
        inProgress =writeCompactSize(_bts.length);
        for(uint i=0; i < _bts.length; i++){
            inProgress = abi.encodePacked(inProgress,serializeCReserveTransfer(_bts[i]));
        }
        return inProgress;
    }

    function serializeCUTXORef(VerusObjects.CUTXORef memory _cutxo) public pure returns(bytes memory){
        return abi.encodePacked(
            serializeUint256(_cutxo.hash),
            serializeUint32(_cutxo.n)
        );
    }

    function serializeCProofRoot(VerusObjects.CProofRoot memory _cpr) public pure returns(bytes memory){
        return abi.encodePacked(
            serializeInt16(_cpr.version),
            serializeInt16(_cpr.CPRtype),
            serializeAddress(_cpr.systemID),
            serializeUint32(_cpr.rootHeight),
            serializeUint256(_cpr.stateRoot),
            serializeUint256(_cpr.blockHash),
            serializeUint256(_cpr.compactPower)
            );
    }

    function serializeProofRoots(VerusObjects.ProofRoots memory _prs) public pure returns(bytes memory){
        return abi.encodePacked(
            serializeAddress(_prs.currencyId),
            serializeCProofRoot(_prs.proofRoot)
        );  
    }

    function serializeProofRootsArray(VerusObjects.ProofRoots[] memory _prsa) public pure returns(bytes memory){
        bytes memory inProgress;
        
        inProgress = serializeUint256(_prsa.length);
        for(uint i=0; i < _prsa.length; i++){
            inProgress = abi.encodePacked(inProgress,serializeProofRoots(_prsa[i]));
        }
        return inProgress;
    }

    function serializeCCoinbaseCurrencyState(VerusObjects.CCoinbaseCurrencyState memory _cccs) public pure returns(bytes memory){
        bytes memory part1 = abi.encodePacked(
            serializeUint16(_cccs.version),
            serializeUint16(_cccs.flags),
            serializeAddress(_cccs.currencyID),
            serializeUint160Array(_cccs.currencies),
            serializeInt32Array(_cccs.weights),
            serializeInt64Array(_cccs.reserves)
        );
        bytes memory part2 = abi.encodePacked(
            serializeInt64(_cccs.primaryCurrencyOut),
            serializeInt64(_cccs.preconvertedOut),
            serializeInt64(_cccs.primaryCurrencyFees),
            serializeInt64(_cccs.primaryCurrencyConversionFees),
            serializeInt64Array(_cccs.reserveIn),
            serializeInt64Array(_cccs.primaryCurrencyIn),
            serializeInt64Array(_cccs.reserveOut),
            serializeInt64Array(_cccs.conversionPrice),
            serializeInt64Array(_cccs.viaConversionPrice),
            serializeInt64Array(_cccs.fees),
            serializeInt64Array(_cccs.conversionFees),
            serializeInt32Array(_cccs.priorWeights)
        );
        
        return abi.encodePacked(part1,part2);
    }

    function serializeCurrencyStates(VerusObjects.CurrencyStates memory _cs) public pure returns(bytes memory){
        return abi.encodePacked(
            serializeAddress(_cs.currencyId),
            serializeCCoinbaseCurrencyState(_cs.currencyState)
        );
    }

    function serializeCurrencyStatesArray(VerusObjects.CurrencyStates[] memory _csa) public pure returns(bytes memory){
        bytes memory inProgress;
        inProgress = serializeUint256(_csa.length);
        for(uint i=0; i < _csa.length; i++){
            inProgress = abi.encodePacked(inProgress,serializeCurrencyStates(_csa[i]));
        }
        return inProgress;
    }

    function serializeCPBaaSNotarization(VerusObjects.CPBaaSNotarization memory _not) public pure returns(bytes memory){
        return abi.encodePacked(
            serializeUint32(_not.version),
            serializeCTransferDestination(_not.proposer),
            serializeUint32(_not.notarizationHeight),
            serializeCCoinbaseCurrencyState(_not.currencyState),
            serializeUint256(_not.prevnotarizationtxid),
            serializeInt64(_not.prevnotarizationout),
            serializeUint256(_not.hashprevnotarizationobject),
            serializeUint64(_not.prevheight),
            serializeCurrencyStatesArray(_not.currencyStates),
            serializeProofRootsArray(_not.proofRoots),
            serializeNodes(_not.nodes)
        );
    }
    
    function serializeNodes(VerusObjects.CNodeData[] memory _cnds) public pure returns(bytes memory){
        bytes memory inProgress;
        inProgress = serializeUint256(_cnds.length);
        for(uint i=0; i < _cnds.length; i++){
            inProgress = abi.encodePacked(inProgress,serializeCNodeData(_cnds[i]));
        }
        return inProgress;
    }

    function serializeCNodeData(VerusObjects.CNodeData memory _cnd) public pure returns(bytes memory){
        return abi.encodePacked(
            _cnd.networkAddress,
            serializeAddress(_cnd.nodeIdentity)
        );
    }

    function serializeCCrossChainExport(VerusObjects.CCrossChainExport memory _ccce) public pure returns(bytes memory){
        bytes memory part1 = abi.encodePacked(
            serializeUint16(_ccce.version),
            serializeUint16(_ccce.flags),
            serializeAddress(_ccce.sourcesystemid),
            writeVarInt(_ccce.sourceheightstart),
            writeVarInt(_ccce.sourceheightend),
            serializeAddress(_ccce.destinationsystemid),
            serializeAddress(_ccce.destinationcurrencyid));
        bytes memory part2 = abi.encodePacked(serializeUint32(_ccce.numinputs),
            serializeCCurrencyValueMaps(_ccce.totalamounts),
            serializeCCurrencyValueMaps(_ccce.totalfees),
            serializeBytes32(_ccce.hashtransfers),
            serializeCCurrencyValueMaps(_ccce.totalburned),
            serializeCTransferDestination(_ccce.rewardaddress),
            serializeInt32(_ccce.firstinput),bytes1(0x00));
        return abi.encodePacked(part1,part2);
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