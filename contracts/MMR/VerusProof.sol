// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;
import "../VerusBridge/VerusObjects.sol";
import "./VerusBLAKE2b.sol";
import "../VerusBridge/VerusSerializer.sol";
import "../VerusNotarizer/VerusNotarizer.sol";

contract VerusProof{

    uint256 mmrRoot;
    VerusBLAKE2b blake2b;
    VerusNotarizer verusNotarizer;
    VerusSerializer verusSerializer;
    
    event HashEvent(bytes32 newHash,uint8 eventType);

    constructor(address notarizerAddress,address verusBLAKE2b,address verusSerializerAddress) {
        blake2b = VerusBLAKE2b(verusBLAKE2b);
        verusSerializer = VerusSerializer(verusSerializerAddress);
        verusNotarizer = VerusNotarizer(notarizerAddress);   
    }

    function proveTransaction(bytes32 notarisationHash,bytes32[] memory _transfersProof,uint32 _hashIndex,uint32 _blockHeight) public returns(bool){
        bytes32 mmrRootHash;
        VerusObjects.CPBaaSNotarization memory verusNotarizedData = verusNotarizer.getNotarizedData(_blockHeight);
        //loop through the proofRoots get the appropriate one for eth
        for(uint i = 0;i< verusNotarizedData.proofroots.length;i++){
//            if(verusNotarizedData.proofroots[i].currencyid == VerusObjects.VEth) {
                mmrRootHash = bytes32(verusNotarizedData.proofroots[i].stateroot);
//            }
        }
        if (mmrRootHash == predictedRootHash(notarisationHash,_hashIndex,_transfersProof)) return true;
        else return false;
    }

    function predictedRootHash(bytes32 _hashToCheck,uint _hashIndex,bytes32[] memory _branch) public returns(bytes32){
        
        require(_hashIndex >= 0,"Index cannot be less than 0");
        require(_branch.length > 0,"Branch must be longer than 0");
        uint branchLength = _branch.length;
        bytes32 hashInProgress;
        bytes memory joined;
        hashInProgress = blake2b.bytesToBytes32(abi.encodePacked(_hashToCheck));

       for(uint i = 0;i < branchLength; i++){
            if(_hashIndex & 1 > 0){
                require(_branch[i] != _hashToCheck,"Value can be equal to node but never on the right");
                //join the two arrays and pass to blake2b
                joined = abi.encodePacked(_branch[i],hashInProgress);
            } else {
                joined = abi.encodePacked(hashInProgress,_branch[i]);
            }
            hashInProgress = blake2b.createHash(joined);
            _hashIndex >>= 1;
        }

        return hashInProgress;

    }

    function checkHashInRoot(bytes32 _mmrRoot,bytes32 _hashToCheck,uint _hashIndex,bytes32[] memory _branch) public returns(bool){
        bytes32 calculatedHash = predictedRootHash(_hashToCheck,_hashIndex,_branch);
        if(_mmrRoot == calculatedHash) return true;
        else return false;
    }
}


