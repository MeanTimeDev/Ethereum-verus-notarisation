// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.9.0;
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
    
    VerusObjects.CCrossChainExport[] public readyCCEs;
    
    
    mapping (bytes32 => uint) public processedImportSetHashes;
    //stores the index corresponds to the block
    
    struct blockCreated {
        uint index;
        bool created;
    }
    
    mapping (uint => blockCreated) public readyExportsByBlock;
    mapping (address => uint256) public claimableFees;
    
    event ReceivedTransfer(VerusObjects.CReserveTransfer transaction);
    event ExportsReady(uint256 index);
    event Deprecate(address newAddress);
    event CrossChainExport(VerusObjects.CCrossChainExport CCE);
    
    constructor(address verusProofAddress,
        address tokenManagerAddress,
        address verusSerializerAddress,
        address verusBLAKE2bAddress,
        address verusNotarizerAddress,
        address verusCCEAddress) public {
        contractOwner = msg.sender; 
        verusProof =  VerusProof(verusProofAddress);
        tokenManager = TokenManager(tokenManagerAddress);
        verusSerializer = VerusSerializer(verusSerializerAddress);
        blake2b = VerusBLAKE2b(verusBLAKE2bAddress);
        verusNotarizer = VerusNotarizer(verusNotarizerAddress);
        verusCCE = VerusCrossChainExport(verusCCEAddress);
    }

    function exportETH(uint160 _destination,uint256 _nFees,uint160 _secondReserveID,uint160 _destSystemID) public payable returns(uint256){
        require(!deprecated,"Contract has been deprecated");
        //calculate amount of eth to send
        require(msg.value > transactionFee,"Ethereum must be sent with the transaction to be sent to the Verus Chain");
        uint256 amount = msg.value - transactionFee;
        ethHeld += amount;
        feesHeld += transactionFee;
        //create a new Bridge Transaction
        uint160 feeCurrencyID = 0;
        VerusObjects.CTransferDestination memory transferDestination = VerusObjects.CTransferDestination(1,_destination); 
        VerusObjects.CCurrencyValueMap memory currencyvalue = VerusObjects.CCurrencyValueMap(VEth,uint64(amount));
        _createExports(currencyvalue,feeCurrencyID,_nFees,transferDestination,VEth,_secondReserveID,_destSystemID);

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

        uint160 feeCurrencyID = 0;
        VerusObjects.CTransferDestination memory transferDestination = VerusObjects.CTransferDestination(1,_destination);
        VerusObjects.CCurrencyValueMap memory currencyvalue = VerusObjects.CCurrencyValueMap(uint160(_tokenAddress),_amount);
        _createExports(currencyvalue,feeCurrencyID,_nFees,transferDestination,_destCurrencyID,_secondReserveID,_destSystemID);
    }
    
    VerusObjects.CReserveTransfer tempCRT;


    //function _createExports(VerusObjects.CReserveTransfer memory newTransaction) private {
    function _createExports(VerusObjects.CCurrencyValueMap memory _currencyvalue,
        uint160 _feeCurrencyID,
        uint256 _fees,
        VerusObjects.CTransferDestination memory _transferDestination,
        uint160 _destCurrencyID,
        uint160 _secondReserveID,
        uint160 _destSystemID
    ) private {
        uint currentHeight = block.number;
        uint exportIndex;
        bool newHash;
        uint32 flags = 0;
        
        tempCRT.version = 1;
        tempCRT.currencyvalues.push(_currencyvalue);
        tempCRT.flags = flags;
        tempCRT.feecurrencyid = _feeCurrencyID;
        tempCRT.fees = _fees;
        tempCRT.destination = _transferDestination;
        tempCRT.destCurrencyID = _destCurrencyID;
        tempCRT.secondReserveID = _secondReserveID;
        tempCRT.destSystemID = _destSystemID;
        
        
        //check if the current block height has a set of transfers associated with it if so add to the existing array
        if(readyExportsByBlock[currentHeight].created) {
            //append to an existing array of transfers
            exportIndex = readyExportsByBlock[currentHeight].index;
            _readyExports[exportIndex].push(tempCRT);
            newHash = false ;
        }
        else {
            _pendingExports.push(tempCRT);
            _readyExports.push(_pendingExports);
            exportIndex = _readyExports.length - 1;
            readyExportsByBlock[currentHeight] = blockCreated(exportIndex,true);
            delete _pendingExports;
            newHash = true;
        }
        delete tempCRT;
        
        //create a cross chain export, serialize it and hash it
       
        VerusObjects.CCrossChainExport memory CCE = _createCCrossChainExport(exportIndex);
        //push the CCE 
        //create a hash of the CCCE
        bytes memory serializedCCE = verusSerializer.serializeCCrossChainExport(CCE);
        bytes32 hashedCCE = blake2b.createHash(serializedCCE);
        
        
        //bytes32 hashedCCE = keccak256(serializedCCE);
        //add the hashed value
        if(newHash) readyExportHashes.push(hashedCCE);
        else readyExportHashes[exportIndex] = hashedCCE;
        
        
    }


    function _createCCrossChainExport(uint exportIndex) public returns (VerusObjects.CCrossChainExport memory){
        VerusObjects.CCrossChainExport memory output = verusCCE.generateCCE(_readyExports[exportIndex]);
        //temporary emit
        CrossChainExport(output);
        return output;
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
                //loop through the currencyvalues
                for(uint j = 0; j < _import.transfers[i].currencyvalues.length; j++){
                    sendEth(_import.transfers[i].currencyvalues[j].amount,payable(address(_import.transfers[i].destination.destinationaddress)));
                    ethHeld -= _import.transfers[i].currencyvalues[j].amount;
                }
            } else {
                //handle erc20 transactions   
                for(uint j = 0; j < _import.transfers[i].currencyvalues.length; j++){
                    tokenManager.importERC20Tokens(_import.transfers[i].destCurrencyID,
                        _import.transfers[i].currencyvalues[j].amount,
                        _import.transfers[i].destination.destinationaddress);
                }
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
    
    
    function getReadyExportsByBlock(uint _blockNumber) public view returns(VerusObjects.CReserveTransferSet memory){
        //need a transferset for each position not each block
        //retrieve a block get the indexes, create a transfer set for each index add those to the array
        uint eIndex = readyExportsByBlock[_blockNumber].index;
        VerusObjects.CReserveTransferSet memory output = VerusObjects.CReserveTransferSet(
            eIndex, //position in array
            _blockNumber, //blockHeight
            readyExportHashes[eIndex],
            _readyExports[eIndex]
        );
        return output;
    }

    
    function getReadyExportsByRange(uint _startBlock,uint _endBlock) public view returns(VerusObjects.CReserveTransferSet[] memory){
        //calculate the size that the return array will be to initialise it
        uint outputSize = 0;
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

    function deprecate(address _upgradedAddress,bytes32 _addressHash,uint8[] memory _vs,bytes32[] memory _rs,bytes32[] memory _ss) public returns(address){
        if(verusNotarizer.notarizedDeprecation(_upgradedAddress, _addressHash, _vs, _rs, _ss)){
            deprecated = true;
            upgradedAddress = _upgradedAddress;
            Deprecate(_upgradedAddress);
        }
    }


}
