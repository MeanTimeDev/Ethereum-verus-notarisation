pragma solidity >=0.4.20;

import "./Token.sol";

contract Factory {
    event TokenCreated(address tokenAddress);
    //array of contracts address mapped to the token name
    mapping(string => address) vERC20Tokens;

    function deployNewToken(string memory name, string memory symbol)
    public returns (address) {
        Token t = new Token(name, symbol);
        vERC20Tokens[name] = address(t);
        emit TokenCreated(address(t));
    }

    function mintToken(string memory name,uint mintAmount,address recipient) public {
        Token token = Token(vERC20Tokens[name]);
        token.mint(recipient,mintAmount);
    }

    function burnToken(string memory name,uint burnAmount) public {
        Token token = Token(vERC20Tokens[name]);
        token.burn(burnAmount);
    }

    function tokenAddress(string memory name) public returns(address){
        return vERC20Tokens[name];
    }

}