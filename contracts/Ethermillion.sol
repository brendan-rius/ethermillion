pragma solidity ^0.4.0;


contract Ethermillion {
    /**
     * The price the seeder has to pay to submit a hash.
     * This is given back to the seeder when he reveals his number in time.
     * If he does not (for example, because revealing it would change the
     * winning number in a way that disadvantages him), the ether is not sent
     * back.
     * This constant should be kept high enough so seeders do not cheat, and
     * low enough so they can actually deposit the money.
     */
    uint constant public SEEDER_SECURITY_DEPOSIT = 1 ether;

    /**
     * The possible states of the contract
     */
    enum Stages {
    /**
     * Lottery is on : players can buy tickets and seeders can submit hashes
     * Nobody can withdraw, and seeders can't reveal their numbers.
     */
    CanBuyTickets,
    /**
     * People cannot buy tickets anymore, nobody can withdraw.
     * It is time for seeders to reveal their random number. They cannot
     * submit new hashes.
     */
    RNGReveal,
    /**
     * Lottery is finished. Players and seeders can withdraw their money.
     * Nobody can buy tickets, submit numbers or reveal numbers
     */
    Finished
    }

    /**
     * The current stage of the contract
     */
    Stages public stage = Stages.CanBuyTickets;

    /**
     * The manager of the contract.
     * He has special rights (he earns a part of the profit, and change the
     * state of the contract)
     */
    address manager = msg.sender;

    /**
     * The current prize the winning players will share
     */
    uint256 public prize = 0;

    /**
     * The price per winner. This is updated when the lottery is finished
     * and is 0 otherwise
     */
    uint256 public prizePerWinner = 0;

    /**
     * The prize that is given to the manager. This is updated when the
     * lottery is finished and is 0 otherwise
     */
    uint256 public prizeForManager = 0;

    /**
     * The prize for all the people who gave a seed for RNG. This will be
     * updated when the lottery is finished and is 0 otherwise
     */
    uint256 public prizeForSeeders = 0;

    /**
     * The prize for EACH seeder. This is updated when the lottery is finished
     * and is 0 otherwise
     */
    uint256 public prizePerSeeder = 0;

    /**
     * This is the winning number. This number is updated during the RNGReveal
     * stage everytime a seeder reveals his number. To avoid seeders trying
     * to manipulate the winning number by choosing to not revealing their
     * number, the contract keeps the security deposit of the seeder if he does
     * not reveal the contract.
     */
    uint winningNumber = 0;

    /**
     * A player is someone who bought a ticket
     */
    struct Player {
    /**
     * The address of the player.
     * This is used to
     *   1) authenticate him
     *   2) send money to if the ticket is a winning one
     */
    address addr;

    /**
     * Has the owner of the ticket withdrew his profits yet?
     */
    bool withdrew;
    }

    /**
     * The current tickets. For efficiency, keys are the numbers people bet on
     * and the values are the list of people who bet on that number
     */
    mapping (uint => Player[]) tickets;

    /**
     * This represents a seeder
     */
    struct Seeder {
    /**
     * Has the seeder revealed his number yet?
     */
    bool revealed;
    /**
     * Has the seeder withdrew his profits yet?
     */
    bool withdrew;
    /**
     * The hash sent by the miner
     */
    bytes32 hash;
    }
    /**
     * All the seeders for RNGs
     */
    mapping(address => Seeder) seeders;

    /**
     * Number of seeders who have revealed their numbers. This is used to
     * compute the prize per seeder
     */
    uint numberOfReveals = 0;

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    /**
     * A function using this modifier needs a certain price to be paid and
     * refunds the user if he sends more than the specified price
     */
    modifier atExactPrice(uint price) {
        require(msg.value >= price);
        msg.sender.transfer(msg.value - price);
        _;
    }

    /**
     * When the lottery is finished, we send this event with the winning number,
     * the prize per winner (per winning ticket actually, since a player
     * can have multiple tickets) and the prize per seeder.
     */
    event LotteryFinished(uint winningNumber,
    uint prizePerWinner,
    uint prizePerSeeder);

    /**
     * Buy a ticket for a specified number. This number has to be between 1 and
     * 10000 included. Buying a ticket costs 10 finney.
     * This function returns the current prize of the lottery after this
     * ticket has been bought.
     */
    function BuyTicket(uint number)
    atStage(Stages.CanBuyTickets)
    payable atExactPrice(10 finney)
    returns (uint)
    {
        // Check the number is correct
        require(number >= 1 && number <= 10000);

        // Store the ticket
        tickets[number].push(Player({
        addr : msg.sender,
        withdrew : false
        }));

        // The prize increases by 7 finney.
        prize += 8 finney;
        // The prize for the manager increases by 1 finney
        prizeForManager += 1 finney;
        // The prize for the seeders increases by 1 finney
        prizeForSeeders += 1 finney;

        return prize;
    }

    /**
     * Called by a seeder with a hash constructed like this:
     * SALT + NUMBER + SALT
     * where number is a RANDOM unsigned integer not to be disclosed
     * and salt a secret complex enough not to be guessed.
     */
    function SeedRNG(bytes32 hash)
    atStage(Stages.CanBuyTickets)
    payable
    atExactPrice(SEEDER_SECURITY_DEPOSIT)
    {
        seeders[msg.sender] = Seeder({
        revealed: false,
        hash: hash,
        withdrew: false
        });
    }

    /**
     * Called by seeders during the RNGReveal stage. The seeders need to call
     * the function with the number and the hash they used to compute the hash
     * they previously sent. Any seeder who does that correctly and before
     * the stage ends will get refunded of his security deposit and be able
     * to withdraw his profits when the lottery is finished
     */
    function RevealRNG(uint number, string salt) atStage(Stages.RNGReveal)
    {
        // Find the seeder
        var seeder = seeders[msg.sender];

        // Use the number and the salt to compute the hash
        var computedHash = sha256(bytes(salt), number, bytes(salt));

        if (!seeder.revealed && seeder.hash == computedHash) {
            seeder.revealed = true;

            // Update the winning number by xoring it with the seeder's random
            // number
            winningNumber = winningNumber ^ number;

            numberOfReveals++;

            // Refund the seeder of his security deposit
            msg.sender.transfer(SEEDER_SECURITY_DEPOSIT);
        }
    }

    /**
     * End the lottery. Computes the final winning number, prize per winner
     * and prize per seeder.
     * Activated the Finished stage during which seeders and players can
     * withdraw their money.
     */
    function EndLottery() onlyManager atStage(Stages.RNGReveal)
    {
        stage = Stages.Finished;

        // Make th ewinning number be in between 1 and 10 000 included
        winningNumber = winningNumber % 10000 + 1;

        // Compute prize per winning ticket
        prizePerWinner = prize / tickets[winningNumber].length;

        // Compute prize per seeder
        prizePerSeeder = prizeForSeeders / numberOfReveals;

        // Notify players that the lottery is finished
        LotteryFinished(winningNumber, prizePerWinner, prizePerSeeder);

        // The manager gets its profits
        manager.transfer(prizeForManager);
    }

    /**
     * Can be used by winners when lottery is finished to withdraw their
     * profits. This function withdraws profits from all winning tickets of the
     * player and returns the total won amount.
     */
    function WithdrawPrize() atStage(Stages.Finished) returns (uint)
    {
        var winningTickets = tickets[winningNumber];

        // The total profits that have been transferred
        uint256 toTransfer = 0;

        for (uint256 i = 0; i < winningTickets.length; i++) {
            var ticket = winningTickets[i];
            if (ticket.addr == msg.sender && !ticket.withdrew) {
                ticket.withdrew = true;
                toTransfer += prizePerWinner;
            }
        }

        msg.sender.transfer(toTransfer);
        return toTransfer;
    }

    /**
     * Can be used by seeders when lottery is finished to withdraw the
     * profit they made out by participating to the RNG.
     */
    function WithdrawSeederPrize() atStage(Stages.Finished)
    {
        var seeder = seeders[msg.sender];

        if (seeder.revealed && !seeder.withdrew) {
            seeder.withdrew = true;
            msg.sender.transfer(prizePerSeeder);
        }
    }

    /**
     * The manager can force moving to the reveal stage
     */
    function ActivateRevealStage() onlyManager {
        stage = Stages.RNGReveal;
    }
}