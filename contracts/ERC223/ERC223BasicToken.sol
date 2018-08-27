pragma solidity ^0.4.24;

import '../zeppelin/contracts/math/SafeMath.sol';

import './ERC223Basic.sol';
import './ERC223Receiver.sol';

/**
 * @title Implementation of the ERC223 standard token.
 */
contract ERC223BasicToken is ERC223Basic {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;

  uint256 private totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  /**
   * @dev Transfer the specified amount of tokens to the specified address.
   *      Invokes the `tokenFallback` function if the recipient is a contract.
   *      The token transfer fails if the recipient is a contract
   *      but does not implement the `tokenFallback` function
   *      or the fallback function to receive funds.
   *
   * @param _to    Receiver address.
   * @param _value Amount of tokens that will be transferred.
   * @param _data  Transaction metadata.
   */
  function transfer(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    returns (bool)
  {
    return _transferFromTo(msg.sender, _to, _value, _data);
  }

  /**
   * @dev Transfer the specified amount of tokens to the specified address.
   *      This function works the same with the previous one
   *      but doesn't contain `_data` param.
   *      Added due to backwards compatibility reasons.
   *
   * @param _to    Receiver address.
   * @param _value Amount of tokens that will be transferred.
   */
  function transfer(
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    bytes memory _empty;

    return transfer(_to, _value, _empty);
  }

  /**
   * @dev Internal function that checks whether a specified address is a contract or not.
   * @param _addr The address to check.
   * @return true if this is a contract address, otherwise false.
   */
  function _isContract(address _addr) internal view returns (bool) {
    // Assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    uint256 _codeLength;
    assembly {
      // Retrieve the size of the code on target address, this needs assembly .
      _codeLength := extcodesize(_addr)
    }
    return _codeLength > 0;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param _account The account that will receive the created tokens.
   * @param _amount The amount that will be created.
   */
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);

    totalSupply_ = totalSupply_.add(_amount);
    balances[_account] = balances[_account].add(_amount);

    bytes memory _empty;
    emit Transfer(address(0), _account, _amount, _empty);
  }

  /**
   * @dev Internal function that transfers the specified amount of tokens to the specified address.
   *      Invokes the `tokenFallback` function if the recipient is a contract.
   *      The token transfer fails if the recipient is a contract
   *      but does not implement the `tokenFallback` function
   *      or the fallback function to receive funds.
   *
   * @param _from  Sender address.
   * @param _to    Receiver address.
   * @param _value Amount of tokens that will be transferred.
   * @param _data  Transaction metadata.
   */
  function _transferFromTo(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    internal
    returns (bool)
  {
    require(_value > 0);
    require(_value <= balances[_from]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    if (_isContract(_to)) {
      ERC223Receiver _receiver = ERC223Receiver(_to);
      _receiver.tokenFallback(_from, _value, _data);
    }

    emit Transfer(_from, _to, _value, _data);
    return true;
  }
}
