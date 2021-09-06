// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./TokenManager.sol";
import "../MMR/VerusProof.sol";
import "../MMR/VerusBLAKE2b.sol";
import "./Token.sol";
import "./VerusObjects.sol";
import "./VerusSerializer.sol";
import "../VerusNotarizer/VerusNotarizer.sol";
import "./VerusCrossChainExport.sol";

contract VerusBridge {

    //list of erc20 tokens that can be accessed,
    //the contract must be able to mint and burn coins on the contract
    //defines the tokenManager which creates the erc20
    TokenManager tokenManager;
    VerusSerializer verusSerializer;
    VerusProof verusProof;
    VerusBLAKE2b blake2b;
    VerusNotarizer verusNotarizer;
    VerusCrossChainExport verusCCE;

    //THE CONTRACT OWNER NEEDS TO BE REPLACED BY A SET OF NOTARIES
    address contractOwner;
    bool public deprecated = false; //indicates if the cotnract is deprecated
    address public upgradedAddress;
    uint256 public feesHeld = 0;
    uint256 public ethHeld = 0;
    uint256 public poolSize = 0;
    uint public firstBlock = 0;

    //used to prove the transfers the index of this corresponds to the index of the 
    bytes32[] public readyExportHashes;
    //DO NOT ADD ANY VARIABLES ABOVE THIS POINT
    //used to store a list of currencies and an amount
    VerusObjects.CReserveTransfer[] private _pendingExports;
    
    //stores the blockheight of each pending transfer
    //the export set holds the summary of a set of exports
    VerusObjects.CReserveTransfer[][] public _readyExports;
    
    //stores the index corresponds to the block
    
    mapping (uint => VerusObjects.blockCreated) public readyExportsByBlock;
    mapping (address => uint256) public claimableFees;
    
    VerusObjects.infoDetails chainInfo;
    
    bytes[] public SerializedCRTs;
    bytes[] public SerializedCCEs;
    bytes32[] public hashedCRTs;
    
    //event ReceivedTransfer(VerusObjects.CReserveTransfer transaction);
    //event ExportsReady(uint256 index);
    event Deprecate(address newAddress);
    
    constructor(address verusProofAddress,
        address tokenManagerAddress,
        address verusSerializerAddress,
        address verusBLAKE2bAddress,
        address verusNotarizerAddress,
        address verusCCEAddress,
        uint chainVersion,
        string memory chainVerusVersion,
        string memory chainName,
        bool chainTestnet,
        uint256 _poolSize) public {
        contractOwner = msg.sender; 
        verusProof =  VerusProof(verusProofAddress);
        tokenManager = TokenManager(tokenManagerAddress);
        verusSerializer = VerusSerializer(verusSerializerAddress);
        blake2b = VerusBLAKE2b(verusBLAKE2bAddress);
        verusNotarizer = VerusNotarizer(verusNotarizerAddress);
        verusCCE = VerusCrossChainExport(verusCCEAddress);
        chainInfo.version = chainVersion;
        chainInfo.VRSCversion = chainVerusVersion;
        chainInfo.name = chainName;
        chainInfo.testnet = chainTestnet;
        poolSize = _poolSize;
    }

    function getinfo() public view returns(VerusObjects.infoDetails memory){
        //set blocks
        VerusObjects.infoDetails memory returnInfo;
        returnInfo.version = chainInfo.version;
        returnInfo.VRSCversion = chainInfo.VRSCversion;
        returnInfo.blocks = block.number;
        returnInfo.tiptime = block.timestamp;
        returnInfo.name = chainInfo.name;
        returnInfo.testnet = chainInfo.testnet;
        return returnInfo;
    }

    function getcurrency(address _currencyid) public view returns(VerusObjects.currencyDetail memory){
        VerusObjects.currencyDetail memory returnCurrency;
        returnCurrency.version = chainInfo.version;
        //if the _currencyid is null then return VEth
        address[] memory notaries = verusNotarizer.getNotaries();
        uint8 minnotaries = verusNotarizer.currentNotariesRequired();
        if(_currencyid == VerusObjects.VEth){
            returnCurrency = VerusObjects.currencyDetail(
                chainInfo.version,
                VerusObjects.currencyName,
                VerusObjects.VEth,
                VerusObjects.VerusSystemId,
                VerusObjects.VerusSystemId,
                2,
                3,
                VerusObjects.CTransferDestination(9,VerusObjects.VEth),
                VerusObjects.VerusSystemId,
                0,
                0,
                72000000,
                72000000,
                VerusObjects.VEth,
                notaries,
                minnotaries
            );
        } else {
            //look up the erc20 in token manager
            Token token = Token(address(_currencyid));
            
            returnCurrency = VerusObjects.currencyDetail(
                chainInfo.version,
                token.name(),
                _currencyid,
                VerusObjects.VerusSystemId,
                VerusObjects.VerusSystemId,
                2,
                3,
                VerusObjects.CTransferDestination(9,_currencyid),
                VerusObjects.VerusSystemId,
                0,
                0,
                0,
                0,
                VerusObjects.VEth,
                notaries,
                minnotaries
            );
        }
        return returnCurrency;
    }

    function isPoolAvailable(uint256 _feesAmount,address _feeCurrencyID) private view returns(bool){
        if(verusNotarizer.numNotarizedBlocks() >= 1) {
            //the bridge has been activated
            return false;
        } else {
            require(_feeCurrencyID == VerusObjects.VerusCurrencyId,"Bridge is not yet available only Verus can be used for fees");
            require(poolSize > _feesAmount,"Bridge is not yet available fees cannot exceed existing pool.");
            return true;
        }
    }

    function convertToVerusNumber(uint256 a) public pure returns (uint64) {
        uint256 c = a / 10000000000;
        return uint64(c);
    }

    function exportETH(address _destination,uint8 _destinationType,address _feeCurrencyID,uint256 _nFees,address _destSystemID) public payable returns(uint256){
        require(!deprecated,"Contract has been deprecated");
        //calculate amount of eth to send
        require(msg.value > VerusObjects.transactionFee,"Ethereum must be sent with the transaction to be sent to the Verus Chain");
        
        uint256 amount = msg.value - VerusObjects.transactionFee;
        ethHeld += amount;
        feesHeld += VerusObjects.transactionFee;
        //create a new Bridge Transaction
         
        _createExports(convertToVerusNumber(amount), address(VerusObjects.VEth), _destination,_destinationType, VerusObjects.VerusSystemId, _nFees, _feeCurrencyID, _destSystemID);

        return amount;
    }


    //nFees and secondReserveID are used to send the tokens/eth on
    function exportERC20(uint64 _amount,address _tokenAddress,address _destination,uint8 _destinationType,address _destCurrencyID,uint256 _nFees,address _feeCurrencyID,address _destSystemID) public payable {
        //check that they are not attempting to send Eth
        require(!deprecated,"Contract has been deprecated");
        require(msg.value >= VerusObjects.transactionFee + uint64(_nFees),"Please send the appropriate transaction fee.");
        require(_destination != VerusObjects.VEth,"To send eth use exportETH");
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

        //create the BridgeTransaction 
        _createExports(_amount,_tokenAddress,_destination,_destinationType,_destCurrencyID,_nFees,_feeCurrencyID,_destSystemID);
    }

    function _createExports(uint64 _amount,address _tokenAddress,address _destination,uint8 _destinationType,address _destCurrencyID,uint256 _nFees,address _feeCurrencyID,address _destSystemID) private {
        uint currentHeight = block.number;
        uint exportIndex;
        bool newHash;

        uint32 flags = 65;
        VerusObjects.CTransferDestination memory transferDestination = VerusObjects.CTransferDestination(_destinationType,_destination);
        VerusObjects.CCurrencyValueMap memory currencyvalues = VerusObjects.CCurrencyValueMap(_tokenAddress,_amount);
        VerusObjects.CReserveTransfer memory newTransaction = VerusObjects.CReserveTransfer(
            1,//force to be a signle value in the currencyvalue
            currencyvalues,
            flags,
            _feeCurrencyID,
            _nFees,
            transferDestination,
            _destCurrencyID,
            _destSystemID);


        //if there is fees in the pool spend those and not the amount that
        if(isPoolAvailable(newTransaction.fees,newTransaction.feecurrencyid)) {
            poolSize -= newTransaction.fees;
        }

        //check if the current block height has a set of transfers associated with it if so add to the existing array
        if(readyExportsByBlock[currentHeight].created) {
            //append to an existing array of transfers
            exportIndex = readyExportsByBlock[currentHeight].index;
            _readyExports[exportIndex].push(newTransaction);
            newHash = false;
        }
        else {
            _pendingExports.push(newTransaction);
            _readyExports.push(_pendingExports);
            exportIndex = _readyExports.length - 1;
            readyExportsByBlock[currentHeight] = VerusObjects.blockCreated(exportIndex,true);
            delete _pendingExports;
            newHash = true;
        }
       
        //create a cross chain export, serialize it and hash it
        
        VerusObjects.CCrossChainExport memory CCCE = verusCCE.generateCCE(_readyExports[exportIndex]);
        //create a hash of the CCCE
        
        bytes memory serializedCCE = verusSerializer.serializeCCrossChainExport(CCCE);
        
        bytes memory serializedTransfers = verusSerializer.serializeCReserveTransfers(_readyExports[exportIndex],false);
        SerializedCRTs.push(serializedTransfers);
        bytes32 hashedTransfers = keccak256(serializedTransfers);
        bytes memory toHash = abi.encodePacked(serializedCCE,serializedTransfers);
        SerializedCCEs.push(toHash);
        hashedCRTs.push(hashedTransfers);
        bytes32 hashedCCE = keccak256(abi.encodePacked(serializedCCE,serializedTransfers));
        
        //add the hashed value
        if(newHash) readyExportHashes.push(hashedCCE);
        else readyExportHashes[exportIndex] = hashedCCE;
        if(firstBlock == 0) firstBlock = currentHeight;
        
    }
    
    function testCCE(uint exportIndex) public returns(bytes memory){
        VerusObjects.CCrossChainExport memory CCCE = verusCCE.generateCCE(_readyExports[exportIndex]);
        //create a hash of the CCCE
        
        bytes memory serializedCCE = verusSerializer.serializeCCrossChainExport(CCCE);
        
        bytes memory serializedTransfers = verusSerializer.serializeCReserveTransfers(_readyExports[exportIndex],false);
        return abi.encodePacked(serializedCCE,serializedTransfers);
    }
    
    function testCCE2(uint exportIndex) public view returns(bytes memory){
        bytes memory serializedTransfers = verusSerializer.serializeCReserveTransfers(_readyExports[exportIndex],false);
        return serializedTransfers;
    }

    /***
     * Import from Verus functions
     ***/
     

    function submitImports(VerusObjects.CReserveTransferImport[] memory _imports) public {
        //loop through the transfers and process
        for(uint i = 0; i < _imports.length; i++){
            _createImports(_imports[i]);
        }
    }

    function _createImports(VerusObjects.CReserveTransferImport memory _import) private returns(bool){
        //TO DO
        //prove the transaction
        //require(verusProof.proveTransaction(_import.txid,_import.partialtransactionproof,_import.txoutnum,_import.height));
        //check the transfers were in the hash.
        for(uint i = 0; i < _import.transfers.length; i++){
            //handle eth transactions
            if(_import.transfers[i].destcurrencyid == VerusObjects.VEth) {
                //cast the destination as an ethAddress
                
                    sendEth(_import.transfers[i].currencyvalue.amount,payable(address(_import.transfers[i].destination.destinationaddress)));
                    ethHeld -= _import.transfers[i].currencyvalue.amount;
        
            } else {
                //handle erc20 transactions   
                tokenManager.importERC20Tokens(_import.transfers[i].destcurrencyid,
                    _import.transfers[i].currencyvalue.amount,
                    _import.transfers[i].destination.destinationaddress);
            }
            //handle the distributions of the fees
            //add them into the fees array to be claimed by the message sender
            if(_import.transfers[i].fees > 0 && _import.transfers[i].feecurrencyid == VerusObjects.VEth){
                claimableFees[msg.sender] = claimableFees[msg.sender] + _import.transfers[i].fees;
            }
            //could there be a scenario where more fees are paid here than there are funds for
            //if its a create token situation how do we handle that
            //probably best to just allow tokens to be created as a seperate operation
        }
        return true;
    }
    
    function getReadyExportsByBlock(uint _blockNumber) public view returns(VerusObjects.CReserveTransferSet memory){
        //need a transferset for each position not each block
        //retrieve a block get the indexes, create a transfer set for each index add those to the array
        uint eIndex = readyExportsByBlock[_blockNumber].index;
        VerusObjects.CReserveTransferSet memory output = VerusObjects.CReserveTransferSet(
            eIndex, //position in array
            _blockNumber, //blockHeight
            //readyExportHashes[eIndex],
            hashedCRTs[eIndex],
            _readyExports[eIndex]
        );
        return output;
    }


    
    function getReadyExportsByRange(uint _startBlock,uint _endBlock) public view returns(VerusObjects.CReserveTransferSet[] memory){
        //calculate the size that the return array will be to initialise it
        uint outputSize = 0;
        if(_startBlock < firstBlock) _startBlock = firstBlock;
        for(uint i = _startBlock; i <= _endBlock; i++){
            if(readyExportsByBlock[i].created) outputSize += 1;
        }

        VerusObjects.CReserveTransferSet[] memory output = new VerusObjects.CReserveTransferSet[](outputSize);
        uint outputPosition = 0;
        for(uint blockNumber = _startBlock;blockNumber <= _endBlock;blockNumber++){
            if(readyExportsByBlock[blockNumber].created) {
                output[outputPosition] = getReadyExportsByBlock(blockNumber);
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
/*
    function deprecate(address _upgradedAddress,bytes32 _addressHash,uint8[] memory _vs,bytes32[] memory _rs,bytes32[] memory _ss) public{
        if(verusNotarizer.notarizedDeprecation(_upgradedAddress, _addressHash, _vs, _rs, _ss)){
            deprecated = true;
            upgradedAddress = _upgradedAddress;
            Deprecate(_upgradedAddress);
        }
    }*/


}
