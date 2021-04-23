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
        uint32 destinationtype;
        address destinationaddress;
    }

    struct CReserveTransfer {
        uint32 version;
        CCurrencyValueMap currencyvalues;
        uint32 flags;
        bool preconvert;
        address feecurrencyid;
        uint256 fees;
        address destinationcurrencyid;
        CTransferDestination destination;
        uint160 destCurrencyID;
        uint160 secondReserveID;
    }

    struct CReserveTransferImport {
        uint height;
        bytes32 txid; //this is actually the hash of the transfers that can be used for proof
        uint txoutnum; //index of the transfers in the exports array
        CCrossChainExport exportinfo;
        bytes32[] partialtransactionproof;  //partial transaction prroof is for the 
        CReserveTransfer[] transfers;
    }

/*
    struct CCrossChainExport {
        uint8 version;
        uint32 flags;
        uint160 sourceSystemID;
        uint32 sourceHeightStart;
        uint32 sourceHeightEnd;
        uint160 destSystemID;
        uint160 destCurrencyID;
        int32 numInputs;
        CCurrencyValueMap totalAmounts;
        CCurrencyValueMap totalFees;
        uint256 hashReserveTransfers; // hashtransfers
        CTransferDestination exporter; //reward address
        int32 firstInput;
    }*/

    struct CCrossChainExport {
        uint8 version;
        uint32 flags;
        uint160 sourcesystemid;
        uint32 sourceheightstart;
        uint32 sourceheightend;
        uint160 destinationsystemid;
        uint160 destinationcurrencyid;
        int32 numinputs;
        CCurrencyValueMap totalamounts;
        CCurrencyValueMap totalfees;
        uint256 hashtransfers; // hashtransfers
        address rewardaddress; //reward address
        int32 firstinput;
    }

    /** Notarisation objects */

    struct CChainNotarizationData {
        uint32 version;
        int32 lastConfirmed; // last confirmed notarization
        int32[][] forks; // chains that represent alternate branches from the last confirmed notarization
        int32 bestChain; // index in forks of the chain, beginning with the last confirmed notarization, that has the most power
    }

    struct CProofRoot{
        int16 version;                        // to enable future data types with various functions
        int16 CPRtype;                           // type of proof root
        uint160 systemID;                       // system that can have things proven on it with this root
        uint32 rootHeight;                    // height (or sequence) of the notarization we certify
        uint256 stateRoot;                      // latest MMR root of the notarization height
        uint256 blockHash;                      // combination of block hash, block MMR root, and compact power (or external proxy) for the notarization height
        uint256 compactPower;   
    }

    struct CurrencyStates {
        uint160 currencyId;
        CCoinbaseCurrencyState currencyState;
    }

    struct ProofRoots {
        uint160 currencyId;
        CProofRoot proofRoot;
    }

    struct CCoinbaseCurrencyState {
        int64 nativeOut;                      // converted native output, emitted is stored in parent class
        int64 nativeFees;
        int64 nativeConversionFees;
        int64[] reserveIn;         // reserve currency converted to native
        int64[] nativeIn;          // native currency converted to reserve
        int64[] reserveOut;        // output can have both normal and reserve output value, if non-0, this is spent by the required output transactions
        int64[] conversionPrice;   // calculated price in reserve for all conversions * 100000000
        int64[] viaConversionPrice; // the via conversion stage prices
        int64[] fees;              // fee values in native (or reserve if specified) coins for reserve transaction fees for the block
        int64[] conversionFees;    // total of only conversion fees, which will accrue to the conversion transaction
    }
/*
    struct CIdentitySignature {
        uint8 verion;
        uint32 blockHeight;
        bytes65[] signatures;
    }*/


/*
    struct CIdentitySignature{
        uint8 version;
        uint32 blockHeight;
        bytes65[] signatures;
    }

    struct Signatures {
        uint160 cIdentityID;
        CIdentitySignature cIdentitySignature;
    }

    struct CPartialProof {
        int8 version;
        int8 CPPtype;
        CMMRProof txProof;
        CTransactionComponentProof[] components;
    }
*/
    struct CUTXORef {
        uint256 hash;
        uint32 n;
    }

    struct CPBaaSNotarization {
        uint32 version;
        uint32 flags;
        CTransferDestination proposer;
        uint160 currencyID;
        uint32 notarizationHeight;
        CCoinbaseCurrencyState currencyState;
        CUTXORef prevNotarization;
        uint256 hashPrevNotarization;
        uint32 prevHeight;
        CurrencyStates[] currencyStates;
        ProofRoots[] proofRoots;
    }
/*
    struct CNotaryEvidence {
        uint8 version;
        uint8 CNEtype;
        uint160 systemID;
        bytes32 output; //hash of the notarisation
        bool confirmed;
        Signatures[] signatures;
        //evidence; not needed as we dont eneed to prove the notarisation far too complicated to try adn deal with

    }*/

}