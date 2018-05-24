pragma solidity ^0.4.20;


import "./deal/AnswerList.sol";
import "./deal/SecKeyList.sol";
import "./payment/Payment.sol";

contract DealInterface is AnswerList, SecKeyList, Payment {
  uint256 public globalDealId = 1;
	
  event LogDealCreated (
    uint256 _dealId,
    address _bidder,
    uint256 _expiryTime,
    string _sessionPublicKey
  );	

  function createDeal(
    uint256 _price,
    uint256 _expiryTime,
    string _sessionPublicKey
  ) public {
    uint256 _id = globalDealId;
    DealData storage _deal = deals[_id];
    require(_deal.id == 0);
     
    _deal.id = _id;
    _deal.bidder = msg.sender;
    _deal.price = _price;
    _deal.expiryTime = _expiryTime + block.timestamp;
    _deal.sessionPublicKey = _sessionPublicKey;

    globalDealId++;
    emit LogDealCreated(_id, msg.sender, _expiryTime, _sessionPublicKey);
  }
       
  // get information of a Deal
  function getDeal(uint256 _dealId) public constant returns (
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
	
  function sendSecKey(
    uint256 _dealId,
    address _userId,
    string _encDocId,
    string _secEncKey,
    string _encDocNonce
  ) public payable {
    DealData storage _deal = deals[_dealId];
    require(_deal.id == _dealId);

    addSecKey(_dealId, _userId, _encDocId, _secEncKey, _encDocNonce);
	
    unlockBalance(_userId, _deal.price);
  }
    
  function deleteDeal(uint256 _dealId) public {
    require(deals[_dealId].id == _dealId);
    require(deals[_dealId].bidder == msg.sender);
      
    delete deals[_dealId];
    clearAnswers(_dealId);
    clearSecKeys(_dealId);
  }
    
}
