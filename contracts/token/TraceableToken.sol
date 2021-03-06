pragma solidity ^0.4.24;

import '../zeppelin/contracts/token/ERC20/MintableToken.sol';

import '../utils/AddressSet.sol';

/**
 * @title Traceable token.
 * @dev This contract allows a sub-class token contract to run a loop through its all holders.
 **/
contract TraceableToken is MintableToken {
  AddressSet public holderSet;

  constructor() public {
    holderSet = new AddressSet();
  }

  /**
   * @dev Mints tokens to a beneficiary address. The target address should be
   * added to the token holders list if needed.
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
    bool suc = super.mint(_to, _amount);
    if (suc) holderSet.add(_to);

    return suc;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    _checkTransferTarget(_to);

    super.transfer(_to, _value);
    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    _checkTransferTarget(_to);

    super.transferFrom(_from, _to, _value);
    return true;
  }

  function getTheNumberOfHolders() onlyOwner external view returns (uint256) {
    return holderSet.getTheNumberOfElements();
  }

  function getHolder(uint256 _index) onlyOwner external view returns (address) {
    return holderSet.elementAt(_index);
  }

  function _checkTransferTarget(address _to) internal {
    if (!holderSet.contains(_to)) {
      holderSet.add(_to);
    }
  }
}
