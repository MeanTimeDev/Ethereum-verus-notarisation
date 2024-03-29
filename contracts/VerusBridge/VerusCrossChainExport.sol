// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../VerusBridge/VerusObjects.sol";
import "../VerusBridge/VerusSerializer.sol";

contract VerusCrossChainExport{

    VerusObjects.CCurrencyValueMap[] currencies;
    VerusObjects.CCurrencyValueMap[] fees;
    VerusSerializer verusSerializer;

    constructor(address _verusSerializerAddress) {
        verusSerializer = VerusSerializer(_verusSerializerAddress);
    }

    function inCurrencies(address checkCurrency) private view returns(int64){
        for(uint i = 0; i < uint64(currencies.length); i++){
            if(currencies[i].currency == checkCurrency) return int64(i);
        }
        return -1;
    }

    function inFees(address checkFeesCurrency) private view returns(int64){
        for(uint i = 0; i < uint64(fees.length); i++){
            if(fees[i].currency == checkFeesCurrency) return int64(i);
        }
        return -1;
    }

    function generateCCE(VerusObjects.CReserveTransfer[] memory transfers) public returns(VerusObjects.CCrossChainExport memory){

        VerusObjects.CCrossChainExport memory workingCCE;
        //create a hash of the transfers and then 
        bytes memory serializedTransfers = verusSerializer.serializeCReserveTransfers(transfers,false);
        bytes32 hashedTransfers = keccak256(serializedTransfers);

        //create the Cross ChainExport to then serialize and hash
        
        workingCCE.version = 1;
        workingCCE.flags = 2;
        //workingCCE.flags = 1;
        //need to pick up the 
        workingCCE.sourceheightstart = uint32(block.number);
        workingCCE.sourceheightend =uint32(block.number);
        workingCCE.sourcesystemid = VerusObjects.VEth;
        workingCCE.destinationsystemid = VerusObjects.VerusSystemId;
        workingCCE.destinationcurrencyid = VerusObjects.VerusSystemId;
        workingCCE.numinputs = uint32(transfers.length);
        //loop through the array and create totals of the amounts and fees
        
        int64 currencyExists;
        int64 feeExists;
        for(uint i = 0; i < transfers.length; i++){
            currencyExists = inCurrencies(transfers[i].currencyvalue.currency);
            if(currencyExists >= 0){
                currencies[uint256(currencyExists)].amount += transfers[i].currencyvalue.amount;
            } else {
                currencies.push(VerusObjects.CCurrencyValueMap(transfers[i].currencyvalue.currency,transfers[i].currencyvalue.amount));
            }
            feeExists = inFees(transfers[i].feecurrencyid); 
            if(feeExists >= 0){
                fees[uint256(feeExists)].amount += uint64(transfers[i].fees);
            } else {
                fees.push(VerusObjects.CCurrencyValueMap(transfers[i].feecurrencyid,uint64(transfers[i].fees)));
            }
            
        }
        workingCCE.totalamounts = currencies;
        workingCCE.totalfees = fees;

        workingCCE.hashtransfers = hashedTransfers;
        VerusObjects.CCurrencyValueMap memory totalburnedCCVM = VerusObjects.CCurrencyValueMap(0x0000000000000000000000000000000000000000,0);
        
        workingCCE.totalburned = new VerusObjects.CCurrencyValueMap[](1);
        workingCCE.totalburned[0] = totalburnedCCVM;
        workingCCE.rewardaddress = VerusObjects.CTransferDestination(VerusObjects.RewardAddressType,address(VerusObjects.RewardAddress));
        workingCCE.firstinput = 0;

        //clear the arrays
        delete currencies;
        delete fees;

        return workingCCE;

    }
    
    

}