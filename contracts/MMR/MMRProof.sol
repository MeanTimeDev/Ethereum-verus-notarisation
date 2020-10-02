// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.7.0;
import "./BLAKE2B/BLAKE2b.sol";
pragma experimental ABIEncoderV2;

contract MMRProof{

    uint256 mmrRoot;
    BLAKE2b blake2b;
    bytes verusKey = "VerusDefaultHash";
    event JoinEvent(bytes joinedValue,uint8 eventType);
    event HashEvent(bytes32 newHash,uint8 eventType);

    constructor() public{
        blake2b = new BLAKE2b();
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

    function createHash(bytes memory testString,bytes memory key) public returns(bytes32){
        uint64[8] memory blakeResult;
        bytes memory testInput = abi.encodePacked(testString);
        
        blakeResult = blake2b.blake2b(testInput,key,32);
        bytes memory hashInProgress = abi.encodePacked(blakeResult[0],blakeResult[1],blakeResult[2],blakeResult[3],
                blakeResult[4],blakeResult[5],blakeResult[6],blakeResult[7]);
        return bytesToBytes32(hashInProgress);
    }

    function create64Hash(bytes memory testString,bytes memory key) public returns(bytes memory){
        uint64[8] memory blakeResult;
        bytes memory testInput = abi.encodePacked(testString);
        
        blakeResult = blake2b.blake2b(testInput,key,64);
        bytes memory hashInProgress = abi.encodePacked(blakeResult[0],blakeResult[1],blakeResult[2],blakeResult[3],
                blakeResult[4],blakeResult[5],blakeResult[6],blakeResult[7]);
        return hashInProgress;
    }

    /*
    function testMMR(string memory testString) public returns(bytes32){
        uint64[8] memory blakeResult;
        bytes memory testInput = bytes(testString);
        verusKey = "";
        blakeResult = blake2b.blake2b(testInput,verusKey,32);
        bytes memory hashInProgress = abi.encodePacked(blakeResult[0],blakeResult[1],blakeResult[2],blakeResult[3],
                blakeResult[4],blakeResult[5],blakeResult[6],blakeResult[7]);
        return bytesToBytes32(hashInProgress);
    }

    function testMMRBytes(bytes memory testInput) public returns(bytes32){
        uint64[8] memory blakeResult;
        verusKey = "";
        blakeResult = blake2b.blake2b(testInput,verusKey,32);
        bytes memory hashInProgress = abi.encodePacked(blakeResult[0],blakeResult[1],blakeResult[2],blakeResult[3],
                blakeResult[4],blakeResult[5],blakeResult[6],blakeResult[7]);
        return bytesToBytes32(hashInProgress);
    }



    */
}
