pragma solidity ^0.4.0;

contract Ethermillion {
    // The manager gets to keep a part of the prize
    address manager = msg.sender;
    
    // The current prize
    uint256 public prize = 0;
    // The price per winner. This will be updated when the lottery is finished
    // and is 0 otherwise
    uint256 public prizePerWinner = 0;
    
    struct Participant {
        address addr; // The address of the participant (to authenticate him)
        bool withdrew; // Has the participant withdrew his profts yet?
    }
    
    // The current tickets. For efficiency, keys are the numbers people bet on
    // and the values are the list of people who bet on that number
    mapping (uint => Participant[]) tickets;
    
    // The possible states of the contract
    enum Stages {
        CanBuyTickets, // Lottery is on, people can buy tickets
        Finished, // Lottery is finished, they can withdraw
        Frozen // Lottery is frozen (should not happen)
    }
    Stages public stage = Stages.CanBuyTickets;
    
    // This is the winning number (available only when lottery is finished)
    uint public winningNumber = 0;

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }
    
    // A function using this modifier needs a certain price to be paid and
    // refunds the user if he sends more than the specified price
    modifier atExactPrice(uint price) {
        require(msg.value >= price);
        msg.sender.transfer(msg.value - price);
        _;
    }
    
    // When the lottery is finished, we send this event with the winiing number
    // And the prize per winner (per winning ticket actually, since a player
    // can have multiple tickets)
    event LotteryFinished(uint winningNumber, uint prizePerWinner);

    // Buy a ticket for a specified number. This number has to be between 1 and
    // 10000 included. Buying a ticket costs 10 finney.
    // This function returns the current prize of the lottery after this
    // ticket has been bought.
    function BuyTicket(uint number)
        atStage(Stages.CanBuyTickets)
        payable atExactPrice(10 finney)
        returns (uint)
    {
        // Check the number is correct
        require(number >= 1 && number <= 10000);
        
        // Store the ticket
        tickets[number].push(Participant({
            addr: msg.sender,
            withdrew: false
        }));
        
        // The prize increases by 8 finney. The remaining amount compensates
        // the owner of the contract
        prize += 8 finney;
        
        return prize;
    }
    
    
    function Roll(uint number) onlyManager atStage(Stages.CanBuyTickets)
    {
        stage = Stages.Finished;
        winningNumber = number;
        
        // Compute prize per winning ticket
        var numberOfWinners = tickets[winningNumber].length;
        prizePerWinner = prize / numberOfWinners;
        
        // Notify players that the lottery is finished
        LotteryFinished(winningNumber, prizePerWinner);
        
        // The manager gets its profits
        manager.transfer(this.balance - prize);
    }
    
    // Can be used by winners when lottery is finished to withdraw their
    // profits. This function withdraws profits from all winning tickets of the
    // player and returns the total won amount.
    function WithdrawPrize(address to) atStage(Stages.Finished) returns (uint) 
    {
        var winners = tickets[winningNumber];
        uint256 transferred = 0;
        
        for (uint256 i = 0; i < winners.length; i++) {
            var winner = winners[i];
            if (winner.addr == msg.sender && !winner.withdrew) {
                winner.withdrew = true;
                to.transfer(prizePerWinner);
                transferred += prizePerWinner;
            }
        }
        
        return transferred;
    }
    
    // In case of unexpected behaviour, the manager can freeze the lottery
    function Freeze() onlyManager {
        stage = Stages.Frozen;
    }
}
