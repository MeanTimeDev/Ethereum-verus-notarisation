// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.4.20;
pragma experimental ABIEncoderV2;

import "./Token.sol";
import "./VerusAddressCalculator.sol";

contract TokenManager {

    event TokenCreated(address tokenAddress);
    //array of contracts address mapped to the token name
    struct hostedToken{
        uint160 destinationCurrencyID;
        bool VerusOwned;
        bool isRegistered;
    }
    
    mapping(uint160 => address) public destinationToAddress;
    mapping(address => hostedToken) public vERC20Tokens;
    
    address verusBridgeContract;
    
    constructor() public {
        verusBridgeContract = address(0);
    }
    
    function setVerusBridgeContract(address _verusBridgeContract) public {
        require(verusBridgeContract == address(0),"verusBridgeContract Address has already been set.");
        verusBridgeContract = _verusBridgeContract;
    }
    
    function isVerusBridgeContract() private view returns(bool){
        return msg.sender == verusBridgeContract;
    }
    
    //Tokens that are being exported from the eth blockchain are either destroyed or held until imported
    function exportERC20Tokens(address contractAddress,uint256 tokenAmount) public {
        require(isVerusBridgeContract(),"Call can only be made from Verus Bridge Contract");
        //check that the erc20 token is registered with the tokenManager
        require(isToken(contractAddress),"Token has not been registered yet");
        
        Token token = Token(contractAddress);
        hostedToken memory tokenDetail;
        //transfer the tokens to the contract address
        uint256 allowedTokens = token.allowance(msg.sender,address(this));
        require( allowedTokens >= tokenAmount,"Not enough tokens have been approved");
        //if its not approved it wont work
        token.transferFrom(msg.sender,address(this),tokenAmount);   
        
        if(!isToken(contractAddress)){
            tokenDetail = vERC20Tokens[contractAddress];
            //if the token has been cerated by this contract then burn the token
        }
        if(tokenDetail.VerusOwned){
                require(token.balanceOf(address(this)) >= tokenAmount,"Tokens didnt transfer");
                burnToken(contractAddress,tokenAmount);
        } else {
            //the contract stores the token
        }
    }

    function exportERC20Tokens(uint160 destCurrencyID,uint256 tokenAmount) public {
        require(isVerusBridgeContract(),"Call can only be made from Verus Bridge Contract");
        address contactAddress = destinationToAddress[destCurrencyID];
        exportERC20Tokens(contactAddress,tokenAmount);
    }
    
    //Tokens that are being imported into the eth blockchain are either minted or transferred from a reserve
    function importERC20Tokens(address contractAddress,uint256 tokenAmount,address destinationAddress) public returns(bool){
        require(isVerusBridgeContract(),"Call can only be made from Verus Bridge Contract");
        hostedToken memory tokenDetail = vERC20Tokens[contractAddress];
        //if the token has been created by this contract then burn the token
        if(tokenDetail.VerusOwned){
            mintToken(contractAddress,tokenAmount,destinationAddress);
        } else {
            //transfer from the 
            Token token = Token(contractAddress);
            token.transfer(destinationAddress,tokenAmount);   
        }
    }

    function importERC20Tokens(uint160 destCurrencyID,uint64 tokenAmount,uint160 destination) public returns(bool){
        require(isVerusBridgeContract(),"Call can only be made from Verus Bridge Contract");
        address contractAddress;
        //if the token has not been previously created then it must be deployed
        //require(isToken(destCurrencyID),"Token is not registered");
        if(!isToken(destCurrencyID)) {
            contractAddress = deployNewToken(destCurrencyID);
        } else {
            contractAddress = destinationToAddress[destCurrencyID];
        }

        hostedToken memory tokenDetail = vERC20Tokens[contractAddress];
        //if the token has been created by this contract then burn the token
        if(tokenDetail.VerusOwned){
            mintToken(contractAddress,uint256(tokenAmount),address(destination));
        } else {
            //transfer from the 
            Token token = Token(contractAddress);
            token.transfer(address(destination),tokenAmount);   
        }
    }

    function balanceOf(address contractAddress,address account) public view returns(uint256){
        Token token = Token(contractAddress);
        return token.balanceOf(account);
    }
    function allowance(address contractAddress,address owner, address spender) public view returns(uint256){
        Token token = Token(contractAddress);
        return token.allowance(owner,spender);
    }

    function mintToken(address contractAddress,uint256 mintAmount,address recipient) private {
        Token token = Token(contractAddress);
        token.mint(recipient,mintAmount);
    }

    function burnToken(address contractAddress,uint burnAmount) private {
        Token token = Token(contractAddress);
        token.burn(burnAmount);
    }

    function addExistingToken(address contractAddress) public returns(uint160){
        require(!isToken(contractAddress),"Token is already registered");
        //generate a uint160 for the token name
        Token token = Token(contractAddress);
        uint160 destinationCurrencyID = generateDestinationCurrencyID(token.name());
        vERC20Tokens[contractAddress] = hostedToken(destinationCurrencyID,false,true);
        destinationToAddress[destinationCurrencyID] = contractAddress;
        return destinationCurrencyID;
    }

    function deployNewToken(uint160 destinationCurrencyID) public returns (address) {
        require(isVerusBridgeContract(),"Call can only be made from Verus Bridge Contract");
        //generate a name based on the uint160 and deploy the token
        string memory IDAsString; IDAsString= VerusAddressCalculator.uint160ToString(destinationCurrencyID);
        
        //capitalised version of the first 4 letters becomes the symbol the full address is the token name
        bytes memory tokenSymbolBytes = abi.encodePacked(bytes4(VerusAddressCalculator.stringToBytes32(IDAsString)));
        //convert them to uppercase
        bytes memory symbolUpper = new bytes(4);
        for(uint i = 0; i < 4; i++){
            if ((uint8(tokenSymbolBytes[i]) >= 97) && (uint8(tokenSymbolBytes[i]) <= 122)){
                symbolUpper[i] = bytes1(uint8(tokenSymbolBytes[i]) - 32);
            } else {
                symbolUpper[i] = tokenSymbolBytes[i];
            }
        }
        return deployNewToken(destinationCurrencyID,IDAsString,string(symbolUpper));
    }

    function deployNewToken(uint160 destinationCurrencyID,string memory tokenName, string memory symbol) public returns (address) {
        require(isVerusBridgeContract(),"Call can only be made from Verus Bridge Contract");
        if(isToken(destinationCurrencyID)) return destinationToAddress[destinationCurrencyID];
        Token t = new Token(tokenName, symbol);
        vERC20Tokens[address(t)]= hostedToken(destinationCurrencyID,true,true);
        destinationToAddress[destinationCurrencyID] = address(t);
        emit TokenCreated(address(t));
        return address(t);
    }

    function generateDestinationCurrencyID(string memory tokenName) public view returns(uint160){
        bytes memory reducedTokenName = abi.encodePacked(bytes9(VerusAddressCalculator.stringToBytes32(tokenName)));
        uint160 output;
        uint coinNumber = 0;
        string memory coinNumberAsStr;
        uint maxLen = 9;
        bytes memory tokenNameAsBytes;
        bytes memory numberAsBytes;
        output = VerusAddressCalculator.stringToUint160(string(abi.encodePacked(reducedTokenName,bytes11(".erc20.eth."))));
        while(isToken(output)){
            
            //need to be able to handle
            coinNumber++;
            coinNumberAsStr = _uintToStr(coinNumber);
            tokenNameAsBytes = abi.encodePacked(reducedTokenName);
            numberAsBytes = abi.encodePacked(coinNumberAsStr);
            
            //check for the very slim possibility that this maxes out
            require(maxLen >= 0,"tokenName permutations exceeded.");
            
            for(uint i = 1;i <= numberAsBytes.length; i++){
                tokenNameAsBytes[tokenNameAsBytes.length -i] = numberAsBytes[numberAsBytes.length -i];
            }
            
            //truncate the bytes array
            reducedTokenName =abi.encodePacked(tokenNameAsBytes);
            output = VerusAddressCalculator.stringToUint160(string(abi.encodePacked(reducedTokenName,bytes11(".erc20.eth."))));
            
        }
        return output;
    }

    function _newDestinationCurrencyID(string memory tokenName) private pure returns(uint160){
        //a verus address is made up of tokenName.erc20.eth. where tokenName is a max of 9 chars
        //check if the tokenName already exists
        bytes9 reducedTokenName = bytes9(VerusAddressCalculator.stringToBytes32(tokenName));
        return VerusAddressCalculator.stringToUint160(string(abi.encodePacked(reducedTokenName,bytes11(".erc20.eth."))));
    }
    
    function isToken(uint160 destinationCurrencyID) public view returns(bool){
        return vERC20Tokens[destinationToAddress[destinationCurrencyID]].isRegistered;
    }

    function isToken(address contractAddress) public view returns(bool){
        return vERC20Tokens[contractAddress].isRegistered;
    }

    function isVerusOwned(address contractAddress) public view returns(bool){
        return vERC20Tokens[contractAddress].VerusOwned;
    }

    /** helper function for generating currency ids **/
    function _uintToStr(uint _i) private pure returns (string memory _uintAsString) {
        uint number = _i;
        if (number == 0) {
            return "0";
        }
        uint j = number;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (number != 0) {
            bstr[k--] = byte(uint8(48 + number % 10));
            number /= 10;
        }
        return string(bstr);
    }

}