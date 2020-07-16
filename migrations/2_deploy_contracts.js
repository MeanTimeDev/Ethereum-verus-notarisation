var KomodoNotarise = artifacts.require("./komodoNotarise.sol");

module.exports = function(deployer) {
  deployer.deploy(KomodoNotarise);
};