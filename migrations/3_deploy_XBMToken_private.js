const XBMToken = artifacts.require("./token/private/XBMToken.sol");

module.exports = function(deployer, network) {
  let overwrite = true;

  switch (network) {
    case 'development':
      overwrite = true;
      break;
    default:
        throw new Error ("Unsupported network");
  }

  deployer.then (() => {
      return deployer.deploy(XBMToken, {overwrite: overwrite});
  }).then(() => {
      return XBMToken.deployed();
  }).catch((err) => {
      console.error(err);
      process.exit(1);
  });
};
