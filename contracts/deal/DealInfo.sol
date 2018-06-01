pragma solidity ^0.4.20;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

import "../ownership/ClaimableEx.sol";

contract DealInfo is ClaimableEx {
  using SafeMath for uint256;

  struct DealData {
    uint256 id;
    address bidder;
    uint256 price;
    uint256 expiryTime;
    string sessionPublicKey;
  }

  // dealId => DealData
  mapping(uint256 => DealData) deals;

  uint256[] dealIds;

  function hasExpired(uint256 _dealId) public view returns(bool) {
    DealData storage _deal = deals[_dealId];
    return block.timestamp > _deal.expiryTime;
  }

  function getTheNumberOfDeals() external view onlyOwner returns(uint256) {
    return dealIds.length;
  }

  function getDealId(uint256 _index) external view onlyOwner returns(uint256) {
    require(_index < dealIds.length);

    return dealIds[_index];
  }

  function _addDeal(uint256 _id, uint256 _price, uint256 _expiryTime, string _sessionPublicKey) internal {
    DealData storage _deal = deals[_id];

    require(_deal.id == 0);

    _deal.id = _id;
    _deal.bidder = msg.sender;
    _deal.price = _price;
    _deal.expiryTime = _expiryTime;
    _deal.sessionPublicKey = _sessionPublicKey;

    dealIds.push(_id);
  }
}
