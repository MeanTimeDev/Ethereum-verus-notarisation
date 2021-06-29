// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../VerusBridge/VerusObjects.sol";
import "../VerusBridge/VerusSerializer.sol";
import "../MMR/VerusBLAKE2b.sol";

contract VerusCrossChainExport{

    VerusObjects.CCurrencyValueMap[] currencies;
    VerusObjects.CCurrencyValueMap[] fees;
    VerusBLAKE2b blake2b;
    VerusSerializer verusSerializer;


    uint160 public VEth = uint160(0x0000000000000000000000000000000000000000);
    uint160 public EthSystemID = uint160(0x0000000000000000000000000000000000000000);
    uint160 public VerusSystemId = uint160(0x0000000000000000000000000000000000000001);
    uint160 public RewardAddress = uint160(0x0000000000000000000000000000000000000002);

    constructor(address _verusBLAKE2bAddress,address _verusSerializerAddress) public {
        verusSerializer = VerusSerializer(_verusSerializerAddress);
        blake2b = VerusBLAKE2b(_verusBLAKE2bAddress);
    }

    function inCurrencies(uint160 checkCurrency) private view returns(int64){
        for(uint i = 0; i < uint64(currencies.length); i++){
            if(currencies[i].currency == checkCurrency) return int64(i);
        }
        return -1;
    }

    function inFees(uint160 checkFeesCurrency) private view returns(int64){
        for(uint i = 0; i < uint64(fees.length); i++){
            if(fees[i].currency == checkFeesCurrency) return int64(i);
        }
        return -1;
    }

    function generateCCE(VerusObjects.CReserveTransfer[] memory transfers) public returns(VerusObjects.CCrossChainExport memory){

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
        
        int64 currencyExists;
        int64 feeExists;
        for(uint i = 0; i < transfers.length; i++){
            currencyExists = inCurrencies(transfers[i].currencyvalues.currency);
            if(currencyExists >= 0){
                currencies[uint256(currencyExists)].amount += transfers[i].currencyvalues.amount;
            } else {
                currencies.push(VerusObjects.CCurrencyValueMap(transfers[i].currencyvalues.currency,transfers[i].currencyvalues.amount));
            }
            feeExists = inFees(transfers[i].currencyvalues.currency); 
            if(feeExists >= 0){
                fees[uint256(feeExists)].amount += uint64(transfers[i].fees);
            } else {
                fees.push(VerusObjects.CCurrencyValueMap(transfers[i].feecurrencyid,uint64(transfers[i].fees)));
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