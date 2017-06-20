pragma solidity ^0.4.0;


contract EthermillionBoard {
    /**
     * The total number of tokens
     */
    uint constant public TOTAL_TOKEN_SUPPLY = 10000000;

    /**
     * The unit price of a token during pre-sale
     */
    uint constant public PRICE_PER_TOKEN = 6666666666666666 wei;

    struct TokenHolder {
    uint nTokens;
    uint lastTotalDividends;
    }

    /**
     * A list of shareholders
     */
    mapping (address => TokenHolder) public tokenholders;

    uint public totalDividends = 0;

    function EthermillionBoard() {
        tokenholders[msg.sender].nTokens = TOTAL_TOKEN_SUPPLY;
    }

    /**
     * This function deposits dividends to be shared between token holders.
     * It is called at the end of the lottery, byt the lottery itself
     */
    function Deposit() payable {
        totalDividends += msg.value;
    }

    /**
     * Buy tokens. Will buy as many tokens as possible with the ether passed
     * to the function.
     *
    function() payable {
        // How many tokens can this amount buy?
        var nTokens = msg.value / PRICE_PER_TOKEN;

        // Is this amount of tokens is more than the rest of the available
        // tokens
        if (nTokens > nAvailableTokens) {
            // Send all available tokens
            nAvailableTokens = 0;
            tokenholders[msg.sender].nTokens += nAvailableTokens;

            // Refund the sender of the excess
            var refund = msg.value - (nAvailableTokens * PRICE_PER_TOKEN);
            msg.sender.transfer(refund);
        }
        else {
            // Remove the bought tokens from the available ones
            nAvailableTokens -= nTokens;

            // Add the bought token to the balance of the holder
            tokenholders[msg.sender].nTokens += nTokens;
        }
    }*/

    /**
     * Send tokens to someone else
     */
    function SendTokens(uint nTokens, address to) payable {
        require(tokenholders[msg.sender].nTokens >= nTokens);
        tokenholders[msg.sender].nTokens -= nTokens;
        tokenholders[to].nTokens += nTokens;
    }

    /**
     * Allow token holders to withdraw their dividends
     */
    function Withdraw() {
        var tokenHolder = tokenholders[msg.sender];

        // This is the total dividends increase between last withdrawal and now
        var newTotalDividends = totalDividends - tokenHolder.lastTotalDividends;

        // The dividends to pay corresponds to the increase in dividends weighted
        // by the number of tokens the holder holds
        var dividendsToPay = newTotalDividends * tokenHolder.nTokens / TOTAL_TOKEN_SUPPLY;

        tokenHolder.lastTotalDividends = totalDividends;
        msg.sender.transfer(dividendsToPay);
    }
}