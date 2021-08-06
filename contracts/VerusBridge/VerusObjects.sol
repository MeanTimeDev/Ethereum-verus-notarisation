// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 < 0.9.0;
pragma experimental ABIEncoderV2;

library VerusObjects {
    
    address constant public VEth = 0x67460C2f56774eD27EeB8685f29f6CEC0B090B00;
    address constant public EthSystemID = VEth;
    address constant public VerusSystemId = 0xA6ef9ea235635E328124Ff3429dB9F9E91b64e2d;
    address constant public VerusCurrencyId = 0xA6ef9ea235635E328124Ff3429dB9F9E91b64e2d;
    //does this need to be set 
    address constant public RewardAddress = 0xB26820ee0C9b1276Aac834Cf457026a575dfCe84;
    uint8 constant public RewardAddressType = 4;
    uint256 constant public transactionFee = 100000000000000; //0.0001 eth
    string constant public currencyName = "VETH";
    
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
        address currencyid;
        address parent;
        address systemid;
        uint8 notarizationprotocol;
        uint8 proofprotocol;
        VerusObjects.CTransferDestination nativecurrencyid;
        address launchsystemid;
        uint startblock;
        uint endblock;
        uint256 initialsupply;
        uint256 prelaunchcarveout;
        address gatewayid;
        address[] notaries;
        uint minnotariesconfirm;
    }
    
    struct CCurrencyValueMap {
        address currency;
        uint64 amount;
    }

    enum TransferDestinationType{
        DEST_INVALID,DEST_PK,DEST_PKH,DEST_SH,DEST_ID,DEST_FULLID,DEST_QUANTUM,DEST_RAW
    }

    struct CTransferDestination {
        uint8 destinationtype;
        address destinationaddress;
    }

    struct CReserveTransfer {
        uint32 version;
        CCurrencyValueMap currencyvalue;
        uint32 flags;
        address feecurrencyid;
        uint256 fees;
        CTransferDestination destination;
        address destCurrencyID;
        address destSystemID;
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
        uint16 version;
        uint16 flags;
        address sourcesystemid;
        uint32 sourceheightstart;
        uint32 sourceheightend;
        address destinationsystemid;
        address destinationcurrencyid;
        uint32 numinputs;
        CCurrencyValueMap[] totalamounts;
        CCurrencyValueMap[] totalfees;
        bytes32 hashtransfers; // hashtransfers
        CCurrencyValueMap[] totalburned;
        CTransferDestination rewardaddress; //reward address
        int32 firstinput;
    }

    /** Notarisation objects */


    struct CProofRoot{
        int16 version;                        // to enable future data types with various functions
        int16 CPRtype;                           // type of proof root
        address systemID;                       // system that can have things proven on it with this root
        uint32 rootHeight;                    // height (or sequence) of the notarization we certify
        bytes32 stateRoot;                      // latest MMR root of the notarization height
        bytes32 blockHash;                      // combination of block hash, block MMR root, and compact power (or external proxy) for the notarization height
        bytes32 compactPower;   
    }

    struct CurrencyStates {
        address currencyId;
        CCoinbaseCurrencyState currencyState;
    }

    struct ProofRoots {
        address currencyId;
        CProofRoot proofRoot;
    }

    struct CCoinbaseCurrencyState {
        uint16 version;
        uint16 flags;
        address currencyID;
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
        int32[] priorWeights;
        int64[] conversionFees;    // total of only conversion fees, which will accrue to the conversion transaction
    }

    struct CUTXORef {
        bytes32 hash;
        uint32 n;
    }

    struct CNodeData {
        string networkAddress;
        address nodeIdentity;
    }

    struct CPBaaSNotarization {
        uint32 version;
        uint32 flags;
        CTransferDestination proposer;
        address currencyID;
        CCoinbaseCurrencyState currencyState;
        uint32 notarizationHeight;
        CUTXORef prevNotarization;
        bytes32 hashPrevNotarization;
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