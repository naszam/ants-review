var ANTS = artifacts.require("ANTS");
var AntsReview = artifacts.require("AntsReview");
var AntsFaucet = artifacts.require("AntsFaucet");

module.exports = function(deployer) {

 		deployer.deploy(ANTS).then(function() {
			return deployer.deploy(AntsReview, ANTS.address);
		}).then(function() {
			return deployer.deploy(AntsFaucet, ANTS.address);
		});

};
