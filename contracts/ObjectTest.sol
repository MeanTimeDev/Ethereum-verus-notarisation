
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./VerusObjects.sol";

contract testObjects {

    function testCReserveTransferImport(CReserveTransferImport crt) public returns (CReserveTransferImport){
        return crt;
    }

    function testCReserveTransfer(CReserveTransfer crt) public returns (CReserveTransfer) {
        return crt;
    }

    function testCTransferDestination(CTransferDestination ctd) public returns (CTransferDestination) {
        return ctd;
    }

}