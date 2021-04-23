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
    uint256 transactionFee = 100000000000000; //0.0001 eth
    //used to prove the transfers the index of this corresponds to the index of the 
    bytes32[] public readyExportHashes;
    //used to store a list of currencies and an amount
    
    VerusObjects.CReserveTransfer[] private _pendingExports;
    //the export set holds the summary of a set of exports
    VerusObjects.CReserveTransfer[][] private _readyExports;
    //used for proving the export set
    
    mapping (bytes32 => uint) public processedImportSetHashes;
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

    function exportETH(uint32 _destinationType,uint32 _flags,bool _preconvert,address _feeCurrencyID,uint160 _destination,uint256 _fees,uint160 _secondReserveID) public payable returns(uint256){
        require(!deprecated,"Contract has been deprecated");
        //calculate amount of eth to send
        require(msg.value > transactionFee,"Ethereum must be sent with the transaction to be sent to the Verus Chain");
        uint256 amount = msg.value - transactionFee;
        ethHeld += amount;
        feesHeld += transactionFee;
        //create a new Bridge Transaction
        
        VerusObjects.CTransferDestination memory transferDestination = VerusObjects.CTransferDestination(_destinationType,address(_destination)); 
        
        VerusObjects.CReserveTransfer memory newTransaction = VerusObjects.CReserveTransfer(
            1,
            VerusObjects.CCurrencyValueMap(VEth,uint64(amount)),
            _flags,
            _preconvert,
            _feeCurrencyID,
            _fees,
            address(VEth),
            transferDestination,
            VEth,
            _secondReserveID);
        _createExports(newTransaction);

        return amount;
    }

    //nFees and secondReserveID are used to send the tokens/eth on
    function exportERC20(uint64 _amount,address _tokenAddress,uint160 _destination,uint32 _destinationType,uint160 _destCurrencyID,uint32 _flags,uint256 _fees,address _feeCurrencyID,bool _preconvert,uint160 _secondReserveID) public payable {
        //check that they are not attempting to send Eth
        require(!deprecated,"Contract has been deprecated");
        require(msg.value >= transactionFee + uint64(_fees),"Please send the appropriate transaction fee.");
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
    
        VerusObjects.CTransferDestination memory transferDestination = VerusObjects.CTransferDestination(_destinationType,address(_destination)); 
        VerusObjects.CCurrencyValueMap memory currencyMap = VerusObjects.CCurrencyValueMap(_destCurrencyID,uint64(_amount));
        VerusObjects.CReserveTransfer memory newTransaction = VerusObjects.CReserveTransfer(
            1,
            currencyMap,
            _flags,
            _preconvert,
            _feeCurrencyID,
            _fees,
            address(_destCurrencyID),
            transferDestination,
            _destCurrencyID,
            _secondReserveID
        );
        //create the BridgeTransaction 
        _createExports(newTransaction);
    }

    function _createExports(VerusObjects.CReserveTransfer memory newTransaction) private {
        bytes32 hashedTransactions;

        _pendingExports.push(newTransaction);    
        //loop through the total amounts 
        
        //loop through the totalAmounts and append if the currency exists
        if(_pendingExports.length >= transactionsPerCall){
            //add the transactions to the ready export
            _readyExports.push(_pendingExports);
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
            if(uint160(_import.transfers[i].destinationcurrencyid) == uint160(VEth)) {
                //cast the destination as an ethAddress
                sendEth(_import.transfers[i].currencyvalues.amount,payable(address(_import.transfers[i].destination.destinationaddress)));
                ethHeld -= _import.transfers[i].currencyvalues.amount;
            } else {
                //handle erc20 transactions  
                tokenManager.importERC20Tokens(_import.transfers[i].destCurrencyID,
                    _import.transfers[i].currencyvalues.amount,
                    uint160(_import.transfers[i].destination.destinationaddress));
            }
            //handle the distributions of the fees
            //add them into the fees array to be claimed by the message sender
            if(_import.transfers[i].fees > 0 && _import.transfers[i].feecurrencyid == address(VEth)){
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
    
    function pendingExports() public view returns(VerusObjects.CReserveTransfer[] memory){
        require(!deprecated,"Contract has been deprecated");
        return _pendingExports;
    }
    
    function getReadyExportsIndex() public view returns(uint){
        require(!deprecated,"Contract has been deprecated");
        return _readyExports.length - 1;
    }

    function getReadyExports(uint _eIndex) public view returns(VerusObjects.CReserveTransfer[] memory){
        require(!deprecated,"Contract has been deprecated");
        return _readyExports[_eIndex];
    }
    
    
 /*   function getReadyExportsByRange(uint _startBlock,uint _endBlock) public view returns(VerusObjects.CReserveTransferSet[] memory){
        VerusObjects.CReserveTransferSet[] memory output;
        //if they are both 0 return the latest in the array
        uint tIndex = 0;
        if(_startBlock == 0 && _endBlock == 0) {
            output[tIndex] = VerusObjects.CReserveTransferSet(block.number,
            readyExportHashes[_readyExports.length-1],
            _readyExports.length-1,
            _readyExports[_readyExports.length-1]);
            return output;
            
        }
        //loop through the array of block heights and create an array of arrays
        uint[] memory transferIndexList;
        
        while(_startBlock <= _endBlock){
            if(readyExportsByBlock[_startBlock].length > 0){
                transferIndexList = readyExportsByBlock[_startBlock];
               //loop through and add create a CReserveTransferSet for each instance;
                for(uint i = 0; i < transferIndexList.length; i++){
                    //_readyExports[transferIndexList[i]]; //this is the export transfers
                    output[i] = VerusObjects.CReserveTransferSet(
                        _startBlock,
                        readyExportHashes[transferIndexList[i]],
                        transferIndexList[i],
                        _readyExports[transferIndexList[i]]);
                }
                tIndex++;
            }
            _startBlock++;
        }
        return output;        
    }*/

    function getReadyExportsByRange(uint _startBlock,uint _endBlock) public view returns(VerusObjects.CReserveTransfer[][] memory){
        require(!deprecated,"Contract has been deprecated");
        //may need to initialise this to be the summed length of the array
        VerusObjects.CReserveTransfer[][] memory output;
        uint[] memory eIndexes;
        for(uint processingBlock =_startBlock;processingBlock <= _endBlock;processingBlock++){
            eIndexes = readyExportsByBlock[processingBlock];
            for(uint i = 0; i < eIndexes.length; i++){
                output[eIndexes[i]] = _readyExports[eIndexes[i]];
            }
        }
        return output;
    }

    
    function getReadyExportsByBlock(uint _blockNumber) public view returns(VerusObjects.CReserveTransfer[][] memory){
        require(!deprecated,"Contract has been deprecated");
        //retrieve the bridge transactions
        uint[] memory eIndexes = readyExportsByBlock[_blockNumber];
        //loop through the array and add to the outgoing array
        VerusObjects.CReserveTransfer[][] memory output = new VerusObjects.CReserveTransfer[][](eIndexes.length);
        for(uint i = 0; i < eIndexes.length; i++){
            output[eIndexes[i]] = _readyExports[eIndexes[i]];
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

    /**
    * deprecate current contract
    */
    /*function deprecate(address _upgradedAddress,bytes32 _addressHash,bytes32[] memory _vs,bytes32[] memory _rs,bytes32[] memory _ss) public {
        require(verusNotarizer.isNotary(msg.sender),"Only a notary can deprecate this contract");
        bytes32 testingAddressHash = blake2b.createHash(_upgradedAddress);
        require(testingAddressHash == _addressHash,"Hashed address does not match address hash passed in");
        require(verusNotarizer.isNotarized(_addressHash, _rs, _ss, _vs),"Deprecation requires the address to be notarized");
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        Deprecate(_upgradedAddress);
    }*/

    function deprecate(address _upgradedAddress,bytes32 _addressHash,uint8[] memory _vs,bytes32[] memory _rs,bytes32[] memory _ss) public returns(address){
        if(verusNotarizer.notarizedDeprecation(_upgradedAddress, _addressHash, _vs, _rs, _ss)){
            deprecated = true;
            upgradedAddress = _upgradedAddress;
            Deprecate(_upgradedAddress);
        }
    }


}