// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 < 0.7.0;
pragma experimental ABIEncoderV2;

library VerusObjects {

    struct CCurrencyValueMap {
        uint160 currency;
        uint64 amount;
    }

    enum TransferDestinationType{
        DEST_INVALID,DEST_PK,DEST_PKH,DEST_SH,DEST_ID,DEST_FULLID,DEST_QUANTUM,DEST_RAW
    }

    struct CTransferDestination {
        uint8 transferType;
        uint160 destination;
    }

    //pending transactions array
    struct CTransfer {
        uint32 flags; //type of transfer 0,
        uint160 feeCurrencyID; //fees are paid in this currency
        uint64 nFees; //cross chain network fees
        CTransferDestination destination; //destination address
        uint64 amount;
        uint160 destCurrencyID;
        uint160 secondReserveID;
    }

    struct CTransferSet {
        uint16 version;
        uint16 flags;
        uint160 sourceSystemID;
        uint32 sourceHeightStart;
        uint32 sourceHeightEnd;
        uint160 destCurrencyId; //does this need to be here as we have the currency map?
        CCurrencyValueMap[] totalAmounts; 
        CCurrencyValueMap[] totalFees;
        uint32 numInputs; //number of transactions in this list
        uint256 hashReserveTransfer; //hash of the transactions in this block
        uint32 firstInput; 
    }

}