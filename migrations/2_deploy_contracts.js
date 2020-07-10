var Ants = artifacts.require("Ants");
var AntsReview = artifacts.require("AntsReview");
var AntFaucet = artifacts.require("AntFaucet");

module.exports = function(deployer) {

 		deployer.deploy(Ants).then(function() {
			return deployer.deploy(AntsReview, Ants.address);
		}).then(function() {
			return deployer.deploy(AntFaucet, Ants.address);
		});

};
