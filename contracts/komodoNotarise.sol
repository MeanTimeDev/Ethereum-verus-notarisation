// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract KomodoNotarise is Ownable{

    //last notarised blockheight
    uint32 public lastBlockHeight;
    CurrencyState private lastCurrencyState;
    //allows for the contract to be upgradable
    bool public deprecated;
    address public upgradedAddress;
    //number of notaries required
    uint8 requiredNotaries = 1;

    //list of all notarisers mapped to allow for quick searching
    mapping (address => bool) private komodoNotaries;
    //mapped blockdetails
    //the
    mapping (uint32 => bytes) private notarisedBlocks;
    //used to record the number of notaries
    uint8 private notaryCount;

    struct NotarisedBlock{
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
    event NewBlock(bytes notarisedBlock,uint64 komodoBlockHeight);


    constructor() public {
        deprecated = false;
        notaryCount = 0;
        lastBlockHeight = 0;
    }

    function addNotary(address _notary) public onlyOwner
    returns(bool){

        require(!deprecated,"Contract has been deprecated");
        //if the the komodoNotaries is full reject
        require(notaryCount < 60,"Cnat have more than 60 notaries");
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

    /**
    Solidity cant handle a struct array or an array of variable length arrays
    as the sig byte array is 65 bytes this gets flagged as a variable length array
    to get round this we pass in the constituents of the address.
    _komodoBlockDetail is 148 bytes serialised
    **/
    function setLatestBlock(bytes memory _komodoBlockDetail,
        uint32 _blockHeight,
        bytes32[] memory _hashedBlockDetail,
        bytes32[] memory _rs,
        bytes32[] memory _ss,
        uint8[] memory _vs) public returns(bool){

        require(!deprecated,"Contract has been deprecated");
        require(komodoNotaries[msg.sender],"Only a notary can call this function");
        require((_rs.length == _ss.length) && (_rs.length == _vs.length),"Signature arrays must be of equal length");
        require(_blockHeight > lastBlockHeight,"Block Height must be greater than current block height");
        require(_komodoBlockDetail.length == 148,"Incorrect block length, block whould be 148 long");
        

        address signingAddress;
        //total number of signatures that have been validated
        uint8 numberOfSignatures = 0;

        //loop through the arrays, check the following:
        //does the hash in the hashedBlocks match the komodoBlockHash passed in
        for(uint i = 0; i < _rs.length; i++){
            //is the address in the hashed block

            signingAddress = ecrecover(_hashedBlockDetail[i], _vs[i], _rs[i], _ss[i]);
            if(komodoNotaries[signingAddress]) {
                numberOfSignatures++;
            }
        }

        //if there is greater than 13 proper signatories then set the block hash
        if(numberOfSignatures >= requiredNotaries){
            notarisedBlocks[_blockHeight] = _komodoBlockDetail;
            lastBlockHeight = _blockHeight;
            emit NewBlock(_komodoBlockDetail,lastBlockHeight);
        }

    }

    function recoverSigner(bytes32 h, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        address addr = ecrecover(h, v, r, s);
        return addr;
    }


    function getLastNotarisedBlock() public view returns(NotarisedBlock memory){

        require(!deprecated,"Contract has been deprecated");
        return convertSerialisedBlock(notarisedBlocks[lastBlockHeight]);

    }

    function getNotarisedBlock(uint32 _blockHeight) public view returns(NotarisedBlock memory){

        return convertSerialisedBlock(notarisedBlocks[_blockHeight]);

    }

    function getLastBlockHeight() public view returns(uint32){

        require(!deprecated,"Contract has been deprecated");
        return lastBlockHeight;
    }

    function convertSerialisedBlock(bytes memory _serialisedBlock) private pure returns(NotarisedBlock memory){
        NotarisedBlock memory deserialisedBlock;
        deserialisedBlock.version = toUint32(_serialisedBlock,0);
        deserialisedBlock.protocol = toUint32(_serialisedBlock,4);
        deserialisedBlock.currencyID = toUint160(_serialisedBlock,8);
        deserialisedBlock.notaryDest = toUint160(_serialisedBlock,28);
        deserialisedBlock.notarizationHeight = toUint32(_serialisedBlock,48);
        deserialisedBlock.mmrRoot = toUint256(_serialisedBlock,52);
        deserialisedBlock.notarizationPreHash = toUint256(_serialisedBlock,84);
        deserialisedBlock.compactPower = toUint256(_serialisedBlock,116);
        return deserialisedBlock;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= (_start + 4), "Read out of bounds Uint32");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint160(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= (_start + 20), "Read out of bounds Uint160");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x14), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= (_start + 32), "Read out of bounds Uint256");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
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


