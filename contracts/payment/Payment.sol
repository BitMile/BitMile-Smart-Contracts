pragma solidity ^0.4.20;


import "../deal/DealInfo.sol";

contract Payment is DealInfo {
  struct UserBalance {
    uint256 escrowLock;
    uint256 escrowUnlock;
  }

  bool balanceLock = false;

  mapping(address => UserBalance) userBalances;

  event LogDealPaid (
    uint256 _dealId,
    address _from,
    address[] _to
  );
    
  function unlockBalance(address _userId, uint256 _value) internal returns(bool) {		
    require(userBalances[_userId].escrowLock >= _value);
    require(balanceLock == false);
        
    balanceLock = true;
    userBalances[_userId].escrowLock -= _value;
    userBalances[_userId].escrowUnlock += _value;
    balanceLock = false;
        
    return true;
  }    
    
  function withdraw(uint256 _value) public returns (bool) {
    require(userBalances[msg.sender].escrowUnlock >= _value);
    require(balanceLock == false);
        
    balanceLock = true;
        
    userBalances[msg.sender].escrowUnlock -= _value;
    msg.sender.transfer(_value);
        
    balanceLock = false;
    return true;
  }
       
  function getBalance(address _userId) public view returns(
    uint256 lockAmount,
    uint256 unlockAmount
  ) {
    return (
      userBalances[_userId].escrowLock,
      userBalances[_userId].escrowUnlock
    );
  }
    
  // send BMC from Consumer to all valid doc owners
  function payForRequestKeys(uint256 _dealId, address[] _userIds) external payable returns(bool) {
    require (deals[_dealId].bidder == msg.sender);
    uint256 _price = deals[_dealId].price;
    uint256 _sendAmount = msg.value;
        
    require(msg.value >= _userIds.length*_price);
    require(balanceLock == false);
        
    balanceLock = true;
        
    for (uint256 i = 0; i < _userIds.length; ++i) {
      userBalances[_userIds[i]].escrowLock += _price;
      _sendAmount -= _price;
    }

    if (_sendAmount >= 0) {
      userBalances[msg.sender].escrowUnlock += _sendAmount;
    }
        
    emit LogDealPaid(_dealId, msg.sender, _userIds);
        
    balanceLock = false;
    return true;
  }
      
  /* refund BMC to consumer (if necessary) when the deal is finished
  function refundBMCForConsumer(uint256 _dealId, address[] _userIds) public payable returns(bool) {
    require(deals[_dealId].bidder == msg.sender);
    uint256 _price = deals[_dealId].price;
    require(balanceLock == false);
        
    balanceLock = true;
		
    for (uint256 i = 0; i < _userIds.length; ++i) {
      if (userBalances[_userIds[i]].escrowLock >= _price) {
        userBalances[_userIds[i]].escrowLock -= _price;
        userBalances[msg.sender].escrowUnlock += _price;
      }
    }
		
    balanceLock = false;        
    return true;
  }*/
}
