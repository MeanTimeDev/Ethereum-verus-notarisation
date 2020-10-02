pragma solidity >=0.4.20;
pragma experimental ABIEncoderV2;

import "./Token.sol";

contract TokenManager {

    event TokenCreated(address tokenAddress);
    //array of contracts address mapped to the token name
    struct hostedToken{
        address contractAddress;
        bool VerusOwned;
        bool isRegistered;
    }
    mapping(string => hostedToken) vERC20Tokens;
    mapping(address => string) vERC20TokenNames;

    //receive tokens that arent owned by the contract these would need to be authorised before transfer
    function receiveERC20Tokens(address contractAddress,uint256 tokenAmount) public {
        //transfer the tokens to the contract address
        //if its not approved it wont work
        Token token = Token(contractAddress);
        uint256 allowedTokens = token.allowance(msg.sender,address(this));
        require( allowedTokens >= tokenAmount,"Not enough tokens have been approved");
        token.transferFrom(msg.sender,address(this),tokenAmount);   
        
        string memory tokenName = vERC20TokenNames[contractAddress];
        hostedToken memory tokenDetail = vERC20Tokens[tokenName];
        //if the token has been cerated by this contract then burn the token
        if(tokenDetail.VerusOwned){
            require(token.balanceOf(address(this)) >= tokenAmount,"Tokens didnt transfer");
            burnToken(contractAddress,tokenAmount);
        } else {
            //the contract stores the token
        }
    }

    function receiveERC20Tokens(string memory tokenName,uint256 tokenAmount) public {
        address contactAddress = getTokenAddress(tokenName);
        receiveERC20Tokens(contactAddress,tokenAmount);
    }
    
    function sendERC20Tokens(address contractAddress,uint256 tokenAmount,address destinationAddress) public returns(bool){
        string memory tokenName = vERC20TokenNames[contractAddress];
        hostedToken memory tokenDetail = vERC20Tokens[tokenName];
        
        //if the token has been created by this contract then burn the token
        
        if(tokenDetail.VerusOwned){
            mintToken(contractAddress,tokenAmount,destinationAddress);
        } else {
            //transfer from the 
            Token token = Token(contractAddress);
            token.transfer(destinationAddress,tokenAmount);   
        }
    }

    function sendERC20Tokens(string memory tokenName,uint256 tokenAmount,address destinationAddress) public {
        address contactAddress = getTokenAddress(tokenName);
        sendERC20Tokens(contactAddress,tokenAmount,destinationAddress);        
    }

    function deployNewToken(string memory tokenName, string memory symbol)
    public returns (address) {
        if(isToken(tokenName)) return getTokenAddress(tokenName);
        Token t = new Token(tokenName, symbol);
        vERC20Tokens[tokenName]= hostedToken(address(t),true,true);
        vERC20TokenNames[address(t)] = tokenName;
        emit TokenCreated(address(t));
        return address(t);
    }

    function balanceOf(address contractAddress,address account) public view returns(uint256){
        Token token = Token(contractAddress);
        return token.balanceOf(account);
    }
    function approve(address contractAddress,address spender, uint256 amount) public {
        Token token = Token(contractAddress);
        token.approve(spender,amount);
    }
    function allowance(address contractAddress,address owner, address spender) public view returns(uint256){
        Token token = Token(contractAddress);
        return token.allowance(owner,spender);
    }

    function mintToken(address contractAddress,uint256 mintAmount,address recipient) public {
        Token token = Token(contractAddress);
        token.mint(recipient,mintAmount);
    }

    function burnToken(address contractAddress,uint burnAmount) public {
        Token token = Token(contractAddress);
        token.burn(burnAmount);
    }

    function addExistingToken(string memory name, address contactAddress) public{
        require(!isToken(name));
        vERC20Tokens[name] = hostedToken(contactAddress,false,true);
    }

    function isToken(string memory name) public view returns(bool){
        if(vERC20Tokens[name].isRegistered) return true;
        else return false;
    }

    function isVerusOwned(string memory name) public view returns(bool){
        if(vERC20Tokens[name].VerusOwned) return true;
        else return false;
    }

    function getTokenAddress(string memory name) public view returns(address){
        return vERC20Tokens[name].contractAddress;
    }

    function getTokenName(address tokenAddress) public view returns(string memory){
        return vERC20TokenNames[tokenAddress];
    }


}