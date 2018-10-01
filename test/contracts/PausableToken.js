const BigNumber = web3.BigNumber;
const BalanceSheet = artifacts.require("./BalanceSheet.sol");

const XBMToken = artifacts.require("./XBMToken.sol");
const web3Abi = require('web3-eth-abi');

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

const bn = require('./helpers/bignumber.js');

function check(accounts, deployTokenCb) {
  var token;
  var owner = accounts[0];
  var investor = accounts[1];
  var purchaser = accounts[2];
  var beneficiary = accounts[3];
  var balanceSheet;

  var transferAbi;
  var web3;
  var transferDataAgrument;
  var transAmount;
  beforeEach(async function () {
    token = await deployTokenCb();
    balanceSheet = await BalanceSheet.new({from:owner });
    await balanceSheet.transferOwnership(token.address).should.be.fulfilled;
    await token.setBalanceSheet(balanceSheet.address).should.be.fulfilled;
    await token.addAddressToWhitelist(investor).should.be.fulfilled;

    web3 = XBMToken.web3;
    transferAbi = {
      "constant": false,
      "inputs": [
        {
          "name": "_to",
          "type": "address"
        },
        {
          "name": "_value",
          "type": "uint256"
        },
        {
          "name": "_data",
          "type": "bytes"
        }
      ],
      "name": "transfer",
      "outputs": [
        {
          "name": "",
          "type": "bool"
        }
      ],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }

    var data = '0x01';
    transAmount = bn.tokens(1);
    transferDataAgrument = web3Abi.encodeFunctionCall(
      transferAbi,
      [
        beneficiary,
        transAmount.toString(),
        data,
      ]
    );
  });

  describe('when not paused', function() {
    it('should allow transfer(address _to, uint256 _value)', async function() {
      await token.mint(purchaser, bn.tokens(10)).should.be.fulfilled;
      await token.transfer(beneficiary, bn.tokens(1), {from: purchaser}).should.be.fulfilled;
    });

    it('should allow transfer(address _to, uint256 _value, bytes _data)', async function() {
      await token.mint(purchaser, bn.tokens(10)).should.be.fulfilled;
      let _balance1Before = await token.balanceOf(purchaser);
      let _balance2Before = await token.balanceOf(beneficiary);

      await web3.eth.sendTransaction({from: purchaser, to: token.address, data: transferDataAgrument, value: 0, gas: 500000});

      let _balance1After = await token.balanceOf(purchaser);
      let _balance2After = await token.balanceOf(beneficiary);

      _balance1After.should.be.bignumber.equal(_balance1Before.minus(transAmount));
      _balance2After.should.be.bignumber.equal(_balance2Before.plus(transAmount));
    });
  });

  describe('pause()', function() {
    beforeEach(async function () {
      await token.pause().should.be.fulfilled;
    });

    it('paused() should return true', async function() {
      (await token.paused()).should.be.equal(true);
    });

    it('non-owner can not invoke pause()', async function() {
      await token.unpause().should.be.fulfilled;
      await token.pause({from: purchaser}).should.be.rejected;
    });

    it('should allow minting', async function() {
      await token.mint(investor, bn.tokens(1)).should.be.fulfilled;
    });

    it('should reject transfer(address _to, uint256 _value)', async function() {
      await token.mint(purchaser, bn.tokens(1)).should.be.fulfilled;
      await token.transfer(investor, bn.tokens(1), {from: purchaser}).should.be.rejected;
    });
  });

  describe('unpause()', function() {
    beforeEach(async function () {
      await token.pause().should.be.fulfilled;
      await token.unpause().should.be.fulfilled;
      await token.mint(purchaser, bn.tokens(10)).should.be.fulfilled;
    });

    it('paused() should return false', async function() {
      (await token.paused()).should.be.equal(false);
    });

    it('non-owner can not invoke unpause()', async function() {
      await token.pause().should.be.fulfilled;
      await token.unpause({from: purchaser}).should.be.rejected;
    });

    it('should allow transfer(address _to, uint256 _value)', async function() {
      await token.transfer(beneficiary, bn.tokens(1), {from: purchaser}).should.be.fulfilled;
    });

    it('should allow transfer(address _to, uint256 _value, bytes _data)', async function() {
      await token.mint(purchaser, bn.tokens(10)).should.be.fulfilled;
      let _balance1Before = await token.balanceOf(purchaser);
      let _balance2Before = await token.balanceOf(beneficiary);

      await web3.eth.sendTransaction({from: purchaser, to: token.address, data: transferDataAgrument, value: 0, gas: 500000});

      let _balance1After = await token.balanceOf(purchaser);
      let _balance2After = await token.balanceOf(beneficiary);

      _balance1After.should.be.bignumber.equal(_balance1Before.minus(transAmount));
      _balance2After.should.be.bignumber.equal(_balance2Before.plus(transAmount));
    });
  });
}

module.exports.check = check;
