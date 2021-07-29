// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 < 0.9.0;
pragma experimental ABIEncoderV2;

library VerusObjects {
    
    uint160 constant public VEth = uint160(0x67460C2f56774eD27EeB8685f29f6CEC0B090B00);
    uint160 constant public EthSystemID = VEth;
    uint160 constant public VerusSystemId = uint160(0xA6ef9ea235635E328124Ff3429dB9F9E91b64e2d);
    uint160 constant public VerusCurrencyId = uint160(0xA6ef9ea235635E328124Ff3429dB9F9E91b64e2d);
    //does this need to be set 
    uint160 constant public RewardAddress = uint160(0x0000000000000000000000000000000000000002);
    uint256 constant public transactionFee = 100000000000000; //0.0001 eth
    
    struct blockCreated {
        uint index;
        bool created;
    }
    struct infoDetails {
        uint version;
        string VRSCversion;
        uint blocks;
        uint tiptime;
        string name;
        bool testnet;
    }
    
    struct currencyDetail {
        uint version;
        string name;
        uint160 currencyid;
        uint160 parent;
        uint160 systemid;
        uint8 notarizationprotocol;
        uint8 proofprotocol;
        VerusObjects.CTransferDestination nativecurrencyid;
        uint160 launchsystemid;
        uint startblock;
        uint endblock;
        uint256 initialsupply;
        uint256 prelaunchcarveout;
        uint160 gatewayid;
        address[] notaries;
        uint minnotariesconfirm;
    }
    
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
        CCurrencyValueMap currencyvalue;
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
        uint32 version;
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
        uint16 version;
        uint16 flags;
        uint160 currencyID;
        uint160[] currencies;
        int32[] weights;
        int64[] reserves;
        int64 initialSupply;
        int64 emitted;
        int64 supply;
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
        CTransferDestination proposer;
        uint32 notarizationHeight;
        CCoinbaseCurrencyState currencyState;
        uint256 prevnotarizationtxid;
        int64 prevnotarizationout;
        uint256 hashprevnotarizationobject;
        uint64 prevheight;
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