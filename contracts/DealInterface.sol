pragma solidity ^0.4.20;


import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

import "./deal/DealInfo.sol";
import "./deal/SecKeyList.sol";
import "./payment/Payment.sol";
import "./token/BMCToken.sol";

contract DealInterface is DealInfo, SecKeyList, Payment, Pausable {
  using SafeMath for uint256;

  uint256 public globalDealId = 1;

  event LogDealCreated(
    uint256 _dealId,
    address _bidder,
    uint256 _expiryTime,
    string _sessionPublicKey
  );

  event LogDealPaid(uint256 _dealId, address _from, address[] _to);

  function DealInterface(BMCToken _token)
  Payment(_token)
  public {
  }

  function createDeal(
    address _bidder,
    uint256 _price,
    uint256 _expiryTimeAfter,
    string _sessionPublicKey
  ) external whenNotPaused {
    require(_expiryTimeAfter > 0);

    uint256 _id = globalDealId;
    uint256 _expiryTime = _expiryTimeAfter.add(block.timestamp);
    _addDeal(_id, _bidder, _price, _expiryTime, _sessionPublicKey);

    globalDealId++;
    emit LogDealCreated(_id, _bidder, _expiryTime, _sessionPublicKey);
  }

  // get information of a Deal
  function getDeal(uint256 _dealId) external view returns(
    address _bidder,
    uint256 _price,
    uint256 _expiryTime,
    string _sessionPublicKey
  ) {
    return _getDeal(_dealId);
  }

  function payForMyDeal(uint256 _dealId, address[] _addrs) external whenNotPaused {
    DealData storage _deal = deals[_dealId];

    require(_addrs.length > 0);
    require(!hasExpired(_dealId));
    require(_deal.bidder == msg.sender);

    _ensureKeysPayment(_addrs, _deal.price);
    _addPayer(_dealId);

    emit LogDealPaid(_dealId, msg.sender, _addrs);
  }

  function payForUserDeal(uint256 _dealId) external whenNotPaused {
    DealData storage _deal = deals[_dealId];

    require(!hasExpired(_dealId));

    address[] memory _addrs = new address[](1);
    _addrs[0] = _deal.bidder;
    _ensureKeysPayment(_addrs, _deal.price);
    _addPayer(_dealId);

    emit LogDealPaid(_dealId, msg.sender, _addrs);
  }

  function addSecKey(
    uint256 _dealId,
    address _userId,
    string _encDocId,
    string _encSecKey,
    string _encDocNonce
  ) external onlyOwner whenNotPaused {
    DealData storage _deal = deals[_dealId];

    require(_deal.id == _dealId);
    require(!hasExpired(_dealId));

    _addSecKey(_dealId, _userId, _encDocId, _encSecKey, _encDocNonce);

    _unlockBalance(_userId, _deal.price);
  }

  function getSecKey(uint256 _dealId, uint256 _index) external view returns(
    address _userId,
    string _encDocId,
    string _encSecKey,
    string _encDocNonce
  ) {
    require(owner == msg.sender || _isPayer(_dealId));

    return _getSecKey(_dealId, _index);
  }

  function getTheNumberOfSecKeys(uint256 _dealId) external view returns(uint256) {
    require(owner == msg.sender || _isPayer(_dealId));

    return _getTheNumberOfSecKeys(_dealId);
  }

  function deleteDeal(uint256 _dealId) external whenNotPaused {
    require(owner == msg.sender || deals[_dealId].bidder == msg.sender);

    _deleteDeal(_dealId);
    _clearSecKeys(_dealId);
  }
}
