const { getWeb3, getContractInstance } = require("./helper.js")
const web3 = getWeb3()
const getInstance = getContractInstance(web3)
const assert = require('assert');
const BigNumber = require('bignumber.js');


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

0x6574682e74657374636f696e3130307837426566436345384138344263623831423730413433613532333336323742393034313539634562
0x6574682e74657374636f696e0a307837426566436345384138344263623831423730413433613532333336323742393034313539634562
*/
contract('VerusBridge',(accounts) => {
    it('Ethereum created coin, outbound coin process',async () => {
        //create a coin

        function increaseHexByOne(hex) {
            let x = new BigNumber(hex)
            let sum = x.plus(1)
            let result = '0x' + sum.toString(16)
            return result
        }

        const testERC20Coin = await Token.new("eth.testcoin","TEST");
        await testERC20Coin.mint(accounts[0],10000000);
        //add the coin to the token manager
        const verusNotarizerDeployed = await VerusNotarizer.deployed();
        const verusNotarizer = await VerusNotarizer.new();
        const mmrProofDeployed = await MMRProof.deployed();
        const mmrProof = await MMRProof.new();
        const tokenManagerInstance = await TokenManager.deployed();
        const verusBridgeInstance = await VerusBridge.deployed(verusNotarizer.address,mmrProof.address,tokenManagerInstance.address);

        await tokenManagerInstance.addExistingToken("eth.testcoin",testERC20Coin.address);
        let ttresult = await testERC20Coin.approve(verusBridgeInstance.address,20000);
        let allowance = await testERC20Coin.allowance(accounts[0],verusBridgeInstance.address);
        /*
        for(let i = 0; i <= 21; i++){
            verusBridgeInstance.sendERC20ToVerus("eth.testcoin",(10 + i),"0x7BefCcE8A84Bcb81B70A43a5233627B904159cEb",{value: 100000000000000,from: accounts[0]});
            if(i < 1) {
                //build the string to hash
                let hexToHash = Buffer.concat([Buffer.from("0x7BefCcE8A84Bcb81B70A43a5233627B904159cEb"),Buffer.from("eth.testcoin"),Buffer.from([10])]).toString('hex');        
                console.log(i,":",hash + hexToHash);
                hash = await web3.utils.keccak256("0x" + hash + hexToHash);
            }
        }


        //let sendToVerus2 = await verusBridgeInstance.sendERC20ToVerus("eth.testcoin",10,"0x7BefCcE8A84Bcb81B70A43a5233627B904159cEb",{value: 100000000000000,from: accounts[0]});
        let readyTransactions = await verusBridgeInstance.getPendingOutboundTransactions();
        //console.log(readyTransactions);
        let transactionHash = await verusBridgeInstance.getTransactionsHash(0);
        console.log("transactions Hash 0:",transactionHash);
        transactionHash = await verusBridgeInstance.getTransactionsHash(1);
        console.log("transactions Hash 1:",transactionHash);

        */
        let amount = await verusBridgeInstance.sendEthToVerus("0x0584f1440d6F7e5AE5Ebe56D3ddE74B85dEFc0C7",{from: accounts[0],value:1000000000000000,gas: 3000000});
        console.log("amount:",amount);
        let transactions = await verusBridgeInstance.getPendingOutboundTransactions();
        console.log("transactions:",transactions);
        let feesHeld = await verusBridgeInstance.getFeesHeld();
        let ethHeld = await verusBridgeInstance.getEthHeld();

        console.log("fees:",feesHeld.toString()," eth:",ethHeld.toString());

     /*   let storage = await web3.eth.getStorageAt(verusBridgeInstance.address,0);
        console.log("storage token Manager Address:",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,1);
        console.log("storage verusNotarizer address???:",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,2);
        console.log("storage mmrProof???:",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,3);
        console.log("storage feesHeld:",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,4);
        console.log("storage ethHeld:",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,5);
        console.log("storage verusKey :",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,6);
        console.log("storage transactions per call:",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,7);
        console.log("VRSCEthTokenName:",web3.utils.toAscii(storage));
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,8);
        console.log("transaction fee:",storage);
        
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,9);
        console.log("pendingOutboundTransactions:",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,10);
        console.log("readyOutboundTransactions:",storage);*/
        /*
        let index = "0x000000000000000000000000000000000000000000000000000000000000000B";
        let key = web3.utils.sha3(index,{"encoding":"hex"});
        console.log(key);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,key);
        console.log("readyOutboundTransactionsHashes 0:",storage);
        console.log(increaseHexByOne(index));
        let newKey = increaseHexByOne(web3.utils.sha3(index, {"encoding":"hex"}))
        
        console.log(key);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,newKey);
        console.log("readyOutboundTransactionsHashes 0:",storage);
        */
        //let proof = await web3.eth.getProof(verusBridgeInstance.address,[key]);
        //console.log(proof);
    });
});

/*
contract('VerusBridge',(accounts) => {
    it('BLAKE2b test ',async () => {
        const verusNotarizerDeployed = await VerusNotarizer.deployed();
        const verusNotarizer = await VerusNotarizer.new();
        const mmrProofDeployed = await MMRProof.deployed();
        const mmrProof = await MMRProof.new();
        const tokenManagerInstance = await TokenManager.deployed();
        console.log("vnot",verusNotarizer.address);
        console.log("mmr:",mmrProof.address);
        console.log("tm:",tokenManagerInstance.address);
        const verusBridgeInstance = await VerusBridge.deployed(verusNotarizer.address,mmrProof.address,tokenManagerInstance.address);
        let hashKey = "0xbddd813c634239723171ef3fee98579b94964e3bb1cb3e427262c8c068d52319";
        //let generatedHash = await verusBridgeInstance.mmrHash.call("0x61626364","0x566572757344656661756c7448617368");
        //console.log(generatedHash);
        let flipped = await verusBridgeInstance.mmrHash.call("0x61626364",[]);
        //let stringBytes = await verusBridgeInstance.bytes32ToString(hashKey);

        console.log(flipped);
        let accounts = await web3.eth.getAccounts();
        console.log(accounts);
        let storage = await web3.eth.getStorageAt(verusBridgeInstance.address,0);
        console.log("storage token Manager Address:",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,1);
        console.log("storage verusNotarizer address???:",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,2);
        console.log("storage mmrProof???:",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,3);
        console.log("storage feesHeld:",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,4);
        console.log("storage ethHeld:",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,5);
        console.log("storage verusKey :",storage);
        storage = await web3.eth.getStorageAt(verusBridgeInstance.address,6);
        console.log("storage transactions per call:",storage);

    });
    //attempt to 
});*/