pragma solidity ^0.4.24;

import "./DelegateToken.sol";


// See DelegateToken.sol for more on the delegation system.
contract CanDelegateToken is ERC223BasicToken{
  // If this contract needs to be upgraded, the new contract will be stored
  // in 'delegate' and any BurnableToken calls to this contract will be delegated to that one.
  DelegateToken public delegate;

  event DelegateToNewContract(address indexed newContract);

  // Can undelegate by passing in _newContract = address(0)
  function delegateToNewContract(
    DelegateToken _newContract
  )
    public
    onlyOwner
  {
    delegate = _newContract;
    emit DelegateToNewContract(delegate);
  }

  // If a delegate has been designated, all ERC223 calls are forwarded to it
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (!_hasDelegate()) {
      return super.transfer(_to, _value);
    } else {
      require(delegate.delegateTransfer(_to, _value, msg.sender));
      return true;
    }
    return true;
  }

  function totalSupply() public view returns (uint256) {
    if (!_hasDelegate()) {
      return super.totalSupply();
    } else {
      return delegate.delegateTotalSupply();
    }
  }

  function balanceOf(address _who) public view returns (uint256) {
    if (!_hasDelegate()) {
      return super.balanceOf(_who);
    } else {
      return delegate.delegateBalanceOf(_who);
    }
  }

  function _hasDelegate() internal view returns (bool) {
    return !(delegate == address(0));
  }
}
