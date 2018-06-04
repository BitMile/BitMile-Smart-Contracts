pragma solidity ^0.4.20;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

import './AccountSet.sol';
import "../deal/DealInfo.sol";
import "../token/BMCToken.sol";

contract Payment is DealInfo {
  using SafeMath for uint256;

  BMCToken token;
  AccountSet public accountSet;

  event LogDealPaid(uint256 _dealId, address _from, address[] _to);

  event LogBalanceUnlocked(address _userId, uint256 _value);

  function Payment(BMCToken _token)
  public {
    token = _token;
    token.addToFreeChargeSet(this);

    accountSet = new AccountSet();
  }

  function _unlockBalance(address _addr, uint256 _value) onlyOwner internal {
    require(accountSet.getBalance(_addr) >= _value);

    accountSet.decreaseBalance(_addr, _value);
    token.transfer(_addr, _value);

    emit LogBalanceUnlocked(_addr, _value);
  }

  function getBalance(address _addr) public view returns(uint256) {
    return accountSet.getBalance(_addr);
  }

  function payForMyDeal(uint256 _dealId, address[] _addrs) external {
    DealData storage _deal = deals[_dealId];

    require(!hasExpired(_dealId));
    require(_deal.bidder == msg.sender);

    _ensureKeysPayment(_addrs.length, _deal.price);

    for (uint256 _i = 0; _i < _addrs.length; _i++) {
      accountSet.increaseBalance(_addrs[_i], _deal.price);
    }

    emit LogDealPaid(_dealId, msg.sender, _addrs);
  }

  function payForUserDeal(uint256 _dealId) external {
    DealData storage _deal = deals[_dealId];

    require(!hasExpired(_dealId));

    _ensureKeysPayment(1, _deal.price);

    accountSet.increaseBalance(_deal.bidder, _deal.price);

    address[] memory _addrs = new address[](1);
    _addrs[0] = _deal.bidder;
    emit LogDealPaid(_dealId, msg.sender, _addrs);
  }

  function getTheNumberOfAccounts() onlyOwner external view returns(uint256) {
    return accountSet.getTheNumberOfElements();
  }

  function getAccount(uint256 _index) onlyOwner external view returns(address, uint256) {
    address _addr = accountSet.elementAt(_index);
    return(_addr, accountSet.getBalance(_addr));
  }

  function _ensureKeysPayment(uint256 _nUsers, uint256 _price) internal {
    uint256 _allowed = token.allowance(msg.sender, this);
    uint256 _transferValue = _price.mul(_nUsers);
    uint256 _estimate = token.estimateTransferDebit(_transferValue);

    require(_allowed >= _estimate);

    token.transferFrom(msg.sender, this, _transferValue);
  }
}
