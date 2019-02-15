import ether from './ether.js';

const BigNumber = web3.BigNumber;

let MAX_UINT256 = (new BigNumber(2)).pow(256).minus(1);
let OVER_UINT256 = (new BigNumber(2)).pow(256);

function tokens(amount) {
  return (new BigNumber(10**9)).times(amount);
}

function roundDown(x) {
  return x.round(0, BigNumber.ROUND_DOWN);
}

function roundHalfUp(x) {
  return x.round(0, BigNumber.ROUND_HALF_UP);
}

module.exports.MAX_UINT256 = MAX_UINT256;
module.exports.OVER_UINT256 = OVER_UINT256;

module.exports.tokens = tokens;
module.exports.roundDown = roundDown;
module.exports.roundHalfUp = roundHalfUp;
