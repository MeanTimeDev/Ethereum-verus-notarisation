pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./TokenManager.sol";
import "../MMR/MMRProof.sol";
import "../VerusNotarizer/VerusNotarizer.sol";
import { Memory } from "../Standard/Memory.sol";

contract MMRTest {
    
    TokenManager tokenManager;
    VerusNotarizer verusNotarizer;
    MMRProof mmrProof;

    constructor(address notarizerAddress,address mmrProofAddress) public {
       mmrProof =  MMRProof(mmrProofAddress);
        verusNotarizer = VerusNotarizer(notarizerAddress);
        tokenManager = new TokenManager();
        
    }
/*
    function mmrHash(bytes memory toHash) public returns(bytes32){
        //bytes32 generatedHash = mmrProof.createHash(toHash);
       // return generatedHash;
    }*/
}