pragma solidity ^0.4.20;


import "./DealInfo.sol";
import "../ownership/Ownable.sol";

contract SecKeyList is DealInfo {
  struct SecKey {
    address userId;
    string encDocId;
    string secEncKey;
    string encDocNonce;
  }

  // dealId => secret keys list
  mapping(uint256 => SecKey[]) secKeys;

  function _addSecKey(
    uint256 _dealId,
    address _userId,
    string _encDocId,
    string _secEncKey,
    string _encDocNonce
  ) internal onlyOwner {
    DealData storage _deal = deals[_dealId];

    require(_deal.id == _dealId);

    SecKey memory _key;
    _key.userId = _userId;
    _key.encDocId = _encDocId;
    _key.secEncKey = _secEncKey;
    _key.encDocNonce = _encDocNonce;

    secKeys[_dealId].push(_key);
  }

  function getSecKey(uint256 _dealId, uint256 _index) public view returns(
    address ownerId,
    string encDocId,
    string secEncKey,
    string encDocNonce
  ) {
    DealData storage _deal = deals[_dealId];

    require(_deal.bidder == msg.sender);
    require(_index <= secKeys[_dealId].length);

    SecKey memory _key = secKeys[_dealId][_index];
    return (
      _key.userId,
      _key.encDocId,
      _key.secEncKey,
      _key.encDocNonce
    );
  }

  function getTheNumberOfSecKeys(uint256 _dealId) public view returns(uint256) {
    require(deals[_dealId].id == _dealId);

    return secKeys[_dealId].length;
  }

  function _clearSecKeys(uint256 _dealId) internal {
    require(deals[_dealId].bidder == msg.sender);

    delete secKeys[_dealId];
  }
}
