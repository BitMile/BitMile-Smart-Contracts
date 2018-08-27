pragma solidity ^0.4.24;

contract ERC223Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transfer(address to, uint value, bytes data) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}
