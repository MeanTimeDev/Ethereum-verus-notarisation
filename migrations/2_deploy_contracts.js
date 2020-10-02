var VerusNotarize = artifacts.require("./VerusNotarizer/VerusNotarizer.sol");
var VerusBridge = artifacts.require("./VerusBridge/VerusBridge.sol");
var TokenManager = artifacts.require("./VerusBridge/TokenManager.sol");
var MMRProof = artifacts.require("./VerusBridge/MMRProof.sol");
module.exports = function(deployer) {
  deployer.deploy(TokenManager);
  deployer.deploy(MMRProof);
  deployer.deploy(VerusNotarize).then(() => {
    return deployer.deploy(VerusBridge,VerusNotarize.address,MMRProof.address,TokenManager.address);
  });
  
};
