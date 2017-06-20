const Ethermillion = artifacts.require("./Ethermillion.sol");

contract('Ethermillion', accounts => {
	it("should buy 1 ticket for number 5", function () {
		let ethermillion;
		return Ethermillion.deployed().then(instance => {
			ethermillion = instance;
			return ethermillion.BuyTicket(5, {value: web3.toWei(15, "finney"), from: accounts[0]});
		}).then(() => {
			return ethermillion.prize.call()
		}).then(prize => {
			prize = prize.toNumber()
			assert.equal(prize, web3.toWei(8, "finney"), "Total prize is incorrect");
			return ethermillion.prizeForTokenHolders.call()
		}).then(prizeForTokenHolders => {
			prizeForTokenHolders = prizeForTokenHolders.toNumber()
			assert.equal(prizeForTokenHolders, web3.toWei(1, "finney"), "prizeForTokenHolders is incorrect");
			return ethermillion.prizeForSeeders.call()
		}).then(prizeForSeeders => {
			prizeForSeeders = prizeForSeeders.toNumber()
			assert.equal(prizeForSeeders, web3.toWei(1, "finney"), "prizeForSeeders is incorrect");
		})
	});
});
