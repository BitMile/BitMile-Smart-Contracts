pragma solidity ^0.4.20;


contract DealInfo {
  struct DealData {
    uint256 id;
    address bidder;
    uint256 price;
    uint256 expiryTime;
    string sessionPublicKey;
  }
    
  // dealId => DealData
  mapping(uint256 => DealData) deals;
}
