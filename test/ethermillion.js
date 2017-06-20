const Ethermillion = artifacts.require("./Ethermillion.sol");

contract('Ethermillion', accounts => {
	let returnedPrize;

	const initialBalance = web3.eth.getBalance(accounts[0]);

	it("should buy 1 ticket for number 5", function () {
		let ethermillion;
		return Ethermillion.deployed().then(instance => {
			ethermillion = instance;
			return ethermillion.BuyTicket.call(5, {value: web3.toWei(15, "finney"), from: accounts[0]});
		}).then(x => {
			returnedPrize = x.toString()
			return new Promise((resolve, reject) => {
				web3.eth.getBalance(accounts[0], (e, x) => {
					if (e) reject(e)
					else resolve(x)
				})
			})
		}).then(newBalance => {
			assert.equal(newBalance.toString(), initialBalance.minus(web3.toWei(10, "finney")).toString())
			return ethermillion.prize.call();
		}).then(prize => {
			console.log(prize)
			prize = prize.valueOf();
			assert.equal(prize, web3.toWei(8, "finney"), "Prize is incorrect");
			assert.equal(prize, returnedPrize, "Prize and returned prize do not match");
		})
	});
});
