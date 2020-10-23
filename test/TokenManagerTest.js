const assert = require('assert');

const TokenManager = artifacts.require("TokenManager");
const Token = artifacts.require("Token");
const VerusBridge = artifacts.require("VerusBridge");
const VerusNotarizer = artifacts.require("VerusNotarizer");
const MMRProof = artifacts.require("MMRProof");


/*
contract('TokenManager',(accounts) => {
        
    it('should create a coin', async () => {
        const tokenManagerInstance = await TokenManager.deployed();
        const newCoin = await tokenManagerInstance.deployNewToken("Test Coin 1","TST1"); 
        const isToken = await tokenManagerInstance.isToken("Test Coin 1");
        assert.equal(isToken,true,"Coin was not created");
        const isVerusOwned = await tokenManagerInstance.isVerusOwned("Test Coin 1");
        assert.equal(isVerusOwned,true,"Coin is not owned by verus");
    });
    it('send ERC20 Tokens should mint some coins', async () => {
        const tokenManagerInstance = await TokenManager.deployed();
        const newCoin = await tokenManagerInstance.deployNewToken("Test Coin 1","TST1"); 
        const coinAddress = await tokenManagerInstance.getTokenAddress("Test Coin 1");     
        //await tokenManagerInstance.mintToken(coinAddress,100,"0x30905b0623e4951C88c2f030f12B62ee81d4291c");
        let versusDefined = await tokenManagerInstance.isVerusOwned("Test Coin 1");

        let sendTokens = await tokenManagerInstance.sendERC20Tokens("Test Coin 1",100,accounts[0]);
        const accountBalance = await tokenManagerInstance.balanceOf(coinAddress,accounts[0]);
        
        assert.equal(accountBalance,100,"Didnt have 100 coins " + accountBalance);
        //check if it can burn tokens
        console.log(accountBalance);

        //need to approve the transfer of tokens to allow the contract to then be able to burn them
        const testToken = await Token.at(coinAddress);
        let ttresult = await testToken.approve(TokenManager.address,100);
        
       
        //tokenManagerInstance.approve(coinAddress,accounts[1],100);
        console.log(coinAddress,accounts[0],TokenManager.address);
        const allowance = await tokenManagerInstance.allowance(coinAddress,accounts[0],TokenManager.address);
        console.log(allowance);
        let receiveTokens = await tokenManagerInstance.receiveERC20Tokens("Test Coin 1",50);

    })    
});

contract('VerusBridge',(accounts) => {

    it('Verus created coin, inbound coin process',async () => {
        const verusNotarizerDeployed = await VerusNotarizer.deployed();
        const verusNotarizer = await VerusNotarizer.new();
        const mmrProofDeployed = await MMRProof.deployed();
        const mmrProof = await MMRProof.new();
        const tokenManagerInstance = await TokenManager.deployed();
        const verusBridgeInstance = await VerusBridge.deployed(verusNotarizer.address,mmrProof.address,tokenManagerInstance.address);
        //create a new coin
        let newToken = await verusBridgeInstance.createToken("vrsc.testcoin","TEST");
        let coinAddress = await verusBridgeInstance.getTokenAddress("vrsc.testcoin");
        const testToken = await Token.at(coinAddress);
        
        console.log("Token Address",coinAddress);

        let receiveTokens = await verusBridgeInstance.receiveFromVerusChain([[accounts[0],"vrsc.testcoin",1000]],1001,["0x7BefCcE8A84Bcb81B70A43a5233627B904159cEb"],1);
        
        let totalSupply = await testToken.totalSupply();
        assert.equal(totalSupply,1000,"Total Supply does not equal to 1000");
        let erc20Balance = await testToken.balanceOf(accounts[0]);
        assert.equal(erc20Balance,1000,"Accounts 0 balance is incorrect");

        console.log(receiveTokens);

        let transHash = await verusBridgeInstance.createTransactionsHash.call([[accounts[0],"vrsc.testcoin",1000]]);
        console.log("transhash:",transHash)

        let createdTransaction = await verusBridgeInstance.getCompletedInboundTransaction(transHash);
        console.log("createdTransaction:",createdTransaction);
        
        
        let accountBalance = await testToken.balanceOf(accounts[0]);
        assert.equal(accountBalance,1000,"Account does not have 1000 coins" + accountBalance);

        //approve for tokens to be moved over
        
        let ttresult = await testToken.approve(verusBridgeInstance.address,100);
        let allowance = await testToken.allowance(accounts[0],verusBridgeInstance.address);
        console.log("allowance:",allowance);
        totalSupply = await testToken.totalSupply();
        assert.equal(totalSupply,1000,"Total Supply is not equal to 1000");
    
        let sendToVerus = await verusBridgeInstance.sendToVerus("vrsc.testcoin",100,"0x7BefCcE8A84Bcb81B70A43a5233627B904159cEb");

        totalSupply = await testToken.totalSupply();
        console.log("totalSupply:",totalSupply);
        assert.equal(totalSupply,900,"Burn didnt work");

        erc20Balance = await testToken.balanceOf(accounts[0]);
        assert.equal(erc20Balance,900,"Accounts 0 balance is incorrect should be 900");
        let pendingOutboundTransactions = await verusBridgeInstance.getPendingOutboundTransactions();
        console.log("Pending Outbound Transactions: ",pendingOutboundTransactions);

        //repeat this 10 times to fill the transactions array
        await testToken.approve(verusBridgeInstance.address,500);
        for(let i = 0; i <= 10; i++){
            await verusBridgeInstance.sendToVerus("vrsc.testcoin",10,"0x7BefCcE8A84Bcb81B70A43a5233627B904159cEb");
        }
        pendingOutboundTransactions = await verusBridgeInstance.getPendingOutboundTransactions();
        console.log("Pending Outbound Transactions: ",pendingOutboundTransactions);

        let readyTransactionsIndex = await verusBridgeInstance.outboundTransactionsIndex();
        console.log("indes:",readyTransactionsIndex);
        let readyOutboundTransactions = await verusBridgeInstance.getTransactionsToProcess(readyTransactionsIndex - 1);
        
        console.log(readyOutboundTransactions);

    })

})

contract('VerusBridge',(accounts) => {
    it('Ethereum created coin, outbound coin process',async () => {
        //create a coin
        const testERC20Coin = await Token.new("eth.testcoin","TEST");
        await testERC20Coin.mint(accounts[0],1000);
        //add the coin to the token manager
        const verusNotarizerDeployed = await VerusNotarizer.deployed();
        const verusNotarizer = await VerusNotarizer.new();
        const mmrProofDeployed = await MMRProof.deployed();
        const mmrProof = await MMRProof.new();
        const tokenManagerInstance = await TokenManager.deployed();
        const verusBridgeInstance = await VerusBridge.deployed(verusNotarizer.address,mmrProof.address,tokenManagerInstance.address);

        await tokenManagerInstance.addExistingToken("eth.testcoin",testERC20Coin.address);
        let ttresult = await testERC20Coin.approve(verusBridgeInstance.address,100);
        let allowance = await testERC20Coin.allowance(accounts[0],verusBridgeInstance.address);
        let sendToVerus = await verusBridgeInstance.sendToVerus("eth.testcoin",100,"0x7BefCcE8A84Bcb81B70A43a5233627B904159cEb");
     
    });
});
*/

contract('VerusBridge',(accounts) => {
    it('BLAKE2b test ',async () => {
        const verusNotarizerDeployed = await VerusNotarizer.deployed();
        const verusNotarizer = await VerusNotarizer.new();
        const mmrProofDeployed = await MMRProof.deployed();
        const mmrProof = await MMRProof.new();
        const tokenManagerInstance = await TokenManager.deployed();
        const verusBridgeInstance = await VerusBridge.deployed(verusNotarizer.address,mmrProof.address,tokenManagerInstance.address);
        let hashKey = "0xbddd813c634239723171ef3fee98579b94964e3bb1cb3e427262c8c068d52319";
        //let generatedHash = await verusBridgeInstance.mmrHash.call("0x61626364","0x566572757344656661756c7448617368");
        //console.log(generatedHash);
        let flipped = await verusBridgeInstance.mmrHash.call("0x61626364",[]);
        //let stringBytes = await verusBridgeInstance.bytes32ToString(hashKey);

        console.log(flipped);

    });
});