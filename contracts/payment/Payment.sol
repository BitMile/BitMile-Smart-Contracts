pragma solidity ^0.4.24;


import '../zeppelin/contracts/math/SafeMath.sol';

import './AccountSet.sol';
import "../ownership/ClaimableEx.sol";
import "../token/private/XBMToken.sol";

contract Payment is ClaimableEx {
  using SafeMath for uint256;

  XBMToken token;
  AccountSet public accountSet;

  event LogBalanceUnlocked(address _userId, uint256 _value);

  function Payment(XBMToken _token)
  public {
    token = _token;

    accountSet = new AccountSet();
  }

  function getBalance(address _addr) public view returns(uint256) {
    return accountSet.getBalance(_addr);
  }

  function getTheNumberOfAccounts() onlyOwner external view returns(uint256) {
    return accountSet.getTheNumberOfElements();
  }

  function getAccount(uint256 _index) onlyOwner external view returns(address, uint256) {
    address _addr = accountSet.elementAt(_index);
    return(_addr, accountSet.getBalance(_addr));
  }

  function _ensureKeysPayment(address[] _addrs, uint256 _price) internal {
    uint256 _allowed = token.allowance(msg.sender, this);
    uint256 _transferValue = _price.mul(_addrs.length);

    require(_allowed >= _transferValue);

    token.transferFrom(msg.sender, this, _transferValue);

    for (uint256 _i = 0; _i < _addrs.length; _i++) {
      accountSet.increaseBalance(_addrs[_i], _price);
    }
  }

  function _unlockBalance(address _addr, uint256 _value) onlyOwner internal {
    require(accountSet.getBalance(_addr) >= _value);

    accountSet.decreaseBalance(_addr, _value);
    token.transfer(_addr, _value);

    emit LogBalanceUnlocked(_addr, _value);
  }
}
