pragma solidity ^0.4.24;

import "../ERC223/ERC223BasicToken.sol";


// Treats all delegate functions exactly like the corresponding normal functions,
// e.g. delegateTransfer is just like transfer.
contract DelegateToken is ERC223BasicToken {
  address public delegatedFrom;

  event DelegatedFromSet(address addr);

  // Only calls from appointed address will be processed
  modifier onlyMandator() {
    require(msg.sender == delegatedFrom);
    _;
  }

  function setDelegatedFrom(address _addr) public onlyOwner {
    delegatedFrom = _addr;
    emit DelegatedFromSet(_addr);
  }

  // each function delegateX is simply forwarded to function X
  function delegateTotalSupply(
  )
    public
    onlyMandator
    view
    returns (uint256)
  {
    return totalSupply();
  }

  function delegateBalanceOf(
    address _who
  )
    public
    onlyMandator
    view
    returns (uint256)
  {
    return balanceOf(_who);
  }

  function delegateTransfer(
    address _to,
    uint256 _value,
    address _origSender
  )
    public
    onlyMandator
    returns (bool)
  {
    bytes memory _empty;
    return _transferFromTo(_origSender, _to, _value, _empty);
  }

  function delegateTransfer(
    address _to,
    uint256 _value,
    bytes _data,
    address _origSender
  )
    public
    onlyMandator
    returns (bool)
  {
    return _transferFromTo(_origSender, _to, _value, _data);
  }
}
