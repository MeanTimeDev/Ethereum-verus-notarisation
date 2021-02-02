// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;
import "./BLAKE2b/BLAKE2b.sol";
import "../VerusBridge/VerusObjects.sol";
import "../VerusBridge/VerusSerializer.sol";
import "../VerusNotarizer/VerusNotarizer.sol";

contract VerusProof{

    uint256 mmrRoot;
    BLAKE2b blake2b;
    VerusNotarizer verusNotarizer;
    VerusSerializer verusSerializer;
    bytes verusKey = "VerusDefaultHash";
    event JoinEvent(bytes joinedValue,uint8 eventType);
    event HashEvent(bytes32 newHash,uint8 eventType);

    constructor(address notarizerAddress) public{
        blake2b = new BLAKE2b();
        verusNotarizer = VerusNotarizer(notarizerAddress);   
    }

    function proveTransferSet(VerusObjects.CTransferSet memory _setToProve,bytes32[] memory _transfersProof,uint32 _hashIndex,uint32 _blockHeight)public returns(bool){
        bytes32 transferSetHash = createHash(verusSerializer.serializeCTransferSet(_setToProve),verusKey);
        
        //get the notarized block for that block height ? could it work if its greater than that blockheight
        VerusNotarizer.NotarizedData memory verusNotarizedData = verusNotarizer.getNotarizedData(_blockHeight);
        bytes32 mmrRootHash = bytes32(verusNotarizedData.mmrRoot);
        
        if (mmrRootHash == predictedRootHash(transferSetHash,_hashIndex,_transfersProof)) return true;
        else return false;
    }

    function predictedRootHash(bytes32 _hashToCheck,uint _hashIndex,bytes32[] memory _branch) public returns(bytes32){
        
        require(_hashIndex >= 0,"Index cannot be less than 0");
        require(_branch.length > 0,"Branch must be longer than 0");
        uint branchLength = _branch.length;
        bytes32 hashInProgress;
        uint64[8] memory blakeResult;
        bytes memory joined;
        verusKey = "";
        hashInProgress = bytesToBytes32(abi.encodePacked(_hashToCheck));

       for(uint i = 0;i < branchLength; i++){
            if(_hashIndex & 1 > 0){
                require(_branch[i] != _hashToCheck,"Value can be equal to node but never on the right");
                //join the two arrays and pass to blake2b
                joined = abi.encodePacked(_branch[i],hashInProgress);
                emit JoinEvent(joined,1);
            } else {
                joined = abi.encodePacked(hashInProgress,_branch[i]);
                emit JoinEvent(joined,2);
            }
            blakeResult = blake2b.blake2b(joined,verusKey,32);
            hashInProgress = bytesToBytes32(abi.encodePacked(blakeResult[0],blakeResult[1],blakeResult[2],blakeResult[3],
                blakeResult[4],blakeResult[5],blakeResult[6],blakeResult[7]));
            emit HashEvent(hashInProgress,3);
            _hashIndex >>= 1;
        }

        return hashInProgress;

    }

    function checkHashInRoot(bytes32 _mmrRoot,bytes32 _hashToCheck,uint _hashIndex,bytes32[] memory _branch) public returns(bool){
        bytes32 calculatedHash = predictedRootHash(_hashToCheck,_hashIndex,_branch);
        if(_mmrRoot == calculatedHash) return true;
        else return false;
    }

    function bytesToBytes32(bytes memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function createHash(bytes memory toHash,bytes memory personalisation,bool flipped) public returns(bytes32){
        uint64[8] memory blakeResult;
        bytes memory testInput = abi.encodePacked(toHash);
        bytes memory key;
        bytes memory salt;

        blakeResult = blake2b.blake2b(testInput,key,salt,personalisation,32);
        bytes memory hashInProgress = abi.encodePacked(blakeResult[0],blakeResult[1],blakeResult[2],blakeResult[3],
                blakeResult[4],blakeResult[5],blakeResult[6],blakeResult[7]);

        //we flip the bytes array to match up with Verus Hash    
        bytes32 bytes32hash = bytesToBytes32(hashInProgress);   
        if(flipped == true) bytes32hash = reverseBytes(bytes32hash);
        emit HashEvent(bytes32hash,1);
        return bytes32hash;
    }

    function createHash(bytes memory toHash,bytes memory personalisation) public returns(bytes32){
        return createHash(toHash,personalisation,false);
    }
    
    function createHash(bytes memory toHash) public returns(bytes32){
        return createHash(toHash,verusKey,false);
    }

    function reverseBytes(bytes32 _bytes32) public pure returns (bytes32) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[(31-i)];
        }
        return bytesToBytes32(bytesArray);
    }

    function create64Hash(bytes memory testString,bytes memory key) public returns(bytes memory){
        uint64[8] memory blakeResult;
        bytes memory testInput = abi.encodePacked(testString);
        
        blakeResult = blake2b.blake2b(testInput,key,64);
        bytes memory hashInProgress = abi.encodePacked(blakeResult[0],blakeResult[1],blakeResult[2],blakeResult[3],
                blakeResult[4],blakeResult[5],blakeResult[6],blakeResult[7]);
        return hashInProgress;
    }
}
