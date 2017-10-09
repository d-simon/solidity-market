var Market = artifacts.require("./Market.sol");
// var ReputationToken = artifacts.require("./ReputationToken.sol");

module.exports = function(deployer) {
  // deployer.deploy(ReputationToken);
  deployer.deploy(Market);
};
