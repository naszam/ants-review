var Ant = artifacts.require("Ant");
var AntsReview = artifacts.require("AntsReview");

module.exports = function(deployer) {

	deployer.deploy(Ant).then(function() {
		return deployer.deploy(AntsReview, Ant.address);
	});
};
