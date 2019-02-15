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
const pausableToken = require("./PausableToken.js");
const mintableToken = require("./MintableToken.js");
const delegateToken = require("./delegate/DelegateToken.js");
const canDelegateToken = require("./delegate/CanDelegateToken.js");

const XBMToken = artifacts.require("./XBMToken.sol");
const BalanceSheet = artifacts.require("./BalanceSheet.sol");

contract('XBMToken', function (accounts) {
  let token;
  let owner = accounts[0];
  let investor = accounts[1];
  let purchaser = accounts[2];
  let nonWhitelistAdds = accounts[3];

  var initAmount = bn.tokens(100);
  var balanceSheet;

  var r;
  var s;
  var v_decimal;

  beforeEach(async function () {
    token = await deploy();
    balanceSheet = await BalanceSheet.new({from:owner });
    await balanceSheet.transferOwnership(token.address).should.be.fulfilled;
    await token.setBalanceSheet(balanceSheet.address).should.be.fulfilled;
    await token.addAddressToWhitelist(investor).should.be.fulfilled;

    let _hashData =  await token.calcHash(purchaser, initAmount);
    let _signature = web3.eth.sign(investor, _hashData);

    _signature = _signature.substr(2); //remove 0x
    r = '0x' + _signature.slice(0, 64);
    s = '0x' + _signature.slice(64, 128);
    let _v = '0x' + _signature.slice(128, 130);
    v_decimal = web3.toDecimal(_v) + 27;
  });

  describe('changeTokenName()', function() {
    it('Should allow owner to set new name and symbol', async function() {
      let _oldTokenName = await token.name();
      let _oldTokenSymbol = await token.symbol();
      let _newTokenName = "XBMToken_1";
      let _newTokenSymbol = "XBM_1";
      assert.notEqual(_oldTokenName, _newTokenName);
      assert.notEqual(_oldTokenSymbol, _newTokenSymbol);

      const {logs} = await token.changeTokenName(_newTokenName, _newTokenSymbol);
      let _currName = await token.name();
      let _currSymbol = await token.symbol();

      assert.equal(_currName, _newTokenName);
      assert.equal(_currSymbol, _newTokenSymbol);

      // Should log event
      const event = logs.find(e => e.event === 'ChangeTokenName');
      event.should.exist;
      (event.args.newName).should.equal(_newTokenName);
      (event.args.newSymbol).should.equal(_newTokenSymbol);
    });

    it('Should reject non-owner to set new name and symbol', async function() {
      let _newTokenName = "XBMToken_1";
      let _newTokenSymbol = "XBM_1";
      await token.changeTokenName(_newTokenName, _newTokenSymbol, {from: investor}).should.be.rejected;
    });
  });

  describe('transferTo()', function() {
    it('non-whitelistaddress can not call', async function () {
      await token.mint(investor, initAmount).should.be.fulfilled;
      await token.transferTo(purchaser, initAmount, v_decimal, r, s, {from : nonWhitelistAdds}).should.be.rejected;
    });

    it('should allow account in white list address to transfer tokens', async function() {
      await token.mint(investor, initAmount).should.be.fulfilled;
      await token.transferTo(purchaser,initAmount, v_decimal, r, s, {from : investor}).should.be.fulfilled;
    });

    it('should update balances', async function() {
      var amount = initAmount;
      await token.mint(investor, amount).should.be.fulfilled;
      var balance1Before = await token.balanceOf(investor);
      var balance2Before = await token.balanceOf(purchaser);
      await token.transferTo(purchaser, amount, v_decimal, r, s, {from : investor}).should.be.fulfilled;
      var balance1After = await token.balanceOf(investor);
      var balance2After = await token.balanceOf(purchaser);

      balance2After.should.be.bignumber.equal(balance2Before.plus(amount));
      balance1After.should.be.bignumber.equal(balance1Before.minus(amount));
    });

    it("should log Transfer event", async function () {
      var amount = initAmount;
      await token.mint(investor, amount).should.be.fulfilled;
      const {logs} = await token.transferTo(purchaser, amount, v_decimal, r, s, {from : investor}).should.be.fulfilled;
      const xferEvent = logs.find(e => e.event === 'Transfer');
      xferEvent.should.exist;
      (xferEvent.args.from).should.equal(investor);
      (xferEvent.args.to).should.equal(purchaser);
      (xferEvent.args.value).should.be.bignumber.equal(amount);
    });

    it('should reject transferring an amount of tokens which is greater than balance', async function() {
      await token.mint(investor, bn.tokens(99)).should.be.fulfilled;
      await token.transferTo(purchaser, initAmount, v_decimal, r, s, {from : investor}).should.be.rejected;
    });

    it('should reject transferring to invalid address', async function() {
      await token.mint(investor, initAmount).should.be.fulfilled;

      let invalidAdds = 0x0;
      let _invalidAddsHashData =  await token.calcHash(invalidAdds, initAmount);
      let _invalidAddsSignature = web3.eth.sign(investor, _invalidAddsHashData);

      _invalidAddsSignature = _invalidAddsSignature.substr(2); //remove 0x
      let i_r = '0x' + _invalidAddsSignature.slice(0, 64);
      let i_s = '0x' + _invalidAddsSignature.slice(64, 128);
      let i_v = '0x' + _invalidAddsSignature.slice(128, 130);
      let i_v_decimal = web3.toDecimal(i_v) + 27;

      await token.transferTo(invalidAdds, initAmount, i_v_decimal, i_r, i_s, {from : investor}).should.be.rejected;
    });

    it('should reject transferring an amount of max uint256', async function() {
      var totalTokens = await token.TOTAL_TOKENS();
      await token.mint(investor, totalTokens).should.be.fulfilled;

      let _hashData =  await token.calcHash(purchaser, bn.MAX_UINT256);
      let _signature = web3.eth.sign(investor, _hashData);

      _signature = _signature.substr(2); //remove 0x
      r = '0x' + _signature.slice(0, 64);
      s = '0x' + _signature.slice(64, 128);
      let _v = '0x' + _signature.slice(128, 130);
      v_decimal = web3.toDecimal(_v) + 27;

      await token.transferTo(purchaser, bn.MAX_UINT256, v_decimal, r, s, {from : investor}).should.be.rejected;
    });

    it('transferring an amount which exceeds max uint256 should be equivalent to 0 tokens', async function() {
      var totalTokens = await token.TOTAL_TOKENS();
      await token.mint(investor, totalTokens).should.be.fulfilled;
      var balance1Before = await token.balanceOf(investor);
      var balance2Before = await token.balanceOf(purchaser);

      let _hashData =  await token.calcHash(purchaser, bn.OVER_UINT256);
      let _signature = web3.eth.sign(investor, _hashData);

      _signature = _signature.substr(2); //remove 0x
      r = '0x' + _signature.slice(0, 64);
      s = '0x' + _signature.slice(64, 128);
      let _v = '0x' + _signature.slice(128, 130);
      v_decimal = web3.toDecimal(_v) + 27;

      await token.transferTo(purchaser, bn.OVER_UINT256, v_decimal, r, s, {from : investor}).should.be.fulfilled;
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

  describe('Delegate Token', function() {
    delegateToken.check(accounts, deploy);
  });

  describe('Can Delegate Token', function() {
    canDelegateToken.check(accounts, deploy);
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
