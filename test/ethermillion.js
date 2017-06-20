var Ethermillion = artifacts.require("./Ethermillion.sol");

contract('Ethermillion', function(accounts) {
	var returnedPrize;
	it("should buy 1 ticket for number 5", function() {
		var ethermillion;
		return Ethermillion.deployed().then(instance => {
			ethermillion = instance;
			return ethermillion.BuyTicket.call(5, {value: web3.toWei(10, "finney")});
		}).then(x => {
			returnedPrize = x.valueOf()
			return ethermillion.prize.call();
		}).then(prize => {
			console.log(prize)
			var prize = prize.valueOf();
			assert.equal(prize, web3.toWei(8, "finney"), "Prize is incorrect");
			assert.equal(prize, returnedPrize, "Prize and returned prize do not match");
		})
	});
});
