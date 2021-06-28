// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./TokenManager.sol";
import "../MMR/VerusProof.sol";
import "../MMR/VerusBLAKE2b.sol";
import { Memory } from "../Standard/Memory.sol";
import "./Token.sol";
import "./VerusObjects.sol";
import "./VerusSerializer.sol";
import "../VerusNotarizer/VerusNotarizer.sol";

contract VerusBridge {
 
    //list of erc20 tokens that can be accessed,
    //the contract must be able to mint and burn coins on the contract
    //defines the tokenManager which creates the erc20
    TokenManager tokenManager;
    VerusSerializer verusSerializer;
    VerusProof verusProof;
    VerusBLAKE2b blake2b;
    VerusNotarizer verusNotarizer;

    //THE CONTRACT OWNER NEEDS TO BE REPLACED BY A SET OF NOTARIES
    address contractOwner;
    bool public deprecated = false; //indicates if the cotnract is deprecated
    address public upgradedAddress;
    uint256 public feesHeld = 0;
    uint256 public ethHeld = 0;

    uint64 public transactionsPerCall = 2;

    uint160 public VEth = uint160(0x0000000000000000000000000000000000000000);
    uint160 public EthSystemID = uint160(0x0000000000000000000000000000000000000000);
    uint160 public VerusSystemId = uint160(0x0000000000000000000000000000000000000001);
    //does this need to be set 
    uint160 public RewardAddress = uint160(0x0000000000000000000000000000000000000002);
    uint256 transactionFee = 100000000000000; //0.0001 eth
    //used to prove the transfers the index of this corresponds to the index of the 
    bytes32[] public readyExportHashes;
    uint CBCurrencyTypes = 0;
    uint CBFeesTypes = 0;
    
    //used to store a list of currencies and an amount
    VerusObjects.CReserveTransfer[] private _pendingExports;
    uint[] _pendingBlockHeights;
    
    //stores the blockheight of each pending transfer
    //the export set holds the summary of a set of exports
    VerusObjects.CReserveTransfer[][] public _readyExports;
    //used for proving the export set
    
    mapping (bytes32 => uint) public processedImportSetHashes;
    //stores the index of the 
    mapping (uint => uint[]) public readyExportsByBlock;
    mapping (address => uint256) public claimableFees;
    
    event ReceivedTransfer(VerusObjects.CReserveTransfer transaction);
    event ExportsReady(uint256 index);
    event Deprecate(address newAddress);
    
    constructor(address verusProofAddress,address tokenManagerAddress,address verusSerializerAddress,address verusBLAKE2bAddress,address verusNotarizerAddress) public {
        contractOwner = msg.sender; 
        verusProof =  VerusProof(verusProofAddress);
        tokenManager = TokenManager(tokenManagerAddress);
        verusSerializer = VerusSerializer(verusSerializerAddress);
        blake2b = VerusBLAKE2b(verusBLAKE2bAddress);
        verusNotarizer = VerusNotarizer(verusNotarizerAddress);
    }

    function exportETH(uint160 _destination,uint256 _nFees,uint160 _secondReserveID,uint160 _destSystemID) public payable returns(uint256){
        require(!deprecated,"Contract has been deprecated");
        //calculate amount of eth to send
        require(msg.value > transactionFee,"Ethereum must be sent with the transaction to be sent to the Verus Chain");
        uint256 amount = msg.value - transactionFee;
        ethHeld += amount;
        feesHeld += transactionFee;
        //create a new Bridge Transaction
        uint32 flags = 0;
        uint160 feeCurrencyID = 0;
        VerusObjects.CTransferDestination memory transferDestination = VerusObjects.CTransferDestination(1,_destination); 
        VerusObjects.CCurrencyValueMap memory currencyvalues = VerusObjects.CCurrencyValueMap(VEth,uint64(amount));
        VerusObjects.CReserveTransfer memory newTransaction = VerusObjects.CReserveTransfer(
            1,
            currencyvalues,
            flags,
            feeCurrencyID,
            _nFees,
            transferDestination,
            VEth,
            _secondReserveID,
            _destSystemID);
        _createExports(newTransaction);

        return amount;
    }

    //nFees and secondReserveID are used to send the tokens/eth on
    function exportERC20(uint64 _amount,address _tokenAddress,uint160 _destination,uint160 _destCurrencyID,uint256 _nFees,uint160 _secondReserveID,uint160 _destSystemID) public payable {
        //check that they are not attempting to send Eth
        require(!deprecated,"Contract has been deprecated");
        require(msg.value >= transactionFee + uint64(_nFees),"Please send the appropriate transaction fee.");
        require(_destination != VEth,"To send eth use exportETH");
        //check there are enough fees sent
        feesHeld += msg.value;
        Token token = Token(_tokenAddress);
        uint256 allowedTokens = token.allowance(msg.sender,address(this));
        require( uint64(allowedTokens) >= _amount,"This contract must have an allowance of greater than or equal to the number of tokens");
        //transfer the tokens to this contract
        token.transferFrom(msg.sender,address(this),uint256(_amount)); 
        token.approve(address(tokenManager),uint256(_amount));  
        //give an approval for the tokenmanagerinstance to spend the tokens
        tokenManager.exportERC20Tokens(_tokenAddress,uint256(_amount));

        uint32 flags = 0;
        uint160 feeCurrencyID = 0;
        VerusObjects.CTransferDestination memory transferDestination = VerusObjects.CTransferDestination(1,_destination);
        VerusObjects.CCurrencyValueMap memory currencyvalues = VerusObjects.CCurrencyValueMap(uint160(_tokenAddress),_amount);
        VerusObjects.CReserveTransfer memory newTransaction = VerusObjects.CReserveTransfer(
            1,
            currencyvalues,
            flags,
            feeCurrencyID,
            _nFees,
            transferDestination,
            _destCurrencyID,
            _secondReserveID,
            _destSystemID);
        //create the BridgeTransaction 
        _createExports(newTransaction);
    }

    function _createExports(VerusObjects.CReserveTransfer memory newTransaction) private {
        uint currentHeight = block.number;
        uint exportsIndex;
        

        //check if the current block height has a set of transfers associated with it if so add to the existing array
        if((exportsIndex = readyExportsByBlock[currentHeight].length) > 0) {
            //append to an existing array of transfers
            //
            _readyExports[exportsIndex-1].push(newTransaction);
        }
        else {
            
            _pendingExports.push(newTransaction);
            _readyExports.push(_pendingExports);
            readyExportsByBlock[currentHeight].push(_readyExports.length-1);
            delete _pendingExports;
        }
        //create a cross chain export, serialize it and hash it
        //VerusObjects.CCrossChainExport memory CCCE = _createCCrossChainExport(exportsIndex);
        //create a hash of the CCCE
        //bytes memory serializedCCE = verusSerializer.serializeCCrossChainExport(CCCE);
        //bytes32 hashedCCE = blake2b.createHash(serializedCCE);
        //add the hashed value
        //readyExportHashes[exportsIndex] = hashedCCE;
        
    }


/*
    function _createExports(VerusObjects.CReserveTransfer memory newTransaction) private {
        bytes32 hashedTransactions;

        _pendingExports.push(newTransaction);    
        _pendingBlockHeights.push(block.number);
        
        //loop through the totalAmounts and append if the currency exists
        if(_pendingExports.length >= transactionsPerCall){
            //add the transactions to the ready export
            _readyExports.push(_pendingExports);
            //should actually create an mmr not
            hashedTransactions = blake2b.createHash(verusSerializer.serializeCReserveTransfers(_pendingExports));
            //create a hash of the transactions for proo
            readyExportHashes.push(hashedTransactions);
            //clear the pending array
            delete _pendingExports;
            //add the block to the mapping
            readyExportsByBlock[block.number].push(_readyExports.length - 1);
            
            //emit an event       
            emit ExportsReady(_readyExports.length - 1);     
        }
        
    }*/
    
    //create a cross chain export and serialize it for hashing 
    function _createCCrossChainExport(uint exportIndex) public returns (VerusObjects.CCrossChainExport memory){
        bytes32 hashedTransfers;
        //create a hash of the transfers and then 
        hashedTransfers = blake2b.createHash(verusSerializer.serializeCReserveTransfers(_readyExports[exportIndex]));

        //create the Cross ChainExport to then serialize and hash

        VerusObjects.CCrossChainExport memory workingCCE;
        workingCCE.version = 1;
        workingCCE.flags = 3;
        //need to pick up the 
        workingCCE.sourceheightstart = uint32(block.number);
        workingCCE.sourceheightend =uint32(block.number);
        workingCCE.sourcesystemid = EthSystemID;
        workingCCE.destinationsystemid = VerusSystemId;
        workingCCE.destinationcurrencyid = VEth;
        workingCCE.numinputs = int32(_readyExports[exportIndex].length);
        //loop through the array and create totals of the amounts and fees

        //how to calculate the length of the CCurrencyValueMap arrays before the can be created
        //may need to be intitalised to the maximum possible size
        uint160[] memory currencyAddresses = new uint160[](_readyExports[exportIndex].length);
        uint64[] memory currencyAmounts = new uint64[](_readyExports[exportIndex].length);
        uint numAmounts = 0;
        uint160[] memory feesCurrencies = new uint160[](_readyExports[exportIndex].length);
        uint64[] memory feesAmounts = new uint64[](_readyExports[exportIndex].length);
        uint numFees = 0;
        uint160 currencyAddress;
        uint64 currencyAmount;
        uint160 feecurrency;
        uint64 feeamount;
        for(uint i = 0; i < _readyExports[exportIndex].length; i++){
            
            currencyAddress = _readyExports[exportIndex][i].currencyvalues.currency;
            currencyAmount = _readyExports[exportIndex][i].currencyvalues.amount;
            bool currencyExists = false;
            for(uint j = 0; j < currencyAddresses.length; j++){
                if(currencyAddresses[j] == currencyAddress) {
                    currencyAmounts[j] += currencyAmount;
                    currencyExists = true;
                    break;
                }
            }
           if(currencyExists == false){
                currencyAddresses[numAmounts] = currencyAddress;
                currencyAmounts[numAmounts] = currencyAmount;
                numAmounts++;
            }    
            
            feecurrency = _readyExports[exportIndex][i].feecurrencyid;
            feeamount = uint64(_readyExports[exportIndex][i].fees);
            currencyExists = false;
            for(uint k = 0; k < feesCurrencies.length; k++){
                if(feesCurrencies[k] == feecurrency) {
                    feesAmounts[k] += feeamount;
                    currencyExists = true;
                    break;
                }
            }
            if(currencyExists == false){
                feesCurrencies[numFees] = feecurrency;
                feesAmounts[numFees] = feeamount;
                numFees++;
            }
            
        }
    /*
        //create the total amounts arrays
        workingCCE.totalamounts = new VerusObjects.CCurrencyValueMap[](currencyAddresses.length);
        for(uint l = 0; l < currencyAddresses.length ; l++){
            if(currencyAddresses[l] != 0) {
                workingCCE.totalamounts[l] = VerusObjects.CCurrencyValueMap(currencyAddresses[l],currencyAmounts[l]);
            }
        }
        
        workingCCE.totalfees = new VerusObjects.CCurrencyValueMap[](feesCurrencies.length);
        for(uint m = 0; m < feesCurrencies.length ; m++){
            if(feesCurrencies[m] != 0) {
                workingCCE.totalfees[m] = VerusObjects.CCurrencyValueMap(feesCurrencies[m],feesAmounts[m]);
            }
        }
   
        workingCCE.hashtransfers = uint256(hashedTransfers);
        VerusObjects.CCurrencyValueMap memory totalburnedCCVM = VerusObjects.CCurrencyValueMap(0,0);
        
        workingCCE.totalburned = new VerusObjects.CCurrencyValueMap[](1);
        workingCCE.totalburned[0] = totalburnedCCVM;
        workingCCE.rewardaddress = address(RewardAddress);
        workingCCE.firstinput = 0;*/
        return workingCCE;
    }

    /***
     * Import from Verus functions
     ***/
     

    function submitImports(VerusObjects.CReserveTransferImport[] memory _imports) public returns (bool){
        //loop through the transfers and process
        for(uint i = 0; i < _imports.length; i++){
            _createImports(_imports[i]);
        }
    }

    function _createImports(VerusObjects.CReserveTransferImport memory _import) private returns(bool){
        //TO DO
        //prove the transaction
        // require(verusProof.proveTransaction(_import.txid,_import.partialtransactionproof,_import.txoutnum,_import.height));
        //check the transfers were in the hash.
        for(uint i = 0; i < _import.transfers.length; i++){
            //handle eth transactions
            if(_import.transfers[i].destCurrencyID == VEth) {
                //cast the destination as an ethAddress
                sendEth(_import.transfers[i].currencyvalues.amount,payable(address(_import.transfers[i].destination.destinationaddress)));
                ethHeld -= _import.transfers[i].currencyvalues.amount;
            } else {
                //handle erc20 transactions   
                tokenManager.importERC20Tokens(_import.transfers[i].destCurrencyID,
                    _import.transfers[i].currencyvalues.amount,
                    _import.transfers[i].destination.destinationaddress);
            }
            //handle the distributions of the fees
            //add them into the fees array to be claimed by the message sender
            if(_import.transfers[i].fees > 0 && _import.transfers[i].feecurrencyid == VEth){
                claimableFees[msg.sender] = claimableFees[msg.sender] + _import.transfers[i].fees;
            }
            //could there be a scenario where more fees are paid here than there are funds for
            //if its a create token situation how do we handle that
            //probably best to just allow tokens to be created as a seperate operation
        }
        return true;
    }

    

    /**
    returns a list of exports to be processed on the verus chain
    */
    
    function getReadyExportsIndex() public view returns(uint){
        require(!deprecated,"Contract has been deprecated");
        return _readyExports.length - 1;
    }

    function getReadyExports(uint _eIndex) public view returns(VerusObjects.CReserveTransfer[] memory){
        require(!deprecated,"Contract has been deprecated");
        return _readyExports[_eIndex];
    }
    
    
    function getReadyExportsByBlock(uint _blockNumber) public view returns(VerusObjects.CReserveTransferSet[] memory){
        //need a transferset for each position not each block
        //retrieve a block get the indexes, create a transfer set for each index add those to the array
        
        uint[] memory eIndexes = readyExportsByBlock[_blockNumber];
        VerusObjects.CReserveTransferSet[] memory output = new VerusObjects.CReserveTransferSet[](eIndexes.length);
        for(uint i = 0; i < eIndexes.length; i++){
            output[i] = VerusObjects.CReserveTransferSet(
                eIndexes[i], //position in main array
                _blockNumber, //blockHeight
                readyExportHashes[eIndexes[i]], //hash of the transactions
                _readyExports[eIndexes[i]] //list of transactions
            );
        }

        return output;
    }

    
    function getReadyExportsByRange(uint _startBlock,uint _endBlock) public view returns(VerusObjects.CReserveTransferSet[] memory){
        //calculate the size that the return array will be to initialise it
        uint outputSize = 0;
        for(uint i = _startBlock; i <= _endBlock; i++){
            outputSize += readyExportsByBlock[i].length;
        }

       VerusObjects.CReserveTransferSet[] memory output = new VerusObjects.CReserveTransferSet[](outputSize);
        
        uint[] memory eIndexes;
        
        uint outputPosition = 0;
        for(uint blockNumber = _startBlock;blockNumber <= _endBlock;blockNumber++){
            eIndexes = readyExportsByBlock[blockNumber];
            for(uint i = 0; i < eIndexes.length; i++){
                output[outputPosition] = VerusObjects.CReserveTransferSet(
                    eIndexes[i], //position in main array
                    blockNumber, //blockHeight
                    readyExportHashes[eIndexes[i]], //hash of the transactions
                    _readyExports[eIndexes[i]] //list of transactions
                );
                outputPosition++;
            }
            
        }
        return output;        
    }
 
    function sendEth(uint256 _ethAmount,address payable _ethAddress) private {
        require(!deprecated,"Contract has been deprecated");
        //do we take fees here????
        require(_ethAmount <= address(this).balance,"Requested amount exceeds contract balance");
        _ethAddress.transfer(_ethAmount);
    }
    
    function claimFees() public returns(uint256){
        require(!deprecated,"Contract has been deprecated");
        if(claimableFees[msg.sender] > 0 ){
            sendEth(claimableFees[msg.sender],msg.sender);
        }
        return claimableFees[msg.sender];

    }

    function deprecate(address _upgradedAddress,bytes32 _addressHash,uint8[] memory _vs,bytes32[] memory _rs,bytes32[] memory _ss) public returns(address){
        if(verusNotarizer.notarizedDeprecation(_upgradedAddress, _addressHash, _vs, _rs, _ss)){
            deprecated = true;
            upgradedAddress = _upgradedAddress;
            Deprecate(_upgradedAddress);
        }
    }


}
