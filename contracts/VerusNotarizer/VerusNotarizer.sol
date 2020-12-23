// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;


contract VerusNotarizer{

    //last notarized blockheight
    uint32 public lastBlockHeight;
    //CurrencyState private lastCurrencyState;
    //allows for the contract to be upgradable
    bool public deprecated;
    address public upgradedAddress;
    //number of notaries required
    uint8 requiredNotaries = 13;

    //list of all notarizers mapped to allow for quick searching
    mapping (address => bool) private komodoNotaries;
    //mapped blockdetails
    mapping (uint32 => bytes) public notarizedDataEntries;
    uint32[] public blockHeights;
    //used to record the number of notaries
    uint8 private notaryCount;

    struct NotarizedData{
        uint32 version;
        uint32 protocol;
        uint160 currencyID;
        uint160 notaryDest;
        uint32 notarizationHeight;
        uint256 mmrRoot;
        uint256 notarizationPreHash;
        uint256 compactPower;
    }

    struct TestData{
        uint32 version;
        uint32 protocol;
        uint160 currencyID;
        uint160 notaryDest;
        uint32 notarizationHeight;
        uint256 mmrRoot;
    }
  /*  
    struct CurrencyState{
        uint64[] reserveIn;
        uint64[] nativeIn;
        uint64[] reserveOut;
        uint64[] conversionPrice;
        uint64[] fees;
        uint64[] conversionFees;
    }
  */  
    // Notifies when the contract is deprecated
    event Deprecate(address newAddress);
    // Notifies when a new block hash is published
    event NewBlock(NotarizedData notarizedData,uint64 notarizedDataHeight);
    event signedAddress(address signedAddress);

    constructor() public {
        deprecated = false;
        notaryCount = 0;
        lastBlockHeight = 0;
        //add in the owner as the first notary
        address msgSender = msg.sender;
        komodoNotaries[msgSender] = true;
        notaryCount++;
    }

    modifier onlyNotary() {
        address msgSender = msg.sender;
        require(komodoNotaries[msgSender] == true, "Caller is not a notary");
        _;
    }

    function addNotary(address _notary,
        bytes32 _notarizedAddressHash,
        bytes32[] memory _rs,
        bytes32[] memory _ss,
        uint8[] memory _vs) public onlyNotary
    returns(bool){
        require(isNotarized(_notarizedAddressHash,_rs,_ss,_vs),"Function can only be executed by notaries");
        require(!deprecated,"Contract has been deprecated");
        //if the the komodoNotaries is full reject
        require(notaryCount < 60,"Cant have more than 60 notaries");
        //if the notary already is in the komodNotaries then reject
        require(!komodoNotaries[_notary],"Notary already exists");

        komodoNotaries[_notary] = true;
        notaryCount++;
        return true;

    }

    function removeNotary(address _notary) public onlyNotary
    returns(bool){

        require(!deprecated,"Contract has been deprecated");
        //if the notary is not in the list then fail
        require(komodoNotaries[_notary] == true,"Notary does not exist");
        //there must be at least one notary in the contract perhaps?
        require(notaryCount > 1,"Must have more than one notary");
        //need to look at this no easy way to delete from a mapping
        delete komodoNotaries[_notary];
        notaryCount--;
        return true;

    }

    //this function allows for intially expanding out the number of notaries
    function currentNotariesRequired() public view returns(uint8){
        if(notaryCount == 1) return 1;
        uint halfNotaryCount = notaryCount/2;
        if(halfNotaryCount > requiredNotaries) return requiredNotaries;
        else return uint8(halfNotaryCount);
    }


    function splitSignature(bytes sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function isNotarized(bytes32 _notarizedDataHash,bytes65[] memory sigs) private view returns(bool){
        bytes32[] memory rs;
        bytes32[] memory ss;
        uint8[] memory vs;

        bytes32 r,s;
        uint8 v;
        //loop through the signatures array break them out to the 3 part signature
        for(uint i=0;i<sigs.length;i++){
            (v,r,s)splitSignature(sigs[i]);
            rs[i] = r;
            ss[i] = s;
            vs[i] = i;
        }
        return isNotarized(_notarizedDataHash,rs,ss,vs);
    }

    function isNotarized(bytes32 notarizedDataHash,
        bytes32[] memory _rs,
        bytes32[] memory _ss,
        uint8[] memory _vs) private view returns(bool){
        
        address signingAddress;
        //total number of signatures that have been validated
        uint8 numberOfSignatures = 0;

        //loop through the arrays, check the following:
        //does the hash in the hashedBlocks match the komodoBlockHash passed in
        for(uint i = 0; i < _rs.length; i++){
            //if the address is in the notary array increment the number of signatures
            signingAddress = recoverSigner(notarizedDataHash, _vs[i], _rs[i], _ss[i]);
            if(komodoNotaries[signingAddress]) {
                numberOfSignatures++;
            }
        }
        uint8 _requiredNotaries = currentNotariesRequired();
        if(numberOfSignatures >= _requiredNotaries){
            return true;
        } else return false;

    }

    function setLatestData(NotarizedData memory _notarizedDataDetail,
        bytes32 _notarizedDataHash,
        bytes32[] memory _rs,
        bytes32[] memory _ss,
        uint8[] memory _vs) public onlyNotary returns(bool){

        require(!deprecated,"Contract has been deprecated");
        require(komodoNotaries[msg.sender],"Only a notary can call this function");
        require((_rs.length == _ss.length) && (_rs.length == _vs.length),"Signature arrays must be of equal length");
        require(_notarizedDataDetail.notarizationHeight > lastBlockHeight,"Block Height must be greater than current block height");

        bytes memory serializedBlock = serializeData(_notarizedDataDetail);
        //check the hash of the data
        //need to check the block hash matches the hashed notarized block
        
        //if there is greater than 13 proper signatories then set the block hash
        if(isNotarized(_notarizedDataHash,_rs,_ss,_vs)){
            notarizedDataEntries[_notarizedDataDetail.notarizationHeight] = serializedBlock;
            blockHeights.push(_notarizedDataDetail.notarizationHeight);
            lastBlockHeight = _notarizedDataDetail.notarizationHeight;
            //lastCurrencyState = _currencyState;
            emit NewBlock(_notarizedDataDetail,lastBlockHeight);
            return true;
        } else return false;
    }

    function recoverSigner(bytes32 h, uint8 v, bytes32 r, bytes32 s) private pure returns (address) {
        address addr = ecrecover(h, v, r, s);
        return addr;
    }


    function getLastNotarizedData() public view returns(NotarizedData memory){

        require(!deprecated,"Contract has been deprecated");
        return deSerializeData(notarizedDataEntries[lastBlockHeight]);

    }


    function getNotarizedData(uint32 _blockHeight) public view returns(NotarizedData memory){

        return deSerializeData(notarizedDataEntries[_blockHeight]);

    }

    function getLastBlockHeight() public view returns(uint32){

        require(!deprecated,"Contract has been deprecated");
        return lastBlockHeight;
    }

    function getAllBlockHeights() public view returns(uint32[] memory){
        return blockHeights;
    }

    function deSerializeData(bytes memory _serializedBlock) private pure returns(NotarizedData memory){
        NotarizedData memory deserializedBlock;

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

    function serializeData(NotarizedData memory _deserializedBlock) private pure returns(bytes memory){

        return abi.encode(_deserializedBlock.version,
        _deserializedBlock.protocol,
        _deserializedBlock.currencyID,
        _deserializedBlock.notaryDest,
        _deserializedBlock.notarizationHeight,
        _deserializedBlock.mmrRoot,
        _deserializedBlock.notarizationPreHash,
        _deserializedBlock.compactPower);

    }

    /*** temporary code for use on test net only will be removed for production */
/*
    function kill() public onlyNotary{
        selfdestruct(msg.sender);
    }
*/
    /**
    * deprecate current contract
    */
/*    
    function deprecate(address _upgradedAddress) public onlyNotary {
        require(!deprecated,"Contract has been deprecated");
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }
*/
}