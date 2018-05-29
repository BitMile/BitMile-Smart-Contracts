pragma solidity ^0.4.20;


import "./deal/SecKeyList.sol";
import "./payment/Payment.sol";

contract DealInterface is SecKeyList, Payment {
  using SafeMath for uint256;

  uint256 public globalDealId = 1;

  event LogDealCreated(
    uint256 _dealId,
    address _bidder,
    uint256 _expiryTime,
    string _sessionPublicKey
  );

  function createDeal(
    uint256 _price,
    uint256 _expiryTime,
    string _sessionPublicKey
  ) external {
    uint256 _id = globalDealId;
    DealData storage _deal = deals[_id];

    require(_deal.id == 0);
    require(_expiryTime > 0);

    _deal.id = _id;
    _deal.bidder = msg.sender;
    _deal.price = _price;
    _deal.expiryTime = _expiryTime.add(block.timestamp);
    _deal.sessionPublicKey = _sessionPublicKey;

    globalDealId++;
    emit LogDealCreated(_id, msg.sender, _expiryTime, _sessionPublicKey);
  }

  // get information of a Deal
  function getDeal(uint256 _dealId) public view returns(
    address ownerDeal,
    uint256 price,
    uint256 expiredTime,
    string sessionPublicKey
  ) {
    require(deals[_dealId].id == _dealId);

    DealData storage _deal = deals[_dealId];
    return (
      _deal.bidder,
      _deal.price,
      _deal.expiryTime,
      _deal.sessionPublicKey
    );
  }

  function addSecKey(
    uint256 _dealId,
    address _userId,
    string _encDocId,
    string _encSecKey,
    string _encDocNonce
  ) external onlyOwner {
    DealData storage _deal = deals[_dealId];

    require(_deal.id == _dealId);
    require(!hasExpired(_dealId));

    _addSecKey(_dealId, _userId, _encDocId, _encSecKey, _encDocNonce);

    _unlockBalance(_userId, _deal.price);
  }

  function deleteDeal(uint256 _dealId) external {
    require(deals[_dealId].id == _dealId);
    require(deals[_dealId].bidder == msg.sender);
    require(hasExpired(_dealId));

    delete deals[_dealId];
    _clearSecKeys(_dealId);
  }
}
