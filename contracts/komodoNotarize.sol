// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract KomodoNotarize is Ownable{

    //last notarized blockheight
    uint32 public lastBlockHeight;
    CurrencyState private lastCurrencyState;
    //allows for the contract to be upgradable
    bool public deprecated;
    address public upgradedAddress;
    //number of notaries required
    uint8 requiredNotaries = 1;

    //list of all notarizers mapped to allow for quick searching
    mapping (address => bool) private komodoNotaries;
    //mapped blockdetails
    //the
    mapping (uint32 => bytes) private notarizedBlocks;
    //used to record the number of notaries
    uint8 private notaryCount;

    struct NotarizedBlock{
        uint32 version;
        uint32 protocol;
        uint160 currencyID;
        uint160 notaryDest;
        uint32 notarizationHeight;
        uint256 mmrRoot;
        uint256 notarizationPreHash;
        uint256 compactPower;
    }

    struct CurrencyState{
        uint64[] reserveIn;
        uint64[] nativeIn;
        uint64[] reserveOut;
        uint64[] conversionPrice;
        uint64[] fees;
        uint64[] conversionFees;
    }

    // Notifies when the contract is deprecated
    event Deprecate(address newAddress);
    // Notifies when a new block hash is published
    event NewBlock(NotarizedBlock notarizedBlock,uint64 notarizedBlockHeight);


    constructor() public {
        deprecated = false;
        notaryCount = 0;
        lastBlockHeight = 0;
    }

    function addNotary(address _notary) public onlyOwner
    returns(bool){

        require(!deprecated,"Contract has been deprecated");
        //if the the komodoNotaries is full reject
        require(notaryCount < 60,"Cant have more than 60 notaries");
        //if the notary already is in the komodNotaries then reject
        require(!komodoNotaries[_notary],"Notary already exists");

        komodoNotaries[_notary] = true;
        notaryCount++;
        return true;

    }

    function removeNotary(address _notary)  public onlyOwner
    returns(bool){

        require(!deprecated,"Contract has been deprecated");
        //if the notary is not in the list then fail
        require(komodoNotaries[_notary] == true,"Notary does not exist");

        //need to look at this no easy way to delete from a mapping
        komodoNotaries[_notary] = false;
        notaryCount--;
        return true;

    }


    function setLatestBlock(NotarizedBlock memory _notarizedBlockDetail,
        CurrencyState memory _currencyState,
        bytes32 notarizedBlockHash,
        bytes32[] memory _rs,
        bytes32[] memory _ss,
        uint8[] memory _vs) public returns(bool){

        require(!deprecated,"Contract has been deprecated");
        require(komodoNotaries[msg.sender],"Only a notary can call this function");
        require((_rs.length == _ss.length) && (_rs.length == _vs.length),"Signature arrays must be of equal length");
        require(_notarizedBlockDetail.notarizationHeight > lastBlockHeight,"Block Height must be greater than current block height");

        bytes memory serializedBlock = serializeBlock(_notarizedBlockDetail);
        //check the hash of the data
        //need to check the block hash matches the hashed notarized block
        
        address signingAddress;
        //total number of signatures that have been validated
        uint8 numberOfSignatures = 0;

        //loop through the arrays, check the following:
        //does the hash in the hashedBlocks match the komodoBlockHash passed in
        for(uint i = 0; i < _rs.length; i++){
            //if the address is in the notary array increment the number of signatures
            signingAddress = recoverSigner(notarizedBlockHash, _vs[i], _rs[i], _ss[i]);
            if(komodoNotaries[signingAddress]) {
                numberOfSignatures++;
            }
        }

        //if there is greater than 13 proper signatories then set the block hash
        if(numberOfSignatures >= requiredNotaries){
            notarizedBlocks[_notarizedBlockDetail.notarizationHeight] = serializedBlock;
            lastBlockHeight = _notarizedBlockDetail.notarizationHeight;
            lastCurrencyState = _currencyState;
            emit NewBlock(_notarizedBlockDetail,lastBlockHeight);
            return true;
        } else return false;


    }

    function recoverSigner(bytes32 h, uint8 v, bytes32 r, bytes32 s) private pure returns (address) {
        address addr = ecrecover(h, v, r, s);
        return addr;
    }


    function getLastNotarizedBlock() public view returns(NotarizedBlock memory){

        require(!deprecated,"Contract has been deprecated");
        return deSerializeBlock(notarizedBlocks[lastBlockHeight]);

    }

    function getNotarizedBlock(uint32 _blockHeight) public view returns(NotarizedBlock memory){

        return deSerializeBlock(notarizedBlocks[_blockHeight]);

    }

    function getLastBlockHeight() public view returns(uint32){

        require(!deprecated,"Contract has been deprecated");
        return lastBlockHeight;
    }

    function deSerializeBlock(bytes memory _serializedBlock) private pure returns(NotarizedBlock memory){
        NotarizedBlock memory deserializedBlock;

        (deserializedBlock.version,
        deserializedBlock.protocol,
        deserializedBlock.currencyID,
        deserializedBlock.notaryDest,
        deserializedBlock.notarizationHeight,
        deserializedBlock.mmrRoot,
        deserializedBlock.notarizationPreHash,
        deserializedBlock.compactPower
        ) = abi.decode(_serializedBlock,(uint32,uint32,uint160,uint160,uint32,uint256,uint256,uint256));

        return deserializedBlock;
    }

    function serializeBlock(NotarizedBlock memory _deserializedBlock) private pure returns(bytes memory){

        return abi.encode(_deserializedBlock.version,
        _deserializedBlock.protocol,
        _deserializedBlock.currencyID,
        _deserializedBlock.notaryDest,
        _deserializedBlock.notarizationHeight,
        _deserializedBlock.mmrRoot,
        _deserializedBlock.notarizationPreHash,
        _deserializedBlock.compactPower);

    }

    function kill() public onlyOwner{
        selfdestruct(msg.sender);
    }

    /**
    * deprecate current contract
    */
    function deprecate(address _upgradedAddress) public onlyOwner {
        require(!deprecated,"Contract has been deprecated");
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);

    }

}