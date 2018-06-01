pragma solidity ^0.4.20;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

import "../deal/DealInfo.sol";

contract Payment is DealInfo {
  using SafeMath for uint256;

  struct UserBalance {
    uint256 escrowLock;
    uint256 escrowUnlock;
    bool exist;
  }

  bool balanceLock = false;

  mapping(address => UserBalance) userBalances;

  address[] users;

  event LogDealPaid(uint256 _dealId, address _from, address[] _to);

  event LogBalanceUnlocked(address _userId, uint256 _value);

  function _unlockBalance(address _userId, uint256 _value) internal returns(bool) {
    UserBalance storage _balance = userBalances[_userId];

    require(_balance.escrowLock >= _value);
    require(balanceLock == false);

    balanceLock = true;

    _balance.escrowLock = _balance.escrowLock.sub(_value);
    _balance.escrowUnlock = _balance.escrowUnlock.add(_value);

    balanceLock = false;
    emit LogBalanceUnlocked(_userId, _value);
    return true;
  }

  function withdraw(uint256 _value) external returns(bool) {
    UserBalance storage _balance = userBalances[msg.sender];

    require(_balance.escrowUnlock >= _value);
    require(balanceLock == false);

    balanceLock = true;

    _balance.escrowUnlock = _balance.escrowUnlock.sub(_value);
    msg.sender.transfer(_value);

    balanceLock = false;
    return true;
  }

  function getBalance(address _userId) public view returns(
    uint256 _lockAmount,
    uint256 _unlockAmount
  ) {
    return (
      userBalances[_userId].escrowLock,
      userBalances[_userId].escrowUnlock
    );
  }

  // send BMC from Consumer to all valid doc owners
  function payForRequestKeys(uint256 _dealId, address[] _userIds) external payable returns(bool) {
    DealData storage _deal = deals[_id];

    require(!hasExpired(_dealId));
    require(_deal.bidder == msg.sender);

    uint256 _price = _deal.price;
    uint256 _amount = msg.value;

    require(msg.value >= _userIds.length.mul(_price));
    require(balanceLock == false);

    balanceLock = true;

    for (uint256 _i = 0; _i < _userIds.length; ++_i) {
      address _userAddr = _userIds[_i];
      if (!_hasExisted(_userAddr)) _addUser(_userAddr);

      UserBalance storage _balance = userBalances[_userAddr];
      _balance.escrowLock = _balance.escrowLock.add(_price);
      _amount = _amount.sub(_price);
    }

    if (_amount >= 0) {
      UserBalance storage _bidderBalance = userBalances[msg.sender];
      _bidderBalance.escrowUnlock = _bidderBalance.escrowUnlock.add(_amount);
      if (!_hasExisted(msg.sender)) _addUser(msg.sender);
    }

    emit LogDealPaid(_dealId, msg.sender, _userIds);

    balanceLock = false;
    return true;
  }

  function getTheNumberOfUsers() external view onlyOwner returns(uint256) {
    return users.length;
  }

  function getUserAddress(uint256 _index) external view onlyOwner returns(address) {
    require(_index < users.length);

    return users[_index];
  }

  function _addUser(address _userID) internal {
    users.push(_userId);
    userBalances[_userId].exist = true;
  }

  function _hasExisted(address _userID) internal returns(bool) {
    return (userBalances[_userId].exist);
  }
}
