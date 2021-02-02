// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./TokenManager.sol";
import "../MMR/VerusProof.sol";
import { Memory } from "../Standard/Memory.sol";
import "./Token.sol";
import "./VerusObjects.sol";
import "./VerusSerializer.sol";

contract VerusBridge {
 
    //list of erc20 tokens that can be accessed,
    //the contract must be able to mint and burn coins on the contract
    //defines the tokenManager which creates the erc20
    TokenManager tokenManager;
    VerusSerializer verusSerializer;
    VerusProof verusProof;

    //THE CONTRACT OWNER NEEDS TO BE REPLACED BY A SET OF NOTARIES
    address contractOwner;
    bool public deprecated = false; //indicates if the cotnract is deprecated
    address public upgradedAddress;
    uint256 public feesHeld = 0;
    uint256 public ethHeld = 0;

    bytes verusKey = "VerusDefaultHash";
    uint64 public transactionsPerCall = 2;

    uint160 public VEth = uint160(0x0000000000000000000000000000000000000000);
    uint256 transactionFee = 100000000000000; //0.0001 eth
    bytes32[] public readyExportSetHashes;
    //used to store a list of currencies and an amount
    
    VerusObjects.CTransfer[] private _pendingExports;
    VerusObjects.CTransferSet public pendingExportSet;
    //the export set holds the summary of a set of exports
    VerusObjects.CTransfer[][] private _readyExports;
    VerusObjects.CTransferSet[] public readyExportSet;
    VerusObjects.CTransferSet[] public processedImportSets;
    //used for proving the export set
    
    mapping (bytes32 => uint) public processedImportSetHashes;
    mapping (uint => uint[]) public readyExportsByBlock;
    
    event ReceivedTransfer(VerusObjects.CTransfer transaction);
    event ExportsReady(uint256 index);
    event Deprecate(address newAddress);
    
    constructor(address verusProofAddress,address tokenManagerAddress) public {
        contractOwner = msg.sender;
        verusProof =  VerusProof(verusProofAddress);
        tokenManager = TokenManager(tokenManagerAddress);
        verusSerializer = new VerusSerializer();
        _initializePendingExportSet();
    }


    function _initializePendingExportSet() private{
        pendingExportSet.version = 1;
        pendingExportSet.flags = 1;
        pendingExportSet.sourceSystemID = uint160(0x0000000000000000000000000000000000000000);
        pendingExportSet.sourceHeightStart = 0; //reinitiate this to be overwritten at point of adding it to the array
        pendingExportSet.sourceHeightEnd = 0;
        pendingExportSet.destCurrencyId = uint160(0x0000000000000000000000000000000000000000); //default value till we know what to put in here
        delete pendingExportSet.totalAmounts;
        delete pendingExportSet.totalFees;
        pendingExportSet.numInputs = 0;
        pendingExportSet.hashReserveTransfer = 0x00;
        pendingExportSet.firstInput = 0;
    }

    function exportETH(uint160 _destination,uint64 _nFees,uint160 _secondReserveID) public payable returns(uint256){
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
        
        VerusObjects.CTransfer memory newTransaction = VerusObjects.CTransfer(flags,
            feeCurrencyID,
            _nFees,
            transferDestination,
            uint64(amount),
            VEth,
            _secondReserveID);
        _createExports(newTransaction);

        return amount;
    }

    //nFees and secondReserveID are used to send the tokens/eth on
    function exportERC20(uint64 _amount,address _tokenAddress,uint160 _destination,uint160 _destCurrencyID,uint64 _nFees,uint160 _secondReserveID) public payable {
        //check that they are not attempting to send Eth
        require(!deprecated,"Contract has been deprecated");
        require(msg.value >= transactionFee + _nFees,"Please send the appropriate transaction fee.");
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
        VerusObjects.CTransfer memory newTransaction = VerusObjects.CTransfer(flags,feeCurrencyID,_nFees,transferDestination,_amount,_destCurrencyID,_secondReserveID);
        //create the BridgeTransaction 
        _createExports(newTransaction);
    }

    function _createExports(VerusObjects.CTransfer memory newTransaction) private {
        _pendingExports.push(newTransaction);    
        //update the pendingTransactionSet
        //loop through the total amounts 
        
        //loop through the totalAmounts and append if the currency exists
        bool currencyExists = false;
        for(uint i = 0;i<pendingExportSet.totalAmounts.length;i++){
            if(pendingExportSet.totalAmounts[i].currency == newTransaction.destCurrencyID){
                pendingExportSet.totalAmounts[i].amount += newTransaction.amount;
                currencyExists = true;
            }
        }
        
        if(!currencyExists){
            pendingExportSet.totalAmounts.push(VerusObjects.CCurrencyValueMap(newTransaction.destCurrencyID,newTransaction.amount));
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
                pendingExportSet.totalFees.push(VerusObjects.CCurrencyValueMap(newTransaction.destCurrencyID,newTransaction.amount));
            }
        }
        
        pendingExportSet.numInputs++;
        pendingExportSet.hashReserveTransfer = uint256(verusProof.createHash(verusSerializer.serializeCTransfers(_pendingExports),verusKey));
        
        //if we are ready to release
        if(_pendingExports.length >= transactionsPerCall){
            //add the transactions to the ready export
            _readyExports.push(_pendingExports);
            //clear the pending array
            delete _pendingExports;

            //prepare and push the exportSet
            pendingExportSet.sourceHeightStart = uint32(block.number);
            //add to the transactionSet Array
            readyExportSet.push(pendingExportSet);
            //add the block to the mapping
            readyExportsByBlock[block.number].push(_readyExports.length - 1);
            //hash the exportSet and add it to to the array for proof purposes
            _initializePendingExportSet();
            //emit an event       
            emit ExportsReady(_readyExports.length - 1);     
        }
        
    }

    /***
     * Import from Verus functions
     ***/
    function createImports(VerusObjects.CTransfer[] memory _newTransfers,
        VerusObjects.CTransferSet memory _newTransferSet,
        bytes32[] memory _transfersProof, 
        uint32 _blockHeight, 
        uint32 _hashIndex) public returns(bytes32){
        require(!deprecated,"Contract has been deprecated");
        //check the transaction has not already been processed
        
        //check that the transfers match the transfer set
        bytes32 hashedTransactions = verusProof.createHash(verusSerializer.serializeCTransfers(_newTransfers),verusKey);
        require(uint256(hashedTransactions) == _newTransferSet.hashReserveTransfer,"Hashed Transfers do not match those in the hashed Transfer set");
        
        //check the transaction is in the mmr contains the relevant hash
        //require(verusProof.proveTransferSet(_newTransferSet,_transfersProof,_blockHeight,_hashIndex),"Unable to prove transfer set");   

        //loop through the transactions and execute
        for(uint i = 0; i < _newTransfers.length; i++){
            //handle eth transactions
            if(_newTransfers[i].destCurrencyID == VEth) {
                //cast the destination as an ethAddress
                sendEth(_newTransfers[i].amount,payable(address(_newTransfers[i].destination.destination)));
                ethHeld -= _newTransfers[i].amount;
            } else {
                //handle erc20 transactions   
                tokenManager.importERC20Tokens(_newTransfers[i].destCurrencyID,
                    _newTransfers[i].amount,
                    _newTransfers[i].destination.destination);
            }
        }
        //add the hashedTransactions to allow for a lookup on processed 
        //??? need to check on what are the odds of the hash being the same for a transfer set

        processedImportSetHashes[hashedTransactions] = block.number;
        
    }
    

    /**
    returns a list of exports to be processed on the verus chain
    */
    
    function pendingExports() public view returns(VerusObjects.CTransfer[] memory){
        require(!deprecated,"Contract has been deprecated");
        return _pendingExports;
    }
    
    function getReadyExportsIndex() public view returns(uint){
        require(!deprecated,"Contract has been deprecated");
        return _readyExports.length - 1;
    }
    function getReadyExports(uint _eIndex) public view returns(VerusObjects.CTransfer[] memory){
        require(!deprecated,"Contract has been deprecated");
        return _readyExports[_eIndex];
    }

    VerusObjects.CTransfer[][] tempExports;
    function getReadyExportsByBlock(uint _blockNumber) public view returns(VerusObjects.CTransfer[][] memory){
        require(!deprecated,"Contract has been deprecated");
        //retrieve the bridge transactions
        uint[] memory eIndexes = readyExportsByBlock[_blockNumber];
        //loop through the array and add to the outgoing array
        VerusObjects.CTransfer[][] memory output = new VerusObjects.CTransfer[][](eIndexes.length);
        for(uint i = 0; i < eIndexes.length; i++){
            output[eIndexes[i]] = _readyExports[eIndexes[i]];
        }
        return output;
    }

    function getReadyExportsSetByBlock(uint _blockNumber) public view returns(VerusObjects.CTransferSet[] memory){
        require(!deprecated,"Contract has been deprecated");
        //retrieve the bridge transactions
        uint[] memory eIndexes = readyExportsByBlock[_blockNumber];
        //loop through the array and add to the outgoing array
        VerusObjects.CTransferSet[] memory output = new VerusObjects.CTransferSet[](eIndexes.length);
        for(uint i = 0; i < eIndexes.length; i++){
            output[eIndexes[i]] = readyExportSet[eIndexes[i]];
        }
        return output;
    }
    
    function sendEth(uint256 _ethAmount,address payable _ethAddress) private {
        require(!deprecated,"Contract has been deprecated");
        //do we take fees here????
        require(_ethAmount <= address(this).balance,"Requested amount exceeds contract balance");
        _ethAddress.transfer(_ethAmount);
    }
    
    function testSerializeCTransfer(VerusObjects.CTransfer memory testC) public view returns(bytes memory){
        return verusSerializer.serializeCTransfer(testC);
    }

    function testHashCTransfer(VerusObjects.CTransfer memory testC) public returns(bytes32){
         return verusProof.createHash(verusSerializer.serializeCTransfer(testC));
    }
    
    /**
    * deprecate current contract
    */
    function deprecate(address _upgradedAddress) public {
        require(msg.sender == contractOwner,"Only the contract owner can deprecate this contract");
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        Deprecate(_upgradedAddress);

    }

}
