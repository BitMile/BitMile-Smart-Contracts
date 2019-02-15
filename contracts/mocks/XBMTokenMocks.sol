pragma solidity ^0.4.24;

import '../zeppelin/contracts/access/Whitelist.sol';
import '../zeppelin/contracts/ownership/Contactable.sol';
import '../zeppelin/contracts/ownership/NoOwner.sol';

import '../ClaimableEx.sol';
import '../ERC223/ERC223MintableToken.sol';
import '../ERC223/ERC223PausableToken.sol';
import '../delegate/CanDelegateToken.sol';
import '../delegate/DelegateToken.sol';

/**
 * @title XBM public token.
 * @dev XBM is a ERC223 token that:
 *  - caps total number at 100 billion tokens.
 *  - can pause and unpause token transfer (and authorization) actions.
 *  - mints new tokens when purchased.
 *  - attempts to reject ERC20 and ERC223 token transfers to itself and allows token transfer out.
 *  - attempts to reject ether sent and allows any ether held to be transferred out.
 *  - allows the new owner to accept the ownership transfer, the owner can cancel the transfer if needed.
 **/
 contract XBMTokenMocks is Contactable, NoOwner, ClaimableEx, Whitelist, ERC223MintableToken, ERC223PausableToken, CanDelegateToken, DelegateToken {
  string public constant name = "XBMToken";
  string public constant symbol = "XBM";

  uint8 public constant decimals = 9;
  uint256 public constant TOTAL_TOKENS = 100 * (10**9) * (10 ** uint256(decimals));

  constructor(uint256 _totalSupply)
    public
    Contactable()
    NoOwner()
    ClaimableEx()
    Whitelist()
    ERC223MintableToken()
    ERC223PausableToken()
    CanDelegateToken()
    DelegateToken()
  {
    contactInformation = 'http://bitmile.io/';
    totalSupply_ = _totalSupply;
  }

  function calcHash(
    address _to,
    uint256 _amount
  )
    public
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked(_to, _amount)
    );
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
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    require(totalSupply().add(_amount) <= TOTAL_TOKENS);
    return super.mint(_to, _amount);
  }

  /**
   * @dev Transfer tokens from one address to another.
   * This function can be called only by some operator in the whitelist.
   * This function allows users to be able to transfer tokens without holding Ether.
   * The sender user must pass his signature (v, r, s) on message (hash from calcHash())
   * to the operator for the transaction can be validated.
   * @param _to The address which you want to transfer to.
   * @param _amount The amount of tokens to be transferred.
   * @param _v v value of sender user's ECDSA signature.
   * @param _r r value of sender user's ECDSA signature.
   * @param _s s value of sender user's ECDSA signature.
   */
  function transferTo(
    address _to,
    uint256 _amount,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  )
    public
    onlyIfWhitelisted(msg.sender)
    whenNotPaused
    returns (bool)
  {
    address _from = _verify(_to, _amount, _v, _r, _s);

    bytes memory _empty;
    return _transferFromTo(_from, _to, _amount, _empty);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a new owner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    // do not allow self ownership
    require(_newOwner != address(this));
    super.transferOwnership(_newOwner);
  }

  function _verify(
    address _to,
    uint256 _amount,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  )
    internal
    pure
    returns (address)
  {
    bytes memory _prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 _msg = calcHash(_to, _amount);
    bytes32 _prefixedHash = keccak256(
      abi.encodePacked(_prefix, _msg)
    );

    address _sender = ecrecover(_prefixedHash, _v, _r, _s);
    require(_sender != address(0));

    return _sender;
  }
}
