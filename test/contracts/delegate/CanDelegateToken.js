const BigNumber = web3.BigNumber;
const DelegateToken = artifacts.require('./delegate/DelegateToken.sol');
const BalanceSheet = artifacts.require("./BalanceSheet.sol");
const XBMTokenMock = artifacts.require("./mocks/XBMTokenMocks.sol");

const Should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();
const bn = require('../helpers/bignumber.js');

function check(accounts, deployTokenCb) {
  var newToken;
  var oldToken;
  var balanceSheet;

  var owner     = accounts[0];
  var otherUser = accounts[2];
  var purchaser = accounts[3];
  var investor  = accounts[4];

  var _90tokens = bn.tokens(90);
  var _100tokens = bn.tokens(100);

  var systemWallet = accounts[7]
  var tokenName    = "XBMTokenMock";
  var tokenSymbol  = "XBMMock";

  beforeEach(async function () {
    oldToken = await deployTokenCb();

    balanceSheet = await BalanceSheet.new({from:owner });

    await balanceSheet.transferOwnership(oldToken.address).should.be.fulfilled;

    await oldToken.setBalanceSheet(balanceSheet.address).should.be.fulfilled;
  });

  describe('delegateToNewContract()', function() {
    beforeEach(async function () {
      newToken = await XBMTokenMock.new(_90tokens);
    });

    it ('Should allow owner to delegate', async function() {
      await oldToken.delegateToNewContract(newToken.address, {from:owner}).should.be.fulfilled;
      let _delegatingContract = await oldToken.delegate();
      assert.equal(newToken.address, _delegatingContract);
    });

    it ('Should allow owner to undelegate by delegating to null address', async function() {
      let _nullAdds = '0x0000000000000000000000000000000000000000';
      await oldToken.delegateToNewContract(_nullAdds, {from:owner}).should.be.fulfilled;
    });

    it ('Should reject non-owner to delegate', async function() {
      await oldToken.delegateToNewContract(newToken.address, {from:otherUser}).should.be.rejected;
    });

    it ('Should log event', async function() {
      const {logs} = await oldToken.delegateToNewContract(newToken.address, {from:owner}).should.be.fulfilled;
      const delegateEvent = logs.find(e => e.event === 'DelegateToNewContract');
      delegateEvent.should.exist;
      (delegateEvent.args.newContract).should.equal(newToken.address);
    });
  });

  describe('When not delegated', function() {
    it('totalSupply() should return oldToken \'s totalSupply_', async function() {
      await oldToken.mint(purchaser, _90tokens).should.be.fulfilled;
      let _totalSupply = await oldToken.totalSupply().should.be.fulfilled;
      _totalSupply.should.be.bignumber.equal(_90tokens);
    });

    it('balanceOf() should return balance of oldToken \'s user', async function() {
      await oldToken.mint(purchaser, _90tokens).should.be.fulfilled;
      let _purchaserBalance = await oldToken.balanceOf(purchaser).should.be.fulfilled;
      _purchaserBalance.should.be.bignumber.equal(_90tokens);
    });

    it('transfer() should update balance of oldToken\'s user', async function() {
      await oldToken.mint(purchaser, _90tokens).should.be.fulfilled;

      let _balance1OldTokenBefore = await oldToken.balanceOf(investor);
      let _balance2OldTokenBefore = await oldToken.balanceOf(purchaser);

      let _amount = bn.tokens(5);
      await oldToken.transfer(investor, _amount, {from: purchaser}).should.be.fulfilled;

      let _balance1OldTokenAfter = await oldToken.balanceOf(investor);
      let _balance2OldTokenAfter = await oldToken.balanceOf(purchaser);

      _balance1OldTokenAfter.should.be.bignumber.equal(_balance1OldTokenBefore.plus(_amount));
      _balance2OldTokenAfter.should.be.bignumber.equal(_balance2OldTokenBefore.minus(_amount));
    });
  });

  describe('When delegated', function() {
    beforeEach(async function () {
      var owner11 = await balanceSheet.owner();
      await oldToken.mint(purchaser, _90tokens).should.be.fulfilled;
      let _newTotalSupply = await oldToken.totalSupply();
      newToken = await XBMTokenMock.new(_newTotalSupply);
      await oldToken.reclaimContract(balanceSheet.address, {from : owner});
      await balanceSheet.claimOwnership().should.be.fulfilled;
      await balanceSheet.transferOwnership(newToken.address).should.be.fulfilled;
      await newToken.setBalanceSheet(balanceSheet.address).should.be.fulfilled;
      await oldToken.delegateToNewContract(newToken.address, {from:owner}).should.be.fulfilled;
      await newToken.setDelegatedFrom(oldToken.address, {from:owner}).should.be.fulfilled;
    });

    it('totalSupply() should return newToken\'s totalSupply_', async function() {
      let _totalSupply1 = await oldToken.totalSupply().should.be.fulfilled;
      await newToken.mint(purchaser, _100tokens).should.be.fulfilled;
      let _totalSupply2 = await newToken.totalSupply().should.be.fulfilled;
      let _totalSupply3 = await oldToken.totalSupply().should.be.fulfilled;

      _totalSupply2.should.be.bignumber.equal(_totalSupply3);
      _totalSupply2.should.be.bignumber.equal(_totalSupply1.plus(_100tokens));
    });

    it('balanceOf() should return balance of newToken\'s user', async function() {
      await newToken.mint(purchaser, _100tokens).should.be.fulfilled;

      let _purchaserBalance = await oldToken.balanceOf(purchaser).should.be.fulfilled;
      _purchaserBalance.should.be.bignumber.equal(_100tokens.plus(_90tokens));
    });

    it('transfer() should update balance of newToken\'s user', async function() {
      await newToken.mint(purchaser, _100tokens).should.be.fulfilled;
      let _balance1NewTokenBefore = await newToken.balanceOf(investor);
      let _balance2NewTokenBefore = await newToken.balanceOf(purchaser);
      let _amount = bn.tokens(5);
      await oldToken.transfer(investor, _amount, {from: purchaser}).should.be.fulfilled;
      let _balance1NewTokenAfter = await newToken.balanceOf(investor);
      let _balance2NewTokenAfter = await newToken.balanceOf(purchaser);
      _balance1NewTokenAfter.should.be.bignumber.equal(_balance1NewTokenBefore.plus(_amount));
      _balance2NewTokenAfter.should.be.bignumber.equal(_balance2NewTokenBefore.minus(_amount));
    });
  });
}
module.exports.check = check;
