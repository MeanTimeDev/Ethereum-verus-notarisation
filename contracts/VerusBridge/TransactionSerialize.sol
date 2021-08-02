  
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./VerusSerializer.sol";

contract TransactionSerialize{
    
    VerusSerializer vs;
    uint64 transactionsPerCall = 10;
    constructor() public {
        vs = new VerusSerializer();
    }
    
    enum TransferDestinationType{
        DEST_INVALID,DEST_PK,DEST_PKH,DEST_SH,DEST_ID,DEST_FULLID,DEST_QUANTUM,DEST_RAW
    }

    struct CTransferDestination {
        TransferDestinationType transferType;
        address destination;
    }

    //pending transactions array
    struct BridgeTransaction {
        uint32 flags; //type of transfer 0,
        address feeCurrencyID; //fees are paid in this currency
        uint64 nFees; //cross chain network fees
        CTransferDestination destination; //destination address
        uint64 amount;
        address destCurrencyID;
        address secondReserveID;
    }
    
    struct CCurrencyValueMap {
        address currency;
        uint64 amount;
    }
    
    struct BridgeTransactionSet {
        uint16 version;
        uint16 flags;
        address sourceSystemID;
        uint32 sourceHeightStart;
        uint32 sourceHeightEnd;
        address destCurrencyId; //does this need to be here as we have the currency map?
        CCurrencyValueMap[] totalAmounts; 
        CCurrencyValueMap[] totalFees;
        uint32 numInputs; //number of transactions in this list
        uint256 hashReserveTransfer; //hash of the transactions in this block
        uint32 firstInput; 
    }
    
    BridgeTransaction[] bts;
    
    BridgeTransaction[] private pendingExports;
    BridgeTransactionSet private pendingExportSet;
    //the export set holds the summary of a set of exports
    BridgeTransaction[][] private readyExports;
    BridgeTransactionSet[] private readyExportSet;
    mapping (uint => uint[]) private readyExportsByBlock;
    
    function _initializeBridgeTransactionSet() private returns(BridgeTransactionSet memory){
        BridgeTransactionSet memory BTS;
        BTS.version = 1;
        BTS.flags = 1;
        BTS.sourceSystemID = uint160(0x0000000000000000000000000000000000000000);
        BTS.sourceHeightStart = 0; //reinitiate this to be overwritten at point of adding it to the array
        BTS.sourceHeightEnd = 0;
        BTS.destCurrencyId = uint160(0x0000000000000000000000000000000000000000); //default value till we know what to put in here
        delete BTS.totalAmounts;
        delete BTS.totalFees;
        BTS.numInputs = 0;
        BTS.hashReserveTransfer = 0x00;
        BTS.firstInput = 0;
        return BTS;
    }
    
        function _createExports(BridgeTransaction memory newTransaction) private {
        pendingExports.push(newTransaction);    
        //update the pendingTransactionSet
        //loop through the total amounts 
        
        //loop through the totalAmounts and append if the 
        bool currencyExists = false;
        for(uint i = 0;i<pendingExportSet.totalAmounts.length;i++){
            if(pendingExportSet.totalAmounts[i].currency == newTransaction.destCurrencyID){
                pendingExportSet.totalAmounts[i].amount += newTransaction.amount;
                currencyExists = true;
            }
        }
        if(!currencyExists){
            pendingExportSet.totalAmounts.push(CCurrencyValueMap(newTransaction.destCurrencyID,newTransaction.amount));
        }
        if(newTransaction.nFees > 0){
            bool feesExists = false;
            for(uint i = 0;i<pendingExportSet.totalFees.length;i++){
                if(pendingExportSet.totalFees[i].currency == newTransaction.destCurrencyID){
                    pendingExportSet.totalFees[i].amount += newTransaction.nFees;
                    feesExists = true;
                }
            }
            if(!feesExists){
                pendingExportSet.totalFees.push(CCurrencyValueMap(newTransaction.destCurrencyID,newTransaction.amount));
            }
        }
        pendingExportSet.numInputs++;
      //  pendingExportSet.hashReserveTransfer = uint256(mmrProof.createHash(serializeBridgeTransactions(pendingExports),verusKey));
        
        //if we are ready to release
        if(pendingExports.length >= transactionsPerCall){
            //add the transactions to the ready export
            readyExports.push(pendingExports);
            //clear the pending array
            delete pendingExports;

            //prepare and push the exportSet
            pendingExportSet.sourceHeightStart = uint32(block.number);
            //add to the transactionSet Array
            readyExportSet.push(pendingExportSet);
            pendingExportSet = _initializeBridgeTransactionSet();
            //add the block to the mapping
            readyExportsByBlock[block.number].push(readyExports.length - 1);
            //emit an event       
            //emit ExportsReady(readyExports.length - 1);     
        }
        
    }
    
    
  /*  function serializeCtransferDestination(CTransferDestination memory ctd) public returns(bytes memory){
         abi.encodePacked(vs.serialize(uint8(ctd.transferType)),vs.serialize(ctd.destination));
     }*/
/*     
    function serializeBridgeTransaction(BridgeTransaction memory bt) public returns(bytes memory){
        return abi.encodePacked(vs.serializeUInt32(bt.flags),
            vs.serialize(bt.feeCurrencyID),
            vs.serialize(bt.nFees),
            serializeCtransferDestination(bt.destination),
            vs.serialize(bt.amount),
            vs.serialize(bt.destCurrencyID),
            vs.serialize(bt.secondReserveID));
    }
  
    function serializeBridgeTransactions(BridgeTransaction[] memory _bts) public returns(bytes memory){
        bytes memory inProgress;
        
        inProgress = vs.serializeUInt256(_bts.length);
        for(uint i=0; i < _bts.length; i++){
            inProgress = abi.encodePacked(inProgress,serializeBridgeTransaction(_bts[i]));
        }
        return inProgress;
    }

    function encodeBT() public returns(bytes memory){
        BridgeTransaction memory bt = BridgeTransaction(1,
        uint160(0x0000000000000000000000000000000000000005),
        12345,
        CTransferDestination(TransferDestinationType.DEST_PK,uint160(0x0000000000000000000000000000000000000005)),
        6789,
        uint160(0x0000000000000000000000000000000000000006),
        uint160(0x0000000000000000000000000000000000000007));
        
        bts.push(bt);
        bts.push(bt);
        bts.push(bt);
        bts.push(bt);
        bts.push(bt);
        bts.push(bt);
        return serializeBridgeTransactions(bts);
        //return abi.encode(bts);
        /*0x
        0000000000000000000000000000000000000000000000000000000000000001
        0000000000000000000000000000000000000000000000000000000000000005
        0000000000000000000000000000000000000000000000000000000000003039
        0000000000000000000000000000000000000000000000000000000000000001
        0000000000000000000000000000000000000000000000000000000000000005
        0000000000000000000000000000000000000000000000000000000000001a85
        0000000000000000000000000000000000000000000000000000000000000006
        0000000000000000000000000000000000000000000000000000000000000007
    }
    
*/    
    uint8[] arrayTest;
    function encodeTest() public returns(bytes memory){
        //uint8[5] memory arrayTest = [1,2,3,4,5];
        //arrayTest.push(1);
        //arrayTest.push(2);
        //arrayTest.push(3);
        //arrayTest.push(4);
        //arrayTest.push(5);
        uint32 flagTest = 1;
        address feeTest = uint160(0x0000000000000000000000000000000000000005);
        bytes20 bytesTest = bytes20(0x0000000000000000000000000000000000000005);
        //bytes memory output = vs.serialize(bytesTest);
        uint32 transferType = 1;
        bytes memory output = vs.serializeUint32(transferType);
        //bytes memory output = abi.encodePacked(vs.serializeUInt32(flagTest),vs.serializeUInt160(feeTest));
        return output;
        //return abi.encodePacked(flagTest,feeTest);
        
    }

}
/*
0x0000000000000000000000000000000000000005
*/
/*
0x
0000000000000000000000000000000000000000000000000000000000000020
0000000000000000000000000000000000000000000000000000000000000006
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000005
0000000000000000000000000000000000000000000000000000000000003039
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000005
0000000000000000000000000000000000000000000000000000000000001a85
0000000000000000000000000000000000000000000000000000000000000006
0000000000000000000000000000000000000000000000000000000000000007
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000005
0000000000000000000000000000000000000000000000000000000000003039
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000005
0000000000000000000000000000000000000000000000000000000000001a85
0000000000000000000000000000000000000000000000000000000000000006
0000000000000000000000000000000000000000000000000000000000000007
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000005
0000000000000000000000000000000000000000000000000000000000003039
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000005
0000000000000000000000000000000000000000000000000000000000001a85
0000000000000000000000000000000000000000000000000000000000000006
0000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000003039000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000001a8500000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000003039000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000001a8500000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000003039000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000001a850000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000
*/


