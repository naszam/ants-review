var Ant = artifacts.require("Ant");
var AntsReview = artifacts.require("AntsReview");
var AntFaucet = artifacts.require("AntFaucet");

module.exports = function(deployer) {

 		deployer.deploy(Ant).then(function() {
			return deployer.deploy(AntsReview, Ant.address);
		}).then(function() {
			return deployer.deploy(AntFaucet, Ant.address);
		});

};
