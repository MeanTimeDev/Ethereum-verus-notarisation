var VerusTokenManager = artifacts.require("./VerusBridge/TokenManager.sol");
var VerusBlake2b = artifacts.require("./MMR/VerusBLAKE2b.sol");
var VerusSerializer = artifacts.require("./VerusBridge/VerusSerializer.sol");
var VerusNotarizer = artifacts.require("./VerusNotarizer/VerusNotarizer.sol");
var VerusProof = artifacts.require("./VerusNotarizer/VerusNotarizer.sol");
var VerusCCE = artifacts.require("./VerusBridge/VerusCrossChainExport.sol");
var VerusBridge = artifacts.require("./VerusBridge/VerusBridge.sol");
var Verusaddress = artifacts.require("./VerusBridge/VerusAddressCalculator.sol");
var VerusInfo = artifacts.require("./VerusBridge/VerusInfo.sol");

const verusNotariserIDS = ["0xb26820ee0c9b1276aac834cf457026a575dfce84","0x51f9f5f053ce16cb7ca070f5c68a1cb0616ba624","0x65374d6a8b853a5f61070ad7d774ee54621f9638"];
const verusNotariserSigner = ["0xD010dEBcBf4183188B00cafd8902e34a2C1E9f41","0xD010dEBcBf4183188B00cafd8902e34a2C1E9f41","0xD010dEBcBf4183188B00cafd8902e34a2C1E9f41"];
const tokenmanvrsctest = ["0xA6ef9ea235635E328124Ff3429dB9F9E91b64e2d","VRSCTEST","VRST"]

module.exports = function (deployer) {
     
    await deployer.deploy(Verusaddress)
    const addressInst = await Verusaddress.deployed();

    await deployer.link(Verusaddress,VerusTokenManager );
    await deployer.deploy(VerusTokenManager)
    const tokenInst = await VerusTokenManager.deployed();
    
    await deployer.deploy(VerusBlake2b);
    const blakeInst = await VerusBlake2b.deployed();
 
    await deployer.deploy(VerusSerializer);
    const serializerInst = await VerusSerializer.deployed();

    await tokenInst.deployNewToken(tokenmanvrsctest[0],tokenmanvrsctest[1],tokenmanvrsctest[2]);
 
    await deployer.deploy(VerusNotarizer,blakeInst.address,serializerInst.address,verusNotariserIDS,verusNotariserSigner);
    const notarizerInst = await VerusNotarizer.deployed();

    await deployer.deploy(VerusProof,notarizerInst.address,blakeInst.address,serializerInst.address);
    const ProofInst = await VerusProof.deployed();

    await deployer.deploy(VerusCCE,serializerInst.address);
    const CCEInst = await VerusCCE.deployed();
 
    await deployer.deploy(VerusBridge,ProofInst.address, tokenInst.address, serializerInst.address,
                              notarizerInst.address, CCEInst.address, "5000000000000000000000");
    const VerusBridgeInst = await VerusBridge.deployed();

    
    await deployer.deploy(VerusInfo, VerusBridgeInst.address,"2000753","0.7.3-9-rc1","VETH",true);
    const CCEInst = await VerusInfo.deployed();

};