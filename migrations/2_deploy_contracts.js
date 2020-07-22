var KomodoNotarize = artifacts.require("./komodoNotarize.sol");

module.exports = function(deployer) {
  deployer.deploy(KomodoNotarize);
};