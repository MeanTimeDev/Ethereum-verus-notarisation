// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../VerusBridge/VerusObjects.sol";
import "../VerusBridge/VerusSerializer.sol";
import "../MMR/VerusBLAKE2b.sol";

contract generateCrossChainExport{

    VerusObjects.CCurrencyValueMap[] currencies;
    VerusObjects.CCurrencyValueMap[] fees;
    VerusBLAKE2b blake2b;
    VerusSerializer verusSerializer;

    constructor(address _verusBLAKE2bAddress,address _verusSerializerAddress) public {
        verusSerializer = VerusSerializer(_verusSerializerAddress);
        blake2b = VerusBLAKE2b(_verusBLAKE2bAddress);
    }

    function inCurrencies(address checkCurrency) private returns(int){
        for(uint i = 0; i < currencies.length; i++){
            if(currencies[i].currency == checkCurrency) return i;
        }
        return -1;
    }

    function inFees(address checkFeesCurrency) private returns(int){
        for(uint i = 0; i < fees.length; i++){
            if(fees[i].currency == checkFeesCurrency) return i;
        }
        return -1;
    }

    function generateCCE(VerusObjects.CReserveTransfer[] transfers) public returns(VerusObjects.CCrossChainExport){

         bytes32 hashedTransfers;
        //create a hash of the transfers and then 
        hashedTransfers = blake2b.createHash(verusSerializer.serializeCReserveTransfers(transfers));

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
        workingCCE.numinputs = int32(transfers.length);
        //loop through the array and create totals of the amounts and fees
        workingCCE.totalamounts = new VerusObjects.CCurrencyValueMap[](currencyAddresses.length);

        int currencyExists;
        int feeExists;
        for(uint i = 0; i < _readyExports[exportIndex].length; i++){
            
            if(currencyExists = inCurrencies(transfers[i].currencyvalues.currency) >= 0){
                currencies[currencyExists].amount += transfers[i].currencyvalues.amount;
            } else {
                currencies.push(VerusObjects.CCurrencyValueMap(transfers[i].currencyvalues.currency,transfers[i].currencyvalues.amount));
            }

            if(feeExists = inFees(transfers[i].currencyvalues.currency) >= 0){
                fees[feeExists].amount += uint64(transfers[i].fees);
            } else {
                fees.push(VerusObjects.CCurrencyValueMap(transfers[i].feescurrencyid,uint64(transfers[i].fees)));
            }
        }
        workingCCE.totalamounts = currencies;
        workingCCE.totalfees = fees;

        workingCCE.hashtransfers = uint256(hashedTransfers);
        VerusObjects.CCurrencyValueMap memory totalburnedCCVM = VerusObjects.CCurrencyValueMap(0,0);
        
        workingCCE.totalburned = new VerusObjects.CCurrencyValueMap[](1);
        workingCCE.totalburned[0] = totalburnedCCVM;
        workingCCE.rewardaddress = address(RewardAddress);
        workingCCE.firstinput = 0;

        //clear the arrays
        delete currencies;
        delete fees;

        return workingCCE;

    }

}