// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.4.21 <0.7.0;

import "../../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Factory.sol";
import "../MMR/MMRProof.sol";
import "../VerusNotarizer/VerusNotarizer.sol";

contract verusBridge {

    
    //list of erc20 tokens that can be accessed,
    //the contract must be able to mint and burn coins on the contract
    //list of addresses allowed to execute transactions
    address[] private permittedAddresses;
    //defines the factory which creates the erc20
    Factory factory;
    VerusNotarizer verusNotarizer;
    MMRProof mmrProof;

    //pending transactions array
    struct BridgeTransaction {
        address targetAddress;
        string tokenName;
        uint64 tokenAmount;
    }

    struct CompletedTransaction{
        uint256 blockNumber;
        SendTransaction[] includedTransactions;
    }

    BridgeTransaction[] private pendingOutboundTransactions;
    BridgeTransaction[][10] private readyOutboundTransactions;

    mapping (bytes32 => completedTransaction) private completedInboundTransactions;

    constructor(address notarizerAddress) public {
        verusNotarizer = VerusNotarizer(notarizerAddress);
    }

    function receiveFromVerusChain(BridgeTransaction[] memory _newTransactions, uint32 _hashIndex, MMRProof memory _transactionsProof, uint _blockHeight) public {
        
        //check the transaction has not already been processed
        bytes32 newTransactionHash = createTransactionsHash(_newTransactions);
        require(completeInboundTransactions[newTransactionHash] != 0,"Transactions have been already processed");
        //check the transaction is in the mmr contains the relevant hash
        require(confirmTransactionInMMR(_newTransactions,_hashIndex,_transactionsProof,_blockHeight) == true,"Transactions are not in the MMR root hash");
        
        //loop through the transactions and execute
        for(uint i = 0; i < _newTransactions.length; i++){
            factory.mintToken(_newTransactions[i].tokenName,_newTransactions[i].tokenAmount,_newTransactions[i].targetAddress);
        }
        completedInboundTransactions[newTransactionHash] = CompletedTransaction(block.number,_newTransactions);

    }

    function sendToVerus(string memory _tokenName, uint _tokenAmount, address _targetAddress) public {
        
        //call the burn of the amount
        //add to pending transactions array
        //need to check that
        factory.burnToken(_tokenName,_tokenAmount);
        pendingOutboundTransactions.push(BridgeTransaction(_targetAddress,_tokenName,_tokenAmount));
        if(pendingOutboundTransaction.length == 10){
            //move the array to readyOutboundTransactions and 
            readyOutboundTransaction.push(pendingOutboundTransactions);
            pendingOutboundTransaction = [];
        }
    }

    /**
    returns a list of transactions to be processed on the verus chain
    */
    function outboundTransactionsIndex() public pure returns(uint){
        return readyOutboundTransactions.length;
    }

    function transactionsToProcess(uint _tIndex) public returns(BridgeTransactions[10]){
        return readyOutboundTransaction[_tIndex];
    }


    /**
    deploy a new token
     */
    function createToken(string memory verusAddress,string memory ticker) public{
        factory.deployNewToken(verusAddress,ticker);
    }

    function confirmTransactionInMMR(BridgeTransaction[] memory _newTransactions, 
        uint32 _hashIndex,
        bytes32[] memory _transactionsProof,
        uint _blockHeight) private returns(bool){
        
        //loop through the transactions and create a hash of the list
        bytes32 hashedTransactions = createTransactionsHash(_newTransactions);
        //get the mmrRoot relating to the blockheight from the notarized data
        NotarizedData verusNotarizedData = verusNotarizer.getNotarizedData(_blockHeight);
        bytes32 mmrRootHash = bytes32(verusNotarizedData.mmrRoot);
        //check the proof and return the result
        return mmrProof.predictedRootHash(mmrRootHash,hashedTransactions,_hashIndex,_transactionsProof);
        
    }

    function createTransactionsHash(BrdigeTransaction[] _newTransactions) private returns(bytes){
        bytes serializedTransactions = serializeTransactions(_newTransactions);
        bytes32 hashedTransactions = mmrProof.createHash(serializedTransactions);
        return hashedTransactions;
    }
    
    function serializeTransactions(BridgeTransaction[] _newTransactions) private returns(bytes){
        bytes serializedTransactions;
        bytes serializeTransaction;
        for(uint i = 0; i < _newTransactions.length; i++){
            serializedTransaction = serializeTransaction(_newTransactions[i]);
            serializedTransactions = concat(serializedTransactions,serializedTransaction);
        }
        return serializedTransactions;
    }

    function serializeTransaction(BridgeTransaction _sendTransation) private returns(bytes){
        bytes serializedTransaction = abi.encodePacked(_newTransactions[i].targetAddress,_newTransactions[i].tokenName,_newTransactions[i].tokenAmount);
        return serializedTransaction
    }

    /** bytes concat helper function */
    function concat(bytes memory self, bytes memory other) private returns (bytes memory) {
        bytes memory ret = new bytes(self.length + other.length);
        var (src, srcLen) = Memory.fromBytes(self);
        var (src2, src2Len) = Memory.fromBytes(other);
        var (dest,) = Memory.fromBytes(ret);
        var dest2 = dest + src2Len;
        Memory.copy(src, dest, srcLen);
        Memory.copy(src2, dest2, src2Len);
     return ret;
}

}
