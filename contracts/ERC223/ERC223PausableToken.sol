pragma solidity ^0.4.24;

import '../zeppelin/contracts/lifecycle/Pausable.sol';

import "./ERC223BasicToken.sol";


/**
 * @title Pausable token
 * @dev ERC223BasicToken modified with pausable transfers.
 * Based on code by OpenZeppelin: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/PausableToken.sol
 **/
contract ERC223PausableToken is ERC223BasicToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transfer(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value, _data);
  }

  function _transferFromTo(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    internal
    whenNotPaused
    returns (bool)
  {
    return super._transferFromTo(_from, _to, _value, _data);
  }
}
