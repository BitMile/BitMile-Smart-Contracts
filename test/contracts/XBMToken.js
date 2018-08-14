const BigNumber = web3.BigNumber;

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

const bn = require('./helpers/bignumber.js');
const claimableEx = require("./ClaimableEx.js");
const hasNoEther = require("./HasNoEther.js");
const reclaimTokens = require("./CanReclaimToken.js");
const basicToken = require("./BasicToken.js");
const standardToken = require("./StandardToken.js");
const pausableToken = require("./PausableToken.js");
const mintableToken = require("./MintableToken.js");

const XBMToken = artifacts.require("./XBMToken.sol");


contract('XBMToken', function (accounts) {
  let token;
  let owner = accounts[0];
  let investor = accounts[1];
  let purchaser = accounts[2];

  beforeEach(async function () {
    token = await deploy();
  });

  describe('transferFromTo()', function() {
    it('non-owner can not call', async function () {
      await token.mint(investor, bn.tokens(100)).should.be.fulfilled;
      await token.transferFromTo(investor, purchaser, bn.tokens(100), {from: investor}).should.be.rejected;
      await token.transferFromTo(investor, purchaser, bn.tokens(100), {from: purchaser}).should.be.rejected;
    });

    it('should allow owner to transfer tokens', async function() {
      await token.mint(investor, bn.tokens(100)).should.be.fulfilled;
      await token.transferFromTo(investor, purchaser, bn.tokens(100)).should.be.fulfilled;
    });

    it('should update balances', async function() {
      var amount = bn.tokens(10);
      await token.mint(investor, amount).should.be.fulfilled;
      var balance1Before = await token.balanceOf(investor);
      var balance2Before = await token.balanceOf(purchaser);
      await token.transferFromTo(investor, purchaser, amount).should.be.fulfilled;
      var balance1After = await token.balanceOf(investor);
      var balance2After = await token.balanceOf(purchaser);

      balance2After.should.be.bignumber.equal(balance2Before.plus(amount));
      balance1After.should.be.bignumber.equal(balance1Before.minus(amount));
    });

    it("should log Transfer event", async function () {
      var amount = bn.tokens(100);
      await token.mint(investor, amount).should.be.fulfilled;
      const {logs} = await token.transferFromTo(investor, purchaser, amount).should.be.fulfilled;
      const xferEvent = logs.find(e => e.event === 'Transfer');
      xferEvent.should.exist;
      (xferEvent.args.from).should.equal(investor);
      (xferEvent.args.to).should.equal(purchaser);
      (xferEvent.args.value).should.be.bignumber.equal(amount);
    });

    it('should reject transferring to invalid address', async function() {
      await token.mint(investor, bn.tokens(100)).should.be.fulfilled;
      await token.transferFromTo(investor, 0x0, bn.tokens(100)).should.be.rejected;
    });

    it('should reject transferring an amount of tokens which is greater than balance', async function() {
      await token.mint(investor, bn.tokens(100)).should.be.fulfilled;
      await token.transferFromTo(investor, purchaser, bn.tokens(101)).should.be.rejected;
    });

    it('should reject transferring an amount of max uint256', async function() {
      var totalTokens = await token.TOTAL_TOKENS();
      await token.mint(investor, totalTokens).should.be.fulfilled;
      await token.transferFromTo(investor, purchaser, bn.MAX_UINT256).should.be.rejected;
    });

    it('transferring an amount which exceeds max uint256 should be equivalent to 0 tokens', async function() {
      var totalTokens = await token.TOTAL_TOKENS();
      await token.mint(investor, totalTokens).should.be.fulfilled;
      var balance1Before = await token.balanceOf(investor);
      var balance2Before = await token.balanceOf(purchaser);
      await token.transferFromTo(investor, purchaser, bn.OVER_UINT256).should.be.fulfilled;
      var balance1After = await token.balanceOf(investor);
      var balance2After = await token.balanceOf(purchaser);

      balance2After.should.be.bignumber.equal(balance2Before);
      balance1After.should.be.bignumber.equal(balance1Before);
    });
  });

  describe('transferOwnership()', function() {
    it('should not be self-ownable', async function() {
      await token.transferOwnership(token.address).should.be.rejected;
    });
  });

  describe('ClaimableEx', function() {
      claimableEx.check(accounts, deployContract);
  });

  describe('HasNoEther', function() {
      hasNoEther.check(accounts, deployContract);
  });

  describe('CanReclaimToken', function() {
    reclaimTokens.check(accounts, deployContract, deploy);
  });

  describe('Mintable Token', function() {
    mintableToken.check(accounts, deploy);
  });

  describe('Basic Token', function() {
    basicToken.check(accounts, deploy);
  });

  describe('Standard Token', function() {
    standardToken.check(accounts, deploy);
  });

  describe('Pausable Token', function() {
    pausableToken.check(accounts, deploy);
  });

  async function deploy() {
    var _token = await XBMToken.new();
    return _token;
  }

  async function deployContract() {
    return deploy();
  }
});
