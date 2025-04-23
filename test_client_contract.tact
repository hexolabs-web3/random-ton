import "@stdlib/deploy";
import "@stdlib/ownable";

import "./random_ton";

contract TestClientContract with Deployable, Ownable, RandomTON {

    // Initialize.
    randomTonContract: Address?;
    randomTonSeed: Int? as uint256;
    randomTonIsHandlingRegistration: Bool;
    owner: Address;

    init() {
        self.owner = sender();
        self.randomTonContract = null;
        self.randomTonSeed = null;
        self.randomTonIsHandlingRegistration = false;
    }

    override fun randomTonRegistrationGuard()
    {
        self.requireOwner();
    }

    // Request randomness.
    receive( "Request RandomTON Pay-As-You-Go" ) {
        self.requireOwner();
        let numberOfWinners: Int = 5;
        self.randomTonRequestRandomness(numberOfWinners, false);
    }

    receive( "Request RandomTON with Subscription" ) {
        self.requireOwner();
        let numberOfWinners: Int = 5;
        self.randomTonRequestRandomness(numberOfWinners, true);
    }

    receive( "Purchase RandomTON Subscription" ) {
        self.requireOwner();
        self.randomTonPurchaseBasicSubscription();
    }

    // Use randomness.
    override fun randomTonHandleRandomness(randomSeed: Int, numberOfWinners: Int) {
        let numberOfPlayers: Int = 10000;
        repeat (numberOfWinners) {
            let result: RandomTONResult = self.randomTonRandomize(randomSeed, numberOfPlayers);
            let randomNumber: Int = result.randomNumber;
            randomSeed = result.newSeed;

            send(
                SendParameters
                {
                    to    : self.owner,
                    bounce: false,
                    value : self.randomTonMinTransactionValue,
                    mode  : SendPayFwdFeesSeparately | SendIgnoreErrors,
                    body  : beginComment()
                        .concat( "Winner: " )
                        .concat( randomNumber.toString() )
                        .toCell()
                }
            );
        }
    }

    receive( "Withdraw" )
    {
        self.requireOwner();
        send(
            SendParameters
            {
                to   : self.owner,
                value: 0,
                mode : SendRemainingBalance
            }
        );
    }

    receive( "Cashup" )
    {
        self.requireOwner();
    }
}
