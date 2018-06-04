pragma solidity ^0.4.20;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Contactable.sol';
import 'zeppelin-solidity/contracts/ownership/HasNoTokens.sol';
import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';
import 'zeppelin-solidity/contracts/token/ERC20/PausableToken.sol';

import '../ownership/ClaimableEx.sol';
import '../utils/AddressSet.sol';


/**
 * @title BMC token.
 * @dev BMC is a ERC20 token that:
 *  - caps total number at 10 billion tokens.
 *  - can pause and unpause token transfer (and authorization) actions.
 *  - mints new tokens when purchased (rather than transferring tokens pre-granted to a holding account).
 *  - can run a loop through all token holders.
 *  - transfers cost fee, all fees will be sent to the BitMile platform wallet.
 *  - attempts to reject ERC20 token transfers to itself and allows token transfer out.
 *  - allows the new owner to accept the ownership transfer, the owner can cancel the transfer if needed.
 **/
contract BMCToken is Contactable, HasNoTokens, MintableToken, PausableToken, ClaimableEx {
  using SafeMath for uint256;

  string public constant name = "BMCToken";
  string public constant symbol = "BMC";

  uint8 public constant decimals = 18;
  uint256 public constant ONE_TOKENS = (10 ** uint256(decimals));
  uint256 public constant BILLION_TOKENS = (10**9) * ONE_TOKENS;
  uint256 public constant TOTAL_TOKENS = 10 * BILLION_TOKENS;

  AddressSet public holderSet;

  address public bitmileWallet;
  uint8 public transferFeeRate;
  AddressSet public freeChargeSet;

  /**
   * @param _bitmileWallet Wallet address of the BitMile platform.
   * @param _transferFeeRate Transfer fee rate.
   */
  function BMCToken(address _bitmileWallet, uint8 _transferFeeRate)
  Contactable()
  HasNoTokens()
  MintableToken()
  PausableToken()
  ClaimableEx()
  public {
    contactInformation = 'https://token.samuraix.io/';

    require(_bitmileWallet != 0x0);
    bitmileWallet = _bitmileWallet;

    require(_transferFeeRate < 100);
    transferFeeRate = _transferFeeRate;

    freeChargeSet = new AddressSet();
    holderSet = new AddressSet();
  }

  /**
   * @dev Changes wallet address of the BitMile platform.
   * @param _addr A new wallet address to update.
   */
  function setBitMileWallet(address _addr) external onlyOwner {
    require(_addr != 0x0);
    require(_addr != bitmileWallet);

    bitmileWallet = _addr;
  }

  /**
   * @dev Changes transfer fee rate.
   * @param _newRate A new rate to update.
   */
  function setTransferFeeRate(uint8 _newRate) external onlyOwner {
    require(_newRate < 100);

    transferFeeRate = _newRate;
  }

  /**
   * @dev Mints tokens to a beneficiary address. Capped by TOTAL_TOKENS.
   * @param _to Who got the tokens.
   * @param _amount Amount of tokens.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
    require(totalSupply_.add(_amount) <= TOTAL_TOKENS);
    bool suc = super.mint(_to, _amount);
    if (suc) holderSet.add(_to);

    return suc;
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

  function transfer(address _to, uint256 _value) public returns(bool) {
    _checkTransferTarget(_to);

    if (!shouldBeFree(msg.sender)) {
      uint256 _fee = _calcTransferFee(_value);
      super.transfer(bitmileWallet, _fee);
    }

    super.transfer(_to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
    _checkTransferTarget(_to);

    if (!shouldBeFree(_from)) {
      uint256 _fee = _calcTransferFee(_value);
      super.transferFrom(_from, bitmileWallet, _fee);
    }

    super.transferFrom(_from, _to, _value);
    return true;
  }

  function estimateTransferDebit(uint256 _transferValue) public view returns(uint256) {
    if (shouldBeFree(msg.sender)) {
      return _transferValue;
    }

    uint256 _fee = _calcTransferFee(_transferValue);
    return _fee.add(_transferValue);
  }

  function estimateTransferValue(uint256 _transferDebit) public view returns(uint256) {
    if (shouldBeFree(msg.sender)) {
      return _transferDebit;
    }

    return _transferDebit.mul(100).div(100 + transferFeeRate);
  }

  function addToFreeChargeSet(address _addr) onlyOwner public {
    freeChargeSet.add(_addr);
  }

  function shouldBeFree(address _from) public view returns(bool) {
    return freeChargeSet.contains(_from);
  }

  function getTheNumberOfHolders() onlyOwner external view returns(uint256) {
    return holderSet.getTheNumberOfElements();
  }

  function getHolder(uint256 _index) onlyOwner external view returns(address) {
    return holderSet.elementAt(_index);
  }

  function getTheNumberOfFreeSenders() onlyOwner external view returns(uint256) {
    return freeChargeSet.getTheNumberOfElements();
  }

  function getFreeSender(uint256 _index) onlyOwner external view returns(address) {
    return freeChargeSet.elementAt(_index);
  }

  function _checkTransferTarget(address _to) internal {
    if (!holderSet.contains(_to)) {
      holderSet.add(_to);
    }
  }

  function _calcTransferFee(uint256 _transferValue) internal view returns(uint256) {
    uint256 _fee = _transferValue.mul(transferFeeRate).div(100);
    require(_fee > 0);

    return _fee;
  }
}
