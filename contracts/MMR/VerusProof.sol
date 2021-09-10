// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;
import "../Libraries/VerusObjects.sol";
import "./VerusBLAKE2b.sol";
import "../VerusBridge/VerusSerializer.sol";
import "../VerusNotarizer/VerusNotarizer.sol";

contract VerusProof{

    uint256 mmrRoot;
    VerusBLAKE2b blake2b;
    VerusNotarizer verusNotarizer;
    VerusSerializer verusSerializer;
    
    bytes32[] public computedValues;
    bytes32 public testHashedTransfers;
    
    event HashEvent(bytes32 newHash,uint8 eventType);

    constructor(address notarizerAddress,address verusBLAKE2b,address verusSerializerAddress) {
        blake2b = VerusBLAKE2b(verusBLAKE2b);
        verusSerializer = VerusSerializer(verusSerializerAddress);
        verusNotarizer = VerusNotarizer(notarizerAddress);   
    }

    function hashTransfers(VerusObjects.CReserveTransfer[] memory _transfers) public returns (bytes32){
        bytes memory sTransfers = verusSerializer.serializeCReserveTransfers(_transfers,false);
        return blake2b.createHash(sTransfers);
    }
    
    
    function checkTransfers(VerusObjects.CReserveTransferImport memory _import) public returns (bool){
        //identify if the hashed transfers are in the 
        testHashedTransfers = hashTransfers(_import.transfers);
        return true;
    }

    function checkProof(bytes32 hashToProve, VerusObjects.CTXProof[] memory _branches) public returns(bytes32){
        //loop through the branches from bottom to top
        bytes32 hashInProgress = hashToProve;
        for(uint i = 0; i < _branches.length; i++){
            hashInProgress = checkBranch(hashInProgress,_branches[i].proofSequence);
        }
        return hashInProgress;
    }

    function checkBranch(bytes32 _hashToCheck,VerusObjects.CMerkleBranch memory _branch) public returns(bytes32){
        
        require(_branch.nIndex >= 0,"Index cannot be less than 0");
        require(_branch.branch.length > 0,"Branch must be longer than 0");
        uint branchLength = _branch.branch.length;
        bytes32 hashInProgress;
        bytes memory joined;
        hashInProgress = blake2b.bytesToBytes32(abi.encodePacked(_hashToCheck));
        uint hashIndex = _branch.nIndex;
        
       for(uint i = 0;i < branchLength; i++){
            if(hashIndex & 1 > 0){
                require(_branch.branch[i] != _hashToCheck,"Value can be equal to node but never on the right");
                //join the two arrays and pass to blake2b
                joined = abi.encodePacked(_branch.branch[i],hashInProgress);
            } else {
                joined = abi.encodePacked(hashInProgress,_branch.branch[i]);
            }
            hashInProgress = blake2b.createHash(joined);
            hashIndex >>= 1;
        }

        return hashInProgress;

    }
    //roll through each proveComponents
    function proveComponents(VerusObjects.CReserveTransferImport memory _import) public returns(bytes32 txRoot){
        
        bytes32 hashInProgress;
        bytes32 testHash;
        
        if (_import.partialtransactionproof.components.length > 0)
        {   
             hashInProgress = blake2b.createHash(_import.partialtransactionproof.components[0].elVchObj);
            if (_import.partialtransactionproof.components[0].elType == 1 )
            {
                txRoot = checkProof(hashInProgress,_import.partialtransactionproof.components[0].elProof);           
            }
        }
        computedValues.push(txRoot);
        
        for(uint i = 1; i < _import.partialtransactionproof.components.length; i++){
            hashInProgress = blake2b.createHash(_import.partialtransactionproof.components[i].elVchObj);
            computedValues.push(hashInProgress);
            testHash = checkProof(hashInProgress,_import.partialtransactionproof.components[i].elProof);
            computedValues.push(testHash);
           if(txRoot != testHash){
               txRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
               break;
           }          
        }
        checkTransfers(_import);
        return txRoot;
        
    }
    
    function proveTransaction(VerusObjects.CReserveTransferImport memory _import) public returns(bytes32 stateRoot){
        bytes32 txRoot = proveComponents(_import);
        if(txRoot == 0x0000000000000000000000000000000000000000000000000000000000000000) return txRoot;
        
        return checkProof(txRoot,_import.partialtransactionproof.txproof);
    }
    

    function proveTransaction(bytes32 mmrRootHash,bytes32 notarisationHash,bytes32[] memory _transfersProof,uint32 _hashIndex) public returns(bool){
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


