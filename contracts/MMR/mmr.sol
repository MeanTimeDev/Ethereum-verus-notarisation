// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 < 0.7.0;
pragma experimental ABIEncoderV2;

import "../MMR/VerusBLAKE2b.sol";

contract MMR {

    bytes32[][] mmr;
    bytes32[] peaks;
    constructor(address verusBLAKE2bAddress) public {
        blake2b = VerusBLAKE2b(verusBLAKE2bAddress);
    }

    function mmrSize() private returns(uint){
        return mmr[0].length;
    }

    function mmrHeight() private returns(uint){
        return mmr.length;
    }

    function createParentNode(bytes32 left, bytes32 right){
        bytes[] memory serializedNodes = abi.encodePacked(left,right);
        return blake2b.createHash(serializedNodes);
    }

    function addLeaf(bytes[] memory leaf) public returns(uint){

        bytes32 leafNode = blake2b.createHash(leaf);
        //add to the foot of the mountain
        uint leafIndex = mmr[0].push(leafNode);
        uint height = 1;
        for(uint layerSize = mmrSize(); height < mmrHeight(); height++){
            if(height == mmrHeight()){
                //this may not work
                mmr.push([]);
            }
            uint curSizeAbove = mmr[height].length;
            uint newSizeAbove = layerSize >> 1; 
            if (!(layerSize & 1) && newSizeAbove > curSizeAbove){
                //left Node to hash second to last element in array
                bytes32 leftNode = mmr[height-1][(mmr[height-1].length)-2];
                //right Node to hash last element in array
                bytes32 rightNode = mmr[height-1][(mmr[height-1].length)-1];
                //hash left and right
                bytes32 newNode = createParentNode(leftNode,rightNode);
                mmr[height].push(newNode);
            }
            layerSize = newSizeAbove;
        }
        return leafIndex;
    }

    function calcPeaks() private{
        peaks = [];
        //loop through the array
        //if the layer has an odd number of elements the last element is a peak
        //if the mmr has been resized then take it into account        
        uint levelSize = mmrSize;
        //loop through the levels collect any uneven items into the peaks array
        for(uint i = 0;i < mmrSize(); i++){
            bytes32[] level = mmr[i];
            if(levelSize & 1){
                peaks.push(level[levelSize -1]);
            }
            levelSuze = levelSize >> 1;
        }
    }
    //calculate root node
    function getRootNode() private returns (bytes32){
        if(!peaks.length) calcPeaks();
        bytes32 tempPeaks = peaks;
        //traverse it and 
        while(tempPeaks.length > 1){
            bytes32 newNode = createParentNode(tempPeaks[tempPeaks.length - 1],tempPeaks[tempPeaks.length - 2]);
            delete tempPeaks[tempPeaks.length -1];
            tempPeaks[tempPeaks.length -1] = newNode;
        }
        return tempPeaks[0];
    }


    struct MerkleBranch {
        uint branchType;
        uint nIndex;
        uint branchSize;
        bytes32[] branch;

    }

    function getProof(uint pos) private returns(MerkleBranch memory){
        if(!peaks.length) calcPeaks();
        MerkleBra


    }
}