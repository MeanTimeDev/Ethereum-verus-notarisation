// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../VerusBridge/VerusObjects.sol";
import "../VerusBridge/VerusSerializer.sol";
import "../MMR/VerusBLAKE2b.sol";

contract VerusNotarizer{

    //last notarized blockheight
    uint32 public lastBlockHeight;
    //CurrencyState private lastCurrencyState;
    //allows for the contract to be upgradable
    bool public deprecated;
    address public upgradedAddress;
    //number of notaries required
    uint8 requiredNotaries = 13;
    VerusBLAKE2b blake2b;
    VerusSerializer verusSerializer;

    //list of all notarizers mapped to allow for quick searching
    mapping (address => bool) public komodoNotaries;
    address[] private notaries;
    //mapped blockdetails
    mapping (uint32 => VerusObjects.CPBaaSNotarization) public notarizedDataEntries;
    mapping (uint32 => uint256) public notarizedStateRoots;
    uint32[] public blockHeights;
    //used to record the number of notaries
    uint8 private notaryCount;

    // Notifies when the contract is deprecated
    event Deprecate(address newAddress);
    // Notifies when a new block hash is published
    event NewBlock(VerusObjects.CPBaaSNotarization,uint32 notarizedDataHeight);

    constructor(address _verusBLAKE2bAddress,address _verusSerializerAddress,address[] memory _notaries) {
        verusSerializer = VerusSerializer(_verusSerializerAddress);
        blake2b = VerusBLAKE2b(_verusBLAKE2bAddress);
        deprecated = false;
        notaryCount = 0;
        lastBlockHeight = 0;
        //add in the owner as the first notary
       // address msgSender = msg.sender;
        for(uint i =0; i < _notaries.length; i++){
            komodoNotaries[_notaries[i]] = true;
            notaries.push(_notaries[i]);
            notaryCount++;
        }
    }

    modifier onlyNotary() {
        address msgSender = msg.sender;
        require(komodoNotaries[msgSender] == true, "Caller is not a notary");
        _;
    }
    
    function getNotaries() public view returns(address[] memory){
        return notaries;
    }
        
    function isNotary(address _notary) public view returns(bool) {
        if(komodoNotaries[_notary] == true) return true;
        else return false;
    }

    //this function allows for intially expanding out the number of notaries
    function currentNotariesRequired() public view returns(uint8){
        if(notaryCount == 1 || notaryCount == 2) return 1;
        uint halfNotaryCount = (notaryCount/2) + 1;
        if(halfNotaryCount > requiredNotaries) return requiredNotaries;
        else return uint8(halfNotaryCount);
    }


    function splitSignature(bytes memory _sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(_sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        return (v, r, s);
    }

    function isNotarized(bytes32 _notarizedDataHash,
        bytes32[] memory _rs,
        bytes32[] memory _ss,
        uint8[] memory _vs) public view returns(bool){
        
        address signingAddress;
        //total number of signatures that have been validated
        uint8 numberOfSignatures = 0;

        //loop through the arrays, check the following:
        //does the hash in the hashedBlocks match the komodoBlockHash passed in
        for(uint i = 0; i < _rs.length; i++){
            //if the address is in the notary array increment the number of signatures
            signingAddress = recoverSigner(_notarizedDataHash, _vs[i], _rs[i], _ss[i]);
            if(komodoNotaries[signingAddress]) {
                numberOfSignatures++;
            }
        }
        uint8 _requiredNotaries = currentNotariesRequired();
        if(numberOfSignatures >= _requiredNotaries){
            return true;
        } else return false;

    }

    function setLatestData(VerusObjects.CPBaaSNotarization memory _pbaasNotarization,
        uint8[] memory _vs,
        bytes32[] memory _rs,
        bytes32[] memory _ss
        ) public onlyNotary returns(bool){

        require(!deprecated,"Contract has been deprecated");
        require(komodoNotaries[msg.sender],"Only a notary can call this function");
        require((_rs.length == _ss.length) && (_rs.length == _vs.length),"Signature arrays must be of equal length");
        require(_pbaasNotarization.notarizationHeight > lastBlockHeight,"Block Height must be greater than current block height");

        bytes memory serializedNotarisation = verusSerializer.serializeCPBaaSNotarization(_pbaasNotarization);
        bytes32 hashedNotarization = blake2b.createHash(serializedNotarisation);
        //require(hashedNotarization == _notarizedDataHash,"Hash of serialized notarization does not match.");
        //check the hash of the data
        //need to check the block hash matches the hashed notarized block
    /*            
        //if there is greater than 13 proper signatories then set the block hash
        if(isNotarized(hashedNotarization,_rs,_ss,_vs)){
            //loop through the notarized data to retrieve the relevant CProofRoot
            for(uint i = 0 ; i < _pbaasNotarization.proofRoots.length;i++){
                if(_pbaasNotarization.proofRoots[i].currencyId == VerusObjects.VEth){
                    notarizedStateRoots[_pbaasNotarization.notarizationHeight] =  _pbaasNotarization.proofRoots[i].proofRoot.stateRoot;       
                    blockHeights.push(_pbaasNotarization.notarizationHeight);
                    if(lastBlockHeight <_pbaasNotarization.notarizationHeight){
                        lastBlockHeight = _pbaasNotarization.notarizationHeight;
                    }
                }
            }
            
*/
            //lastCurrencyState = _currencyState;
            emit NewBlock(_pbaasNotarization,lastBlockHeight);
            return true;
       // } else return false;
    }

    function recoverSigner(bytes32 _h, uint8 _v, bytes32 _r, bytes32 _s) private pure returns (address) {
        address addr = ecrecover(_h, _v, _r, _s);
        return addr;
    }

    function numNotarizedBlocks() public view returns(uint){
        return blockHeights.length;
    }
/*
    function getLastNotarizedData() public view returns(VerusObjects.CPBaaSNotarization memory){

        require(!deprecated,"Contract has been deprecated");
        return notarizedDataEntries[lastBlockHeight];

    }*/

    function getNotarizedData(uint32 _blockHeight) public view returns(VerusObjects.CPBaaSNotarization memory){

        return notarizedDataEntries[_blockHeight];

    }
    
    function notarizedDeprecation(address _upgradedAddress,bytes32 _addressHash,uint8[] memory _vs,bytes32[] memory _rs,bytes32[] memory _ss) public returns(bool){
        require(isNotary(msg.sender),"Only a notary can deprecate this contract");
        bytes32 testingAddressHash = blake2b.createHash(abi.encodePacked(_upgradedAddress));
        require(testingAddressHash == _addressHash,"Hashed address does not match address hash passed in");
        require(isNotarized(_addressHash, _rs, _ss, _vs),"Deprecation requires the address to be notarized");
        return(true);
    }

    function deprecate(address _upgradedAddress,bytes32 _addressHash,uint8[] memory _vs,bytes32[] memory _rs,bytes32[] memory _ss) public {
        if(notarizedDeprecation(_upgradedAddress, _addressHash, _vs, _rs, _ss)){
            deprecated = true;
            upgradedAddress = _upgradedAddress;
            Deprecate(_upgradedAddress);
        }
    }

}
