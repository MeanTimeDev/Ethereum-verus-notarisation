// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./TokenManager.sol";
import "../MMR/MMRProof.sol";
import "../VerusNotarizer/VerusNotarizer.sol";
import { Memory } from "../Standard/Memory.sol";
import "./Token.sol";

contract VerusBridge {
 
    //list of erc20 tokens that can be accessed,
    //the contract must be able to mint and burn coins on the contract
    //list of addresses allowed to execute transactions
    address[] private permittedAddresses;
    //defines the tokenManager which creates the erc20
    TokenManager tokenManager;
    VerusNotarizer verusNotarizer;
    MMRProof mmrProof;
    bytes verusKey = "VerusDefaultHash";

    //pending transactions array
    struct BridgeTransaction {
        address targetAddress;
        string tokenName;
        uint256 tokenAmount;
    }

    struct CompletedTransaction{
        uint256 blockNumber;
        BridgeTransaction[] includedTransactions;
        bool completed;
    }

    BridgeTransaction[] private pendingOutboundTransactions;
    BridgeTransaction[][] private readyOutboundTransactions;

    mapping (bytes32 => CompletedTransaction) private completedInboundTransactions;
    event ReceivedFromVerus(BridgeTransaction transaction);

    constructor(address notarizerAddress,address mmrAddress,address tokenManagerAddress) public {
        mmrProof =  MMRProof(mmrAddress);
        verusNotarizer = VerusNotarizer(notarizerAddress);
        tokenManager = TokenManager(tokenManagerAddress);
        
    }

    function receiveFromVerusChain(BridgeTransaction[] memory _newTransactions, uint32 _hashIndex, bytes32[] memory _transactionsProof, uint32 _blockHeight) public returns(bytes32){
        
        //check the transaction has not already been processed
        bytes32 newTransactionHash = createTransactionsHash(_newTransactions);
        require(!completedInboundTransactions[newTransactionHash].completed ,"Transactions have been already processed");
        //check the transaction is in the mmr contains the relevant hash
        //require(confirmTransactionInMMR(_newTransactions,_hashIndex,_transactionsProof,_blockHeight) == true,"Transactions are not in the MMR root hash");
        
        //loop through the transactions and execute
        for(uint i = 0; i < _newTransactions.length; i++){
            tokenManager.sendERC20Tokens(_newTransactions[i].tokenName,_newTransactions[i].tokenAmount,_newTransactions[i].targetAddress);
            //create an array in storage of transactions as memory cant be added to a storage array
            completedInboundTransactions[newTransactionHash].blockNumber = block.number;
            completedInboundTransactions[newTransactionHash].includedTransactions.push(_newTransactions[i]);
            emit ReceivedFromVerus(_newTransactions[i]);
        }

        return newTransactionHash;
        
    }

    function sendToVerus(string memory _tokenName, uint256 _tokenAmount, address _targetAddress) public {
        
        //check if the token is registered, i should really use the contract address and do a lookup on it
        
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
        pendingOutboundTransactions.push(BridgeTransaction(_targetAddress,_tokenName,_tokenAmount));
        if(pendingOutboundTransactions.length >= 10){
            //move the array to readyOutboundTransactions and 
            readyOutboundTransactions.push(pendingOutboundTransactions);
            delete pendingOutboundTransactions;
        }
    }

    /**
    returns a list of transactions to be processed on the verus chain
    */

    
    
    function outboundTransactionsIndex() public view returns(uint){
        return readyOutboundTransactions.length;
    }

    function getTransactionsToProcess(uint _tIndex) public view returns(BridgeTransaction[] memory){
        return readyOutboundTransactions[_tIndex];
    }

    function getPendingOutboundTransactions() public view returns(BridgeTransaction[] memory){
        return pendingOutboundTransactions;
    }

    function getCompletedInboundTransaction(bytes32 transactionHash) public view returns(CompletedTransaction memory){
        return completedInboundTransactions[transactionHash];
    }

    /**
    deploy a new token
     */
    function createToken(string memory verusAddress,string memory ticker) public returns(address){
        return tokenManager.deployNewToken(verusAddress,ticker);
    }


    function confirmTransactionInMMR(BridgeTransaction[] memory _newTransactions, 
        uint32 _hashIndex,
        bytes32[] memory _transactionsProof,
        uint32 _blockHeight) private returns(bool){
        
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
        bytes memory serializedTransactions = serializeTransactions(_newTransactions);
        bytes32 hashedTransactions = mmrProof.createHash(serializedTransactions,verusKey);
        return hashedTransactions;
    }
    
    function serializeTransactions(BridgeTransaction[] memory _newTransactions) public pure returns(bytes memory){
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
        bytes32 generatedHash = mmrProof.createHash(toHash,hashKey);
        return generatedHash;
    }

    function serializeTransaction(BridgeTransaction memory _sendTransaction) public pure returns(bytes memory){
        bytes memory serializedTransaction = abi.encodePacked(_sendTransaction.targetAddress,_sendTransaction.tokenName,_sendTransaction.tokenAmount);
        return serializedTransaction;
    }

    function getTokenAddress(string memory tokenName) public view returns(address){
        return tokenManager.getTokenAddress(tokenName);
    }

    function getTokenName(address tokenAddress) public view returns(string memory){
        return tokenManager.getTokenName(tokenAddress);
    }
    


    /** bytes concat helper function */
    function concat(bytes memory self, bytes memory other) public pure returns (bytes memory) {
        bytes memory ret = new bytes(self.length + other.length);
        
        (uint256 src, uint256 srcLen) = Memory.fromBytes(self);
        (uint256 src2, uint256 src2Len) = Memory.fromBytes(other);
        (uint256 dest,) = Memory.fromBytes(ret);
        uint256 dest2 = dest + src2Len;
        Memory.copy(src, dest, srcLen);
        Memory.copy(src2, dest2, src2Len);
     return ret;
    }

}
