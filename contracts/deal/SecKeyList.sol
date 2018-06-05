pragma solidity ^0.4.20;


import "../ownership/ClaimableEx.sol";

contract SecKeyList is ClaimableEx {
  struct SecKey {
    address userId;
    string encDocId;
    string encSecKey;
    string encDocNonce;
  }

  // dealId => secret keys list
  mapping(uint256 => SecKey[]) secKeys;

  function _addSecKey(
    uint256 _dealId,
    address _userId,
    string _encDocId,
    string _encSecKey,
    string _encDocNonce
  ) internal onlyOwner {
    SecKey memory _key;
    _key.userId = _userId;
    _key.encDocId = _encDocId;
    _key.encSecKey = _encSecKey;
    _key.encDocNonce = _encDocNonce;

    secKeys[_dealId].push(_key);
  }

  function _getSecKey(uint256 _dealId, uint256 _index) internal view returns(
    address _userId,
    string _encDocId,
    string _encSecKey,
    string _encDocNonce
  ) {
    require(_index <= secKeys[_dealId].length);

    SecKey memory _key = secKeys[_dealId][_index];
    return (
      _key.userId,
      _key.encDocId,
      _key.encSecKey,
      _key.encDocNonce
    );
  }

  function _getTheNumberOfSecKeys(uint256 _dealId) internal view returns(uint256) {
    return secKeys[_dealId].length;
  }

  function _clearSecKeys(uint256 _dealId) internal {
    delete secKeys[_dealId];
  }
}
