// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.4.21 <0.7.0;
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract KomodoNotarise is Ownable{

    //last notarised blockhash
    bytes32 public komodoBlockHash;
    //last notarised blockheight
    uint64 public komodoBlockHeight;
    //allows for the contract to be upgradable
    bool public deprecated;
    address public upgradedAddress;
    //number of notaries required
    uint8 requiredNotaries = 1;

    //list of all notarisers mapped to allow for quick searching
    mapping (address => bool) private komodoNotaries;
    //used to record the number of
    uint8 private notaryCount;

    // Notifies when the contract is deprecated
    event Deprecate(address newAddress);
    // Notifies when a new block hash is published
    event NewBlock(bytes32 komodoBlockHash,uint64 komodoBlockHeight);



    constructor() public {
        deprecated = false;
        notaryCount = 0;
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
    to get round this we pass in the constituents of the address
    **/
    function setLatestBlock(bytes32 _komodoBlockHash,
    uint64 _komodoBlockHeight,
    bytes32[] memory _hashedBlocks,
    bytes32[] memory _rs,
    bytes32[] memory _ss,
    uint8[] memory _vs) public returns(bool){

        require(!deprecated,"Contract has been deprecated");
        require(komodoNotaries[msg.sender],"Only a notary can call this function");
        require((_rs.length == _ss.length) && (_rs.length == _vs.length),"Signature arrays must be of equal length");
        require(_komodoBlockHeight > komodoBlockHeight,"Block Height must be greater than current block height");

        address signingAddress;
        //total number of signatures that have been validated
        uint8 numberOfSignatures = 0;

        //loop through the arrays, check the following:
        //does the hash in the hashedBlocks match the komodoBlockHash passed in
        for(uint i = 0; i < _rs.length; i++){
            //is the address in the hashed block
            signingAddress = recoverSigner(_hashedBlocks[i], _vs[i], _rs[1], _ss[i]);
            if(komodoNotaries[signingAddress]) {
                numberOfSignatures++;
            }
        }

        //if there is greater than 13 proper signatories then set the block hash
        if(numberOfSignatures >= requiredNotaries){
            komodoBlockHash = _komodoBlockHash;
            komodoBlockHeight = _komodoBlockHeight;
            emit NewBlock(komodoBlockHash,komodoBlockHeight);
        }

    }

    function recoverSigner(bytes32 h, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);

        return addr;
    }

    function getLatestBlockHash() public view returns(bytes32){

        require(!deprecated,"Contract has been deprecated");
        return komodoBlockHash;

    }

    function getLatestBlockHeight() public view returns(bytes32){

        require(!deprecated,"Contract has been deprecated");
        return komodoBlockHash;
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
