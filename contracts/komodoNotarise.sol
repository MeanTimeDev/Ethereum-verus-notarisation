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
        CurrencyState currencyState;
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
    event NewBlock(NotarisedBlock notarisedBlock,uint64 notarisedBlockHeight);


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


    function setLatestBlock(NotarisedBlock memory _notarisedBlockDetail,
        bytes32[] memory _rs,
        bytes32[] memory _ss,
        uint8[] memory _vs) public returns(bool){

        require(!deprecated,"Contract has been deprecated");
        require(komodoNotaries[msg.sender],"Only a notary can call this function");
        require((_rs.length == _ss.length) && (_rs.length == _vs.length),"Signature arrays must be of equal length");
        require(_notarisedBlockDetail.notarizationHeight > lastBlockHeight,"Block Height must be greater than current block height");

        bytes memory serialisedBlock = serialiseBlock(_notarisedBlockDetail);
        //check the hash of the data
        bytes32 hashedData = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n",serialisedBlock.length,serialisedBlock));
        //need to check the block hash matches the hashed notarised block
        //require(_notarisedBlockDetail.length == 148,"Incorrect block length, block whould be 148 long");

        address signingAddress;
        //total number of signatures that have been validated
        uint8 numberOfSignatures = 0;

        //loop through the arrays, check the following:
        //does the hash in the hashedBlocks match the komodoBlockHash passed in
        for(uint i = 0; i < _rs.length; i++){
            //if the address is in the notary array increment the number of signatures
            signingAddress = recoverSigner(hashedData, _vs[i], _rs[i], _ss[i]);
            if(komodoNotaries[signingAddress]) {
                numberOfSignatures++;
            }
        }

        //if there is greater than 13 proper signatories then set the block hash
        if(numberOfSignatures >= requiredNotaries){
            notarisedBlocks[_notarisedBlockDetail.notarizationHeight] = serialisedBlock;
            lastBlockHeight = _notarisedBlockDetail.notarizationHeight;
            emit NewBlock(_notarisedBlockDetail,lastBlockHeight);
            return true;
        } else return false;


    }

    function recoverSigner(bytes32 h, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        address addr = ecrecover(h, v, r, s);
        return addr;
    }


    function getLastNotarisedBlock() public view returns(NotarisedBlock memory){

        require(!deprecated,"Contract has been deprecated");
        return deSerialiseBlock(notarisedBlocks[lastBlockHeight]);

    }

    function getNotarisedBlock(uint32 _blockHeight) public view returns(NotarisedBlock memory){

        return deSerialiseBlock(notarisedBlocks[_blockHeight]);

    }

    function getLastBlockHeight() public view returns(uint32){

        require(!deprecated,"Contract has been deprecated");
        return lastBlockHeight;
    }

    function deSerialiseBlock(bytes memory _serialisedBlock) private pure returns(NotarisedBlock memory){
        NotarisedBlock memory deserialisedBlock;
        (deserialisedBlock.version,
        deserialisedBlock.protocol,
        deserialisedBlock.currencyID,
        deserialisedBlock.notaryDest,
        deserialisedBlock.notarizationHeight,
        deserialisedBlock.mmrRoot,
        deserialisedBlock.notarizationPreHash,
        deserialisedBlock.compactPower
        ) = abi.decode(_serialisedBlock,(uint32,uint32,uint160,uint160,uint32,uint256,uint256,uint256));

        return deserialisedBlock;
    }

    function serialiseBlock(NotarisedBlock memory _deserialisedBlock) private pure returns(bytes memory){
        return abi.encode(_deserialisedBlock.version,
        _deserialisedBlock.protocol,
        _deserialisedBlock.currencyID,
        _deserialisedBlock.notaryDest,
        _deserialisedBlock.notarizationHeight,
        _deserialisedBlock.mmrRoot,
        _deserialisedBlock.notarizationPreHash,
        _deserialisedBlock.compactPower);
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

