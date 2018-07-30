pragma solidity ^0.4.24;

import '../../zeppelin/contracts/ownership/Contactable.sol';
import '../../zeppelin/contracts/ownership/CanReclaimToken.sol';
import '../../zeppelin/contracts/token/ERC20/PausableToken.sol';

import '../../ownership/ClaimableEx.sol';
import './TraceableToken.sol';


/**
 * @title XBM private token.
 * @dev XBM is a ERC20 token that:
 *  - caps total number at 100 billion tokens.
 *  - can pause and unpause token transfer (and authorization) actions.
 *  - mints new tokens when purchased.
 *  - can run a loop through all token holders.
 *  - attempts to reject ERC20 token transfers to itself and allows token transfer out.
 *  - allows the new owner to accept the ownership transfer, the owner can cancel the transfer if needed.
 **/
contract XBMToken is Contactable, ClaimableEx, CanReclaimToken, PausableToken, TraceableToken {
  string public constant name = "XBMToken";
  string public constant symbol = "XBM";

  uint8 public constant decimals = 18;
  uint256 public constant TOTAL_TOKENS = 100 * (10**9) * (10 ** uint256(decimals));

  constructor()
    public
    Contactable()
    ClaimableEx()
    CanReclaimToken()
    PausableToken()
    MintableToken()
    TraceableToken()
  {
    contactInformation = 'http://bitmile.io/';
  }

  /**
   * @dev Mints tokens to a beneficiary address. Capped by TOTAL_TOKENS.
   * @param _to Who got the tokens.
   * @param _amount Amount of tokens.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= TOTAL_TOKENS);
    return super.mint(_to, _amount);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a new owner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) onlyOwner public {
    // do not allow self ownership
    require(_newOwner != address(this));
    super.transferOwnership(_newOwner);
  }
}
