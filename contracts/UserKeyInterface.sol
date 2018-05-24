pragma solidity ^0.4.20;


import "./ownership/Ownable.sol";

contract UserInterface is Ownable {
  mapping(address => string) publicKeyRSAs;
  mapping(address => string) publicKeySigns;
    
  address[] userKeyAddeds;
  
  function addPubKeyRSA(address _userId, string _publicKeyRSA) public onlyOwner {        
    publicKeyRSAs[_userId] = _publicKeyRSA;
      
    if (!checkUserKeyAdded(_userId)) {
      userKeyAddeds.push(_userId);
    }
  }

  function addPubKeySign(address _userId, string _publicKeySign) public onlyOwner {        
    publicKeySigns[_userId] = _publicKeySign;
  }

  function getPubKeyRSA(address _userId) public view returns(string publicKey) {
    return publicKeyRSAs[_userId];
  }
    
  function getPubKeySign(address _userId) public view returns(string publicKey) {
    return publicKeySigns[_userId];
  }
    
  function checkUserKeyAdded(address _userId) public view returns(bool) {
    uint256 _len = userKeyAddeds.length;
    for (uint256 i = 0; i < _len; ++i) {
      if (_userId == userKeyAddeds[i]) return true;
    }
        
    return false;
  }
    
  function getAllUserKeyAddeds() public view returns(address[]) {
    return userKeyAddeds;
  }
    
  function getTheNumberOfUserKeyAdded() public view returns(uint256) {
    return userKeyAddeds.length;
  }
}







