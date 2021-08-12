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
    bytes20 vdxfcode = bytes20(0x280A0514338BBcDD2889F4809592816B388D4E7a);//0x280a0514338bbcdd2889f4809592816b388d4e7a;


    //list of all notarizers mapped to allow for quick searching
    mapping (address => bool) public komodoNotaries;
    address[] private notaries;
    //mapped blockdetails
    mapping (uint32 => VerusObjects.CPBaaSNotarization) public notarizedDataEntries;
    mapping (uint32 => bytes32) public notarizedStateRoots;
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
        bytes memory errorMessage = abi.encodePacked("Caller is not a notary",msgSender);
        require(komodoNotaries[msgSender] == true, string(errorMessage));
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
        bytes32[] memory _ss,
        uint[] memory blockheights,
        address[] memory notaryAddress
        ) public returns(bytes memory){

        require(!deprecated,"Contract has been deprecated");
        //require(komodoNotaries[msg.sender],"Only a notary can call this function");
        require((_rs.length == _ss.length) && (_rs.length == _vs.length),"Signature arrays must be of equal length");
        require(_pbaasNotarization.notarizationheight > lastBlockHeight,"Block Height must be greater than current block height");

        bytes memory serializedNotarisation = verusSerializer.serializeCPBaaSNotarization(_pbaasNotarization);
        return serializedNotarisation;
        //add in the extra fields for the hashing
        //add in the other pieces for encoding
        bytes32 hashedNotarization;
        address signer;
        uint8 numberOfSignatures = 0;
        
        
        
        for(uint i=0; i < blockheights.length;i++){
            //build the hashing sequence
            hashedNotarization = keccak256(abi.encodePacked(vdxfcode,VerusObjects.VerusSystemId,blockheights[i],notaryAddress[i],serializedNotarisation));
            signer = recoverSigner(hashedNotarization, _vs[i], _rs[i], _ss[i]);
            if(signer == notaryAddress[i] && komodoNotaries[signer]){
                   numberOfSignatures++;     
            }
            if(numberOfSignatures >= requiredNotaries){
                break;
            }
        }
        if(numberOfSignatures >= requiredNotaries){
            for(uint j = 0 ; j < _pbaasNotarization.proofroots.length;j++){
                if(_pbaasNotarization.proofroots[j].systemid == VerusObjects.VEth){
                    notarizedStateRoots[_pbaasNotarization.notarizationheight] =  _pbaasNotarization.proofroots[j].stateroot;       
                    blockHeights.push(_pbaasNotarization.notarizationheight);
                    if(lastBlockHeight <_pbaasNotarization.notarizationheight){
                        lastBlockHeight = _pbaasNotarization.notarizationheight;
                    }
                }
            }
            emit NewBlock(_pbaasNotarization,lastBlockHeight);
            //lastCurrencyState = _pbaasNotarization.currencyState;
            return serializedNotarisation;
        } //else return bytes(0x00);
        
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
