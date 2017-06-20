var Ethermillion = artifacts.require("./Ethermillion.sol");

module.exports = function (deployer) {
	deployer.deploy(Ethermillion);
};
