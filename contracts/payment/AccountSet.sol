pragma solidity ^0.4.20;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

import '../utils/AddressSet.sol';

/**
 * @title Account Set.
 * @dev This contract allows to store accounts in a set and
 * owner can run a loop through all elements.
 **/
contract AccountSet is AddressSet {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function getBalance(address _addr) public view returns(uint256) {
    return balances[_addr];
  }

  function increaseBalance(address _addr, uint256 _amount) onlyOwner public {
    require(_addr != 0x0);
    require(_amount > 0);

    if (!contains(_addr)) {
      add(_addr);
    }

    balances[_addr] = balances[_addr].add(_amount);
  }

  function decreaseBalance(address _addr, uint256 _amount) onlyOwner public {
    require(_addr != 0x0);
    require(_amount > 0);
    require(contains(_addr));

    balances[_addr] = balances[_addr].sub(_amount);
  }
}
