const HornMarketplace_test = artifacts.require("HornMarketplace_test");

module.exports = async function (deployer) {
  await deployer.deploy(HornMarketplace_test);
};
