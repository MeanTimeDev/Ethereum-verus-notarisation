// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 < 0.7.0;
pragma experimental ABIEncoderV2;   
import "./VerusObjects.sol";

contract VerusSerializer {

    //serialize functions

    function serializeBool(bool anyBool) public pure returns(bytes memory){
        return abi.encodePacked(anyBool);
    }

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
            be = abi.encodePacked(be,numbers[i]);
        }
        return be;
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
/*
    function serializeCTransferDestination(VerusObjects.CTransferDestination memory ctd) public pure returns(bytes memory){
         return abi.encodePacked(serializeUint8(uint8(ctd.CTDType)),
            serializeUint160(ctd.destination),
            serializeUint160(ctd.gatewayID),
            serializeUint160(ctd.gatewayCode),
            serializeInt64(ctd.fees));
    }
*/
    function serializeCTransferDestination(VerusObjects.CTransferDestination memory ctd) public pure returns(bytes memory){
        return abi.encodePacked(serializeUint32(ctd.destinationtype),serializeUint160(ctd.destinationaddress));
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
    
    function serializeCReserveTransfer(VerusObjects.CReserveTransfer memory ct) public pure returns(bytes memory){
        return abi.encodePacked(
            serializeUint32(ct.version),
            serializeCCurrencyValueMap(ct.currencyvalues),
            serializeUint32(ct.flags),
            serializeUint160(ct.feecurrencyid),
            serializeUint256(ct.fees),
            serializeUint160(ct.destCurrencyID),
            serializeCTransferDestination(ct.destination));
    }
    
    function serializeCReserveTransfers(VerusObjects.CReserveTransfer[] memory _bts) public pure returns(bytes memory){
        bytes memory inProgress;
        
        inProgress = serializeUint256(_bts.length);
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
            serializeUint160(_cpr.systemID),
            serializeUint32(_cpr.rootHeight),
            serializeUint256(_cpr.stateRoot),
            serializeUint256(_cpr.blockHash),
            serializeUint256(_cpr.compactPower)
            );
    }

    function serializeProofRoots(VerusObjects.ProofRoots memory _prs) public pure returns(bytes memory){
        return abi.encodePacked(
            serializeUint160(_prs.currencyId),
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
        return abi.encodePacked(
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
    }

    function serializeCurrencyStates(VerusObjects.CurrencyStates memory _cs) public pure returns(bytes memory){
        return abi.encodePacked(
            serializeUint160(_cs.currencyId),
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
            serializeUint32(_not.flags),
            serializeCTransferDestination(_not.proposer),
            serializeUint160(_not.currencyID),
            serializeUint32(_not.notarizationHeight),
            serializeCCoinbaseCurrencyState(_not.currencyState),
            serializeCUTXORef(_not.prevNotarization),
            serializeUint256(_not.hashPrevNotarization),
            serializeUint32(_not.prevHeight),
            serializeCurrencyStatesArray(_not.currencyStates),
            serializeProofRootsArray(_not.proofRoots)
        );
    }

    function serializeCCrossChainExport(VerusObjects.CCrossChainExport memory _ccce) public pure returns(bytes memory){
        bytes memory part1 = abi.encodePacked(
            serializeUint8(_ccce.version),
            serializeUint32(_ccce.flags),
            serializeUint160(_ccce.sourcesystemid),
            serializeUint32(_ccce.sourceheightstart),
            serializeUint32(_ccce.sourceheightend),
            serializeUint160(_ccce.destinationsystemid),
            serializeUint160(_ccce.destinationcurrencyid));
        bytes memory part2 = abi.encodePacked(serializeInt32(_ccce.numinputs),
            serializeCCurrencyValueMaps(_ccce.totalamounts),
            serializeCCurrencyValueMaps(_ccce.totalfees),
            serializeUint256(_ccce.hashtransfers),
            serializeAddress(_ccce.rewardaddress),
            serializeInt32(_ccce.firstinput));
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