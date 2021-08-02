// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../MMR/VerusBLAKE2b.sol";
import { Memory } from "../Standard/Memory.sol";
import "./VerusObjects.sol";
import "./VerusSerializer.sol";
import "../VerusNotarizer/VerusNotarizer.sol";

contract VerusCCE {
    
    VerusBLAKE2b blake2b; 
    VerusSerializer verusSerializer;
    
    constructor(address verusBLAKE2bAddress,address verusSerializerAddress) public {
        verusSerializer = VerusSerializer(verusSerializerAddress);
        blake2b = VerusBLAKE2b(verusBLAKE2bAddress);
    }
    
    uint160[] _currencyAddresses;
    uint64[] _currencyAmounts;
    uint160[] _feesCurrencies;
    uint64[] _feesAmounts;
    
    address public VEth = uint160(0x0000000000000000000000000000000000000000);
    address public EthSystemID = uint160(0x0000000000000000000000000000000000000000);
    address public VerusSystemId = uint160(0x0000000000000000000000000000000000000001);
    //does this need to be set 
    address public RewardAddress = uint160(0x0000000000000000000000000000000000000002);

    //create a cross chain export and serialize it for hashing 
    function createCCrossChainExport(VerusObjects.CReserveTransfer[] memory _readyExports) public returns (VerusObjects.CCrossChainExport memory){
        bytes32 hashedTransfers;
        //create a hash of the transfers and then 
        hashedTransfers = blake2b.createHash(verusSerializer.serializeCReserveTransfers(_readyExports));

        //create the Cross ChainExport to then serialize and hash

        VerusObjects.CCrossChainExport memory workingCCE;
        workingCCE.version = 1;
        workingCCE.flags = 3;
        //need to pick up the 
        workingCCE.sourceheightstart = uint32(block.number);
        workingCCE.sourceheightend =uint32(block.number);
        workingCCE.sourcesystemid = EthSystemID;
        workingCCE.destinationsystemid = VerusSystemId;
        workingCCE.destinationcurrencyid = VEth;
        workingCCE.numinputs = int32(_readyExports.length);
        //loop through the array and create totals of the amounts and fees

        //how to calculate the length of the CCurrencyValueMap arrays before the can be created

        for(uint i = 0; i < _readyExports.length; i++){
            
            address currencyAddress = _readyExports[i].currencyvalues.currency;
            uint64 currencyAmount = _readyExports[i].currencyvalues.amount;
            bool currencyExists = false;
            for(uint j = 0; j < _currencyAddresses.length; j++){
                if(_currencyAddresses[j] == currencyAddress) {
                    _currencyAmounts[j] += currencyAmount;
                    currencyExists = true;
                    break;
                }
            }
            if(currencyExists == false){
                _currencyAddresses.push(currencyAddress);
                _currencyAmounts.push(currencyAmount);
            }    
            
            address feecurrency = _readyExports[i].feecurrencyid;
            uint64 feeamount = uint64(_readyExports[i].fees);
            currencyExists = false;
            for(uint k = 0; k < _feesCurrencies.length; k++){
                if(_feesCurrencies[k] == feecurrency) {
                    _feesAmounts[k] += feeamount;
                    currencyExists = true;
                    break;
                }
            }
            if(currencyExists == false){
                _feesCurrencies.push(feecurrency);
                _feesAmounts.push(feeamount);
            }
            
        }
    
        //create the total amounts arrays
        workingCCE.totalamounts = new VerusObjects.CCurrencyValueMap[](_currencyAddresses.length);
        for(uint l = 0; l < _currencyAddresses.length ; l++){
            workingCCE.totalamounts[l] = VerusObjects.CCurrencyValueMap(_currencyAddresses[l],_currencyAmounts[l]);
        }
        
        workingCCE.totalfees = new VerusObjects.CCurrencyValueMap[](_feesCurrencies.length);
        for(uint l = 0; l < _feesCurrencies.length ; l++){
            workingCCE.totalfees[l] = VerusObjects.CCurrencyValueMap(_feesCurrencies[l],_feesAmounts[l]);
        }
    
        workingCCE.hashtransfers = uint256(hashedTransfers);
        VerusObjects.CCurrencyValueMap memory totalburnedCCVM = VerusObjects.CCurrencyValueMap(0,0);
        
        workingCCE.totalburned = new VerusObjects.CCurrencyValueMap[](1);
        workingCCE.totalburned[0] = totalburnedCCVM;
        workingCCE.rewardaddress = address(RewardAddress);
        workingCCE.firstinput = 0;
        
        delete _currencyAddresses;
        delete _currencyAmounts;
        delete _feesCurrencies;
        delete _feesAmounts;
        
        return workingCCE;
    }
}