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
        uint160 destinationaddress;
    }

    struct CReserveTransfer {
        uint32 version;
        CCurrencyValueMap currencyvalues;
        uint32 flags;
        uint160 feecurrencyid;
        uint256 fees;
        CTransferDestination destination;
        uint160 destCurrencyID;
        uint160 secondReserveID;
        uint160 destSystemID;
    }

    //CReserve Transfer Set is a simplified version of a crosschain export returning only the required info
    
    struct CReserveTransferSet {
        uint position;
        uint blockHeight;
        bytes32 exportHash;
        CReserveTransfer[] transfers;
    }

    struct CReserveTransferImport {
        uint height;
        bytes32 txid; //this is actually the hash of the transfers that can be used for proof
        uint txoutnum; //index of the transfers in the exports array
        CCrossChainExport exportinfo;
        bytes32[] partialtransactionproof;  //partial transaction proof is for the 
        CReserveTransfer[] transfers;
    }

    struct CCrossChainExport {
        uint8 version;
        uint32 flags;
        uint160 sourcesystemid;
        uint32 sourceheightstart;
        uint32 sourceheightend;
        uint160 destinationsystemid;
        uint160 destinationcurrencyid;
        int32 numinputs;
        CCurrencyValueMap[] totalamounts;
        CCurrencyValueMap[] totalfees;
        uint256 hashtransfers; // hashtransfers
        CCurrencyValueMap[] totalburned;
        address rewardaddress; //reward address
        int32 firstinput;
    }

    /** Notarisation objects */


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
        int64 primaryCurrencyOut;
        int64 preconvertedOut;
        int64 primaryCurrencyFees;
        int64 primaryCurrencyConversionFees;
        int64[] reserveIn;         // reserve currency converted to native
        int64[] primaryCurrencyIn;
        int64[] reserveOut;        // output can have both normal and reserve output value, if non-0, this is spent by the required output transactions
        int64[] conversionPrice;   // calculated price in reserve for all conversions * 100000000
        int64[] viaConversionPrice; // the via conversion stage prices
        int64[] fees;              // fee values in native (or reserve if specified) coins for reserve transaction fees for the block
        int64[] conversionFees;    // total of only conversion fees, which will accrue to the conversion transaction
        int32[] priorWeights;
    }

    struct CUTXORef {
        uint256 hash;
        uint32 n;
    }

    struct CNodeData {
        string networkAddress;
        uint160 nodeIdentity;
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
        CNodeData[] nodes;
    }
    //represents the output from the pbaas rpc
    struct Notarization {
        uint32 index;
        bytes32 txid;
        uint32 vout;
        CPBaaSNotarization notarization;
        CNodeData[] nodes;
    }

    struct CChainNotarizationData {
        uint32 version;
        Notarization[] notarizations;
        int32[][] forks; // chains that represent alternate branches from the last confirmed notarization
        int32 lastConfirmedHeight; // last confirmed notarization
        int32 bestChain; // index in forks of the chain, beginning with the last confirmed notarization, that has the most power
    }
}