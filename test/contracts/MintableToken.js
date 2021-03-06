const BigNumber = web3.BigNumber;

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

const bn = require('./helpers/bignumber.js');

function check(accounts, deployTokenCb) {
  var token;
  var owner = accounts[0];
  var investor = accounts[1];

  beforeEach(async function () {
    token = await deployTokenCb();
  });

  describe('mint()', function() {
    let amount = bn.tokens(75000);
    let from = '0x0000000000000000000000000000000000000000';

    it("begins with totalSupply", async function () {
      var totalSupply = await token.totalSupply();
      totalSupply.should.be.bignumber.equal(0);
      owner.should.be.equal(await token.owner());
    });

    it("mint() updates balanceOf and totalSupply", async function () {
      var startingBalance = await token.balanceOf(investor);
      var startingSupply = await token.totalSupply();
      await token.mint(investor, amount);

      (await token.balanceOf(investor)).minus(startingBalance).should.be.bignumber.equal(amount);
      (await token.totalSupply()).minus(startingSupply).should.be.bignumber.equal(amount);
    });

    it("mint() logs events", async function () {
      const {logs} = await token.mint(investor, amount);
      const mintEvent = logs.find(e => e.event === 'Mint');
      mintEvent.should.exist;
      (mintEvent.args.to).should.equal(investor);
      (mintEvent.args.amount).should.be.bignumber.equal(amount);

      const xferEvent = logs.find(e => e.event === 'Transfer');
      xferEvent.should.exist;
      (xferEvent.args.from).should.equal(from);
      (xferEvent.args.to).should.equal(investor);
      (xferEvent.args.value).should.be.bignumber.equal(amount);
    });

    it('non-owner can not mint', async function () {
      await token.mint(investor, bn.tokens(1), {from: investor}).should.be.rejected;
    });

    it('should not mint more than TOTAL_TOKENS', async function () {
      var totalTokens = await token.TOTAL_TOKENS();
      var totalSupply = await token.totalSupply();
      var remaining = totalTokens.minus(totalSupply);
      await token.mint(investor, remaining.plus(bn.tokens(1))).should.be.rejected;
    });

    it('minting an amount that exceeds max uint256 should be equivalent to minting 0 tokens', async function () {
      await token.mint(investor, bn.OVER_UINT256);
      (await token.totalSupply()).should.be.bignumber.equal(0);
    });
  });

  describe('finishMinting()', function() {
    it("owner can finish tokens minting", async function () {
      await token.finishMinting().should.be.fulfilled;
      (await token.mintingFinished()).should.equal(true);
    });

    it("non-owner can not finish tokens minting", async function () {
      await token.finishMinting({from: investor}).should.be.rejected;
    });

    it("should log MintFinished event", async function () {
      const {logs} = await token.finishMinting().should.be.fulfilled;
      const event = logs.find(e => e.event === 'MintFinished');
      event.should.exist;
    });

    it("should not mint after call finishMinting()", async function () {
      await token.finishMinting().should.be.fulfilled;
      await token.mint(investor, bn.tokens(1)).should.be.rejected;
    });
  });
}

module.exports.check = check;
