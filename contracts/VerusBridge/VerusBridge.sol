// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./TokenManager.sol";
import "../MMR/MMRProof.sol";
import "../VerusNotarizer/VerusNotarizer.sol";
import { Memory } from "../Standard/Memory.sol";
import "./Token.sol";
import "./VerusSerializer.sol";

contract VerusBridge {
 
    //list of erc20 tokens that can be accessed,
    //the contract must be able to mint and burn coins on the contract
    //defines the tokenManager which creates the erc20
    TokenManager tokenManager;
    VerusNotarizer verusNotarizer;
    MMRProof mmrProof;
    VerusSerializer verusSerialize;

    //THE CONTRACT OWNER NEEDS TO BE REPLACED BY A SET OF NOTARIES
    address contractOwner;
    bool public deprecated = false; //indicates if the cotnract is deprecated
    address public upgradedAddress;

    uint256 public feesHeld = 0;
    uint256 public ethHeld = 0;

    bytes verusKey = "VerusDefaultHash";
    uint64 transactionsPerCall = 10;
    string VRSCEthTokenName = ".eth.";
    uint256 transactionFee = 100000000000000; //0.0001 eth


    //pending transactions array
    struct BridgeTransaction {
        uint32 flags; //type of transfer 0,
        address ethAddress; //ethereum destination address
        string RAddress; //verus destination address
        string tokenName; //destination currency id
        uint256 tokenAmount; //token amount
        uint256 fees; //network fees to be passed through
        string returnToken; //for use for conversion between;
    }

    struct CompletedTransaction{
        uint256 blockNumber;
        BridgeTransaction[] includedTransactions;
        bool completed;
    }

    BridgeTransaction[] private pendingOutboundTransactions;
    BridgeTransaction[][] private readyOutboundTransactions;
    //to allow for a singe proof for a block of transactions we generate a hash of the transactions in a block
    //that can then be retrieved and used as a single proof of the transactions
    bytes32[] private readyOutboundTransactionsHashes;

    mapping (bytes32 => CompletedTransaction) private completedInboundTransactions;
    event ReceivedFromVerus(BridgeTransaction transaction);
    event TransactionsReady(uint256 index);
    
    constructor(address notarizerAddress,address mmrAddress,address tokenManagerAddress) public {
        contractOwner = msg.sender;
        mmrProof =  MMRProof(mmrAddress);
        verusNotarizer = VerusNotarizer(notarizerAddress);
        tokenManager = TokenManager(tokenManagerAddress);
        //initialise the hash array
        readyOutboundTransactionsHashes.push(0x00);
        
    }

    function getTransactionsPerCall() public view returns(uint64){
        if(deprecated){
            newBridge = VerusBridge(upgradedAddress);
            return newBridge.getTransactionsPerCall();
        }
        return transactionsPerCall;
    }

    function sendEth(uint256 _ethAmount,address payable _ethAddress) private {
        require(!deprecated,"Contract has been deprecated");
        //do we take fees here????
        require(_ethAmount >= address(this).balance,"Requested amount exceeds contract balance");
        _ethAddress.transfer(_ethAmount);
    }

    function receiveFromVerusChain(BridgeTransaction[] memory _newTransactions, uint32 _hashIndex, bytes32[] memory _transactionsProof, uint32 _blockHeight) public returns(bytes32){   
        require(!deprecated,"Contract has been deprecated");
        //check the transaction has not already been processed
        bytes32 newTransactionHash = createTransactionsHash(_newTransactions);
        require(!completedInboundTransactions[newTransactionHash].completed ,"Transactions have been already processed");
        //check the transaction is in the mmr contains the relevant hash
        //require(confirmTransactionInMMR(_newTransactions,_hashIndex,_transactionsProof,_blockHeight) == true,"Transactions are not in the MMR root hash");
        
        //loop through the transactions and execute
        for(uint i = 0; i < _newTransactions.length; i++){
            if(keccak256(abi.encodePacked(_newTransactions[i].tokenName)) == keccak256(abi.encodePacked(VRSCEthTokenName))) {
                sendEth(_newTransactions[i].tokenAmount,payable(_newTransactions[i].ethAddress));
                ethHeld -= _newTransactions[i].tokenAmount;
            } else {
                tokenManager.sendERC20Tokens(_newTransactions[i].tokenName,_newTransactions[i].tokenAmount,_newTransactions[i].ethAddress);
            }
            
            //create an array in storage of transactions as memory cant be added to a storage array
            completedInboundTransactions[newTransactionHash].blockNumber = block.number;
            completedInboundTransactions[newTransactionHash].includedTransactions.push(_newTransactions[i]);
            emit ReceivedFromVerus(_newTransactions[i]);
        }

        return newTransactionHash;
        
    }

    function sendEthToVerus(string memory _RAddress) public payable returns(uint256){
        require(!deprecated,"Contract has been deprecated");
        //calculate amount of eth to send
        require(msg.value > transactionFee,"Ethereum must be sent with the transaction to be sent to the Verus Chain");
        uint256 amount = msg.value - transactionFee;
        ethHeld += amount;
        feesHeld += transactionFee;
        _addOutboundTransaction(VRSCEthTokenName,amount,_RAddress);
        return amount;
    }

    function sendERC20ToVerus(string memory _tokenName, uint256 _tokenAmount, string memory _RAddress) public payable {
        require(!deprecated,"Contract has been deprecated");
        require(msg.value >= transactionFee,"Please send the appropriate transacion fee.");
        require(keccak256(abi.encodePacked(_tokenName)) != keccak256(abi.encodePacked(VRSCEthTokenName)),"To send eth use sendEthToVerus");
        feesHeld += msg.value;
        //claim fees
        _sendToVerus(_tokenName,_tokenAmount,_RAddress);
    }

    function _sendToVerus(string memory _tokenName, uint256 _tokenAmount, string memory _RAddress) private {
        
        //if the tokens have been approved for VerusBridge, approve the tokenManager contract to transfer them over
        address tokenAddress = tokenManager.getTokenAddress(_tokenName);
        Token token = Token(tokenAddress);
        uint256 allowedTokens = token.allowance(msg.sender,address(this));
        require( allowedTokens >= _tokenAmount,"This contract must have an allowance of greater than or equal to the number of tokens");
        //transfer the tokens to this contract
        token.transferFrom(msg.sender,address(this),_tokenAmount); 
        token.approve(address(tokenManager),_tokenAmount);  
        //give an approval for the tokenmanagerinstance to spend the tokens
        tokenManager.receiveERC20Tokens(_tokenName,_tokenAmount);
        pendingOutboundTransactions.push(BridgeTransaction(0,address(0),_RAddress,_tokenName,_tokenAmount,0,""));
        //create a hash of the transaction values and add that to the last value 
        //of the readyOutboundTransactionsHashes;
        _addOutboundTransaction(_tokenName,_tokenAmount,_RAddress);
    }

    function _addOutboundTransaction(string memory _tokenName,uint256 _tokenAmount,string memory _RAddress) private {
        readyOutboundTransactionsHashes[readyOutboundTransactionsHashes.length - 1] = 
            keccak256(abi.encodePacked(readyOutboundTransactionsHashes[readyOutboundTransactionsHashes.length - 1],_tokenName,_tokenAmount,_RAddress));
        if(pendingOutboundTransactions.length >= transactionsPerCall){
            //move the array to readyOutboundTransactions
            readyOutboundTransactions.push(pendingOutboundTransactions);
            readyOutboundTransactionsHashes.push(0x00);
            delete pendingOutboundTransactions;
            emit TransactionsReady(readyOutboundTransactions.length - 1);
        }
    }

    /**
    returns a list of transactions to be processed on the verus chain
    */
    
    function outboundTransactionsIndex() public view returns(uint){
        require(!deprecated,"Contract has been deprecated");
        return readyOutboundTransactions.length;
    }

    function getTransactionsHash(uint _tIndex) public view returns(bytes32){
        require(!deprecated,"Contract has been deprecated");
        return readyOutboundTransactionsHashes[_tIndex];
    }

    function getTransactionsToProcess(uint _tIndex) public view returns(BridgeTransaction[] memory){
        require(!deprecated,"Contract has been deprecated");
        return readyOutboundTransactions[_tIndex];
    }

    function getPendingOutboundTransactions() public view returns(BridgeTransaction[] memory){
        require(!deprecated,"Contract has been deprecated");
        return pendingOutboundTransactions;
    }

    function getCompletedInboundTransaction(bytes32 transactionHash) public view returns(CompletedTransaction memory){
        require(!deprecated,"Contract has been deprecated");
        return completedInboundTransactions[transactionHash];
    }

    /**
    deploy a new token
     */
    function createToken(string memory verusAddress,string memory ticker) public returns(address){
        require(!deprecated,"Contract has been deprecated");
        return tokenManager.deployNewToken(verusAddress,ticker);
    }


    function confirmTransactionInMMR(BridgeTransaction[] memory _newTransactions, 
        uint32 _hashIndex,
        bytes32[] memory _transactionsProof,
        uint32 _blockHeight) private returns(bool){
        require(!deprecated,"Contract has been deprecated");
        //loop through the transactions and create a hash of the list
        bytes32 hashedTransactions = createTransactionsHash(_newTransactions);
        //get the mmrRoot relating to the blockheight from the notarized data
        VerusNotarizer.NotarizedData memory verusNotarizedData = verusNotarizer.getNotarizedData(_blockHeight);
        bytes32 mmrRootHash = bytes32(verusNotarizedData.mmrRoot);
        //check the proof and return the result
        if (mmrRootHash == mmrProof.predictedRootHash(hashedTransactions,_hashIndex,_transactionsProof)) return true;
        else return false;
    }

    function createTransactionsHash(BridgeTransaction[] memory _newTransactions) public returns(bytes32){
        require(!deprecated,"Contract has been deprecated");
        bytes memory serializedTransactions = serializeTransactions(_newTransactions);
        //convert to bytes for hashing

        bytes32 hashedTransactions = mmrProof.createHash(serializedTransactions,verusKey);
        return hashedTransactions;
    }


    function serializeTransaction(BridgeTransaction memory _sendTransaction) public view returns(bytes memory){
        require(!deprecated,"Contract has been deprecated");
        bytes memory serializedTransaction = abi.encodePacked(
            verusSerialize.serializeAddress(_sendTransaction.ethAddress),
            verusSerialize.serializeString(_sendTransaction.RAddress),
            verusSerialize.serializeString(_sendTransaction.tokenName),
            verusSerialize.serializeUint256(_sendTransaction.tokenAmount));
        return serializedTransaction;
    }

    function serializeTransactions(BridgeTransaction[] memory _newTransactions) public view returns(bytes memory){
        require(!deprecated,"Contract has been deprecated");
        bytes memory serializedTransactions;
        bytes memory serializedTransaction;
        for(uint i = 0; i < _newTransactions.length; i++){
            serializedTransaction = serializeTransaction(_newTransactions[i]);
            if(serializedTransactions.length > 0) serializedTransactions = concat(serializedTransaction,serializedTransaction);
            else serializedTransactions = serializedTransaction;
        }
        return serializedTransactions;
    }


    function mmrHash(bytes memory toHash,bytes memory hashKey) public returns(bytes32){
        require(!deprecated,"Contract has been deprecated");
        bytes32 generatedHash = mmrProof.createHash(toHash,hashKey,false);
        return generatedHash;
    }

    function getTokenAddress(string memory tokenName) public view returns(address){
        require(!deprecated,"Contract has been deprecated");
        return tokenManager.getTokenAddress(tokenName);
    }

    function getTokenName(address tokenAddress) public view returns(string memory){
        require(!deprecated,"Contract has been deprecated");
        return tokenManager.getTokenName(tokenAddress);
    }

    /**
    * deprecate current contract
    */
    function deprecate(address _upgradedAddress) {
        require(msg.sender == contractOwner,"Only the contract owner can deprecate this contract");
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        Deprecate(_upgradedAddress);

    }

}
