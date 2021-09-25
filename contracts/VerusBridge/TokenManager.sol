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
        address destinationCurrencyID;
        bool VerusOwned;
        bool isRegistered;
    }
    
    mapping(address => address) public destinationToAddress;
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
        if(verusBridgeContract == address(0)) return true;
        else return msg.sender == verusBridgeContract;
    }
    
    //Tokens that are being exported from the eth blockchain are either destroyed or held until imported
    function exportERC20Tokens(address _contractAddress,uint256 _tokenAmount) public {
        require(isVerusBridgeContract(),"Call can only be made from Verus Bridge Contract");
        //check that the erc20 token is registered with the tokenManager
        require(isToken(_contractAddress),"Token has not been registered yet");
        
        Token token = Token(_contractAddress);
        hostedToken memory tokenDetail;
        //transfer the tokens to the contract address
        uint256 allowedTokens = token.allowance(msg.sender,address(this));
        require( allowedTokens >= _tokenAmount,"Not enough tokens have been approved");
        //if its not approved it wont work
        token.transferFrom(msg.sender,address(this),_tokenAmount);   
        
        if(!isToken(_contractAddress)){
            tokenDetail = vERC20Tokens[_contractAddress];
            //if the token has been cerated by this contract then burn the token
        }
        if(tokenDetail.VerusOwned){
                require(token.balanceOf(address(this)) >= _tokenAmount,"Tokens didnt transfer");
                burnToken(_contractAddress,_tokenAmount);
        } else {
            //the contract stores the token
        }
    }

    /*function exportERC20Tokens(address _destCurrencyID,uint256 _tokenAmount) public {
        require(isVerusBridgeContract(),"Call can only be made from Verus Bridge Contract");
        address contactAddress = destinationToAddress[_destCurrencyID];
        exportERC20Tokens(contactAddress,_tokenAmount);
    }*/
    
    //Tokens that are being imported into the eth blockchain are either minted or transferred from a reserve
    /*function importERC20Tokens(address _contractAddress,uint256 _tokenAmount,address _destinationAddress) public {
        require(isVerusBridgeContract(),"Call can only be made from Verus Bridge Contract");
        hostedToken memory tokenDetail = vERC20Tokens[_contractAddress];
        //if the token has been created by this contract then burn the token
        if(tokenDetail.VerusOwned){
            mintToken(_contractAddress,_tokenAmount,_destinationAddress);
        } else {
            //transfer from the 
            Token token = Token(_contractAddress);
            token.transfer(_destinationAddress,_tokenAmount);   
        }
    }*/

    function importERC20Tokens(address _destCurrencyID,uint256 _tokenAmount,address _destination) public {
        require(isVerusBridgeContract(),"Call can only be made from Verus Bridge Contract");
        address contractAddress;
        //if the token has not been previously created then it must be deployed
        //require(isToken(destCurrencyID),"Token is not registered");
        if(!isToken(_destCurrencyID)) {
            contractAddress = deployNewToken(_destCurrencyID);
        } else {
            contractAddress = destinationToAddress[_destCurrencyID];
        }

        hostedToken memory tokenDetail = vERC20Tokens[contractAddress];
        //if the token has been created by this contract then burn the token
        if(tokenDetail.VerusOwned){
            mintToken(contractAddress,_tokenAmount,address(_destination));
        } else {
            //transfer from the 
            Token token = Token(contractAddress);
            token.transfer(address(_destination),_tokenAmount);   
        }
    }

    function balanceOf(address _contractAddress,address _account) public view returns(uint256){
        Token token = Token(_contractAddress);
        return token.balanceOf(_account);
    }
    function allowance(address _contractAddress,address _owner, address _spender) public view returns(uint256){
        Token token = Token(_contractAddress);
        return token.allowance(_owner,_spender);
    }

    function mintToken(address _contractAddress,uint256 _mintAmount,address _recipient) private {
        Token token = Token(_contractAddress);
        token.mint(_recipient,_mintAmount);
    }

    function burnToken(address _contractAddress,uint _burnAmount) private {
        Token token = Token(_contractAddress);
        token.burn(_burnAmount);
    }

    function addExistingToken(address _contractAddress) public returns(address){
        require(!isToken(_contractAddress),"Token is already registered");
        //generate a address for the token name
        Token token = Token(_contractAddress);
        address destinationCurrencyID = generateDestinationCurrencyID(token.name());
        vERC20Tokens[_contractAddress] = hostedToken(destinationCurrencyID,false,true);
        destinationToAddress[destinationCurrencyID] = _contractAddress;
        return destinationCurrencyID;
    }

    function deployNewToken(address _destinationCurrencyID) public returns (address) {
        require(isVerusBridgeContract(),"Call can only be made from Verus Bridge Contract");
        //generate a name based on the address and deploy the token
        string memory IDAsString; 
        IDAsString= VerusAddressCalculator.addressToString(_destinationCurrencyID);
        
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
        return deployNewToken(_destinationCurrencyID,IDAsString,string(symbolUpper));
    }

    function deployNewToken(address _destinationCurrencyID,string memory _tokenName, string memory _symbol) public returns (address) {
        require(isVerusBridgeContract(),"Call can only be made from Verus Bridge Contract");
        if(isToken(_destinationCurrencyID)) return destinationToAddress[_destinationCurrencyID];
        Token t = new Token(_tokenName, _symbol);
        vERC20Tokens[address(t)]= hostedToken(_destinationCurrencyID,true,true);
        destinationToAddress[_destinationCurrencyID] = address(t);
        emit TokenCreated(address(t));
        return address(t);
    }

    function generateDestinationCurrencyID(string memory _tokenName) public view returns(address){
        bytes memory reducedTokenName = abi.encodePacked(bytes9(VerusAddressCalculator.stringToBytes32(_tokenName)));
        address output;
        uint coinNumber = 0;
        string memory coinNumberAsStr;
        uint maxLen = 9;
        bytes memory tokenNameAsBytes;
        bytes memory numberAsBytes;
        output = VerusAddressCalculator.stringToAddress(string(abi.encodePacked(reducedTokenName,bytes11(".erc20.eth."))));
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
            output = VerusAddressCalculator.stringToAddress(string(abi.encodePacked(reducedTokenName,bytes11(".erc20.eth."))));
            
        }
        return output;
    }

    function _newDestinationCurrencyID(string memory _tokenName) private pure returns(address){
        //a verus address is made up of tokenName.erc20.eth. where tokenName is a max of 9 chars
        //check if the tokenName already exists
        bytes9 reducedTokenName = bytes9(VerusAddressCalculator.stringToBytes32(_tokenName));
        return VerusAddressCalculator.stringToAddress(string(abi.encodePacked(reducedTokenName,bytes11(".erc20.eth."))));
    }
    
    /*function isToken(address _destinationCurrencyID) public view returns(bool){
        return vERC20Tokens[destinationToAddress[_destinationCurrencyID]].isRegistered;
    }*/

    function isToken(address _contractAddress) public view returns(bool){
        return vERC20Tokens[_contractAddress].isRegistered;
    }

    function isVerusOwned(address _contractAddress) public view returns(bool){
        return vERC20Tokens[_contractAddress].VerusOwned;
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
            bstr[k--] = bytes1(uint8(48 + number % 10));
            number /= 10;
        }
        return string(bstr);
    }

}