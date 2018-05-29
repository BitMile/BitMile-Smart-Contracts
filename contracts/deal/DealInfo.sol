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

  function hasExpired(uint256 _dealId) public view returns(bool) {
    DealData storage _deal = deals[_dealId];
    return block.timestamp > _deal.expiryTime;
  }
}
