pragma solidity >=0.5.16 <0.7.1;
contract GasTest{
  uint lastGas;
  uint constant calibration = 5194;
  event LogGas(string message, int gas);

  function Log(string memory message) public {
    uint gasLeft = gasleft();
      if(lastGas == 0){
        lastGas = gasLeft;
      }
      emit LogGas(message, int(lastGas - gasLeft - calibration));
      lastGas = gasLeft;
  }

  event LogVal(string message, bytes32 v);
}
