pragma solidity ^0.4.20;

import "../ownership/ClaimableEx.sol";

contract DealInfo is ClaimableEx {
  struct DealData {
    uint256 id;
    address bidder;
    uint256 price;
    uint256 expiryTime;
    string sessionPublicKey;
  }

  // dealId => DealData
  mapping(uint256 => DealData) deals;

  // dealId => payer
  mapping(uint256 => address) payers;

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

  function _addDeal(uint256 _id, address _bidder, uint256 _price, uint256 _expiryTime, string _sessionPublicKey) internal {
    DealData storage _deal = deals[_id];

    require(_deal.id == 0);

    _deal.id = _id;
    _deal.bidder = _bidder;
    _deal.price = _price;
    _deal.expiryTime = _expiryTime;
    _deal.sessionPublicKey = _sessionPublicKey;

    dealIds.push(_id);
  }

  function _deleteDeal(uint256 _dealId) internal {
    require(deals[_dealId].id == _dealId);
    require(hasExpired(_dealId));

    delete deals[_dealId];
  }

  function _getDeal(uint256 _dealId) internal view returns(
    address _bidder,
    uint256 _price,
    uint256 _expiryTime,
    string _sessionPublicKey
  ) {
    DealData storage _deal = deals[_dealId];

    require(_deal.id == _dealId);

    return (_deal.bidder, _deal.price, _deal.expiryTime, _deal.sessionPublicKey);
  }

  function _addPayer(uint256 _dealId) internal {
    require(payers[_dealId] == 0x0);

    payers[_dealId] = msg.sender;
  }

  function _isPayer(uint256 _dealId) internal view returns(bool) {
    return payers[_dealId] == msg.sender;
  }
}
