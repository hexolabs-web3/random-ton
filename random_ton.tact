struct UInt512
{
    h1: Int as uint256;
    h2: Int as uint256;
}

struct RandomTONResult
{
    newSeed: Int as uint256;
    randomNumber: Int as uint256;
}

message RandomTONRegister
{
    randomTonFactoryContract: Address;
}

message RegisterVerifier
{
    clientContract: Address?;
}

message RandomTONHandleRegistration
{
    randomTonContract: Address;
}

message RandomTONRequestRandomness
{
    iterations: Int as uint256;
}

message RandomTONHandleRandomness
{
    randomTonSeed: Int as uint256;
    iterations: Int as uint256;
}

message RandomTONPurchaseSubscription {}

asm fun sha512( s: Builder ): UInt512
{
    ONE HASHEXT_SHA512 UNPAIR
}

asm fun mulrshift256( x: Int, y: Int ): Int
{
    256 MULRSHIFT#
}

trait RandomTON
{
    randomTonContract: Address?;
    randomTonSeed: Int? as uint256; // SHA256 of the VRF beta string.
    randomTonIsHandlingRegistration: Bool; // Flag to protect from rewriting registration

    const randomTonPayAsYouGoFee: Int = ton( "0.3" );
    const randomTonDeploymentFee: Int = ton( "5" );
    const randomTonBasicSubsctiptionTierFee: Int = ton( "27.5" );
    const randomTonProfessionalSubsctiptionTierFee: Int = ton( "130" );
    const randomTonEnterpriseSubsctiptionTierFee: Int = ton( "240" );
    const randomTonMinTransactionValue: Int = ton( "0.01" );

    // Guards.
    fun requireRandomTONContractAddress()
    {
        require( self.randomTonContract != null, "RandomTON verifier contract address is not set." );
    }

    fun requireRandomTON()
    {
        nativeThrowUnless( 132, sender() == self.randomTonContract );
    }

    fun requireHandlingRegistration()
    {
        require( self.randomTonIsHandlingRegistration == true, "RandomTON registration is not being handled right now." );
    }

    // Setters.
    fun randomTonStoreSeed( randomSeed: Int )
    {
        self.randomTonSeed = randomSeed;
    }

    fun randomTonResetSeed()
    {
        self.randomTonSeed = null;
    }

    // Random.
    fun randomTonRandomize( randomSeed: Int, limit: Int ): RandomTONResult
    {
        let random512: UInt512 = sha512(
           beginCell()
               .storeUint( randomSeed, 256 )
        );

        let randomReduced = mulrshift256( random512.h2, limit );

        return RandomTONResult
        {
            newSeed: random512.h1,
            randomNumber: randomReduced
        }
    }

    // Interface.
    // Deploy.
    receive( msg: RandomTONRegister )
    {
        self.randomTonRegistrationGuard();
        self.randomTonIsHandlingRegistration = true;
        send(
            SendParameters
            {
                to    : msg.randomTonFactoryContract,
                value : self.randomTonDeploymentFee,
                bounce: true,
                body  : RegisterVerifier{}.toCell(),
                mode  : SendPayFwdFeesSeparately
            }
        );
    }

    receive( msg: RandomTONHandleRegistration )
    {
        self.requireHandlingRegistration();
        acceptMessage();
        self.randomTonContract = msg.randomTonContract;
        self.randomTonIsHandlingRegistration = false;
    }

    // Subscriptions.
    fun randomTonPurchaseBasicSubscription()
    {
        self.requireRandomTONContractAddress();

        send(
            SendParameters
            {
                to    : self.randomTonContract!!,
                value : self.randomTonBasicSubsctiptionTierFee,
                bounce: true,
                body  : RandomTONPurchaseSubscription{}.toCell(),
                mode  : SendPayFwdFeesSeparately
            }
        );
    }

    fun randomTonPurchaseProfessionalSubscription()
    {
        self.requireRandomTONContractAddress();

        send(
            SendParameters
            {
                to    : self.randomTonContract!!,
                value : self.randomTonProfessionalSubsctiptionTierFee,
                bounce: true,
                body  : RandomTONPurchaseSubscription{}.toCell(),
                mode  : SendPayFwdFeesSeparately
            }
        );
    }

    fun randomTonPurchaseEnterpriseSubscription()
    {
        self.requireRandomTONContractAddress();

        send(
            SendParameters
            {
                to    : self.randomTonContract!!,
                value : self.randomTonEnterpriseSubsctiptionTierFee,
                bounce: true,
                body  : RandomTONPurchaseSubscription{}.toCell(),
                mode  : SendPayFwdFeesSeparately
            }
        );
    }

    abstract fun randomTonRegistrationGuard(); // Override to enforce guard for registration function.

    // Send request.
    virtual fun randomTonRequestRandomness( iterations: Int, isSubscription: Bool )
    {
        self.requireRandomTONContractAddress();

        let messageValue: Int = isSubscription ? self.randomTonMinTransactionValue : self.randomTonPayAsYouGoFee;

        send(
            SendParameters
            {
                to    : self.randomTonContract!!,
                value : messageValue,
                bounce: true,
                body  : RandomTONRequestRandomness{ iterations: iterations }.toCell(),
                mode  : SendPayFwdFeesSeparately
            }
        );
    }

    // Handle response.
    virtual fun randomTonHandleRandomness( randomSeed: Int, iterations: Int )
    {
        self.randomTonStoreSeed( randomSeed );
    }

    receive( msg: RandomTONHandleRandomness )
    {
        self.requireRandomTONContractAddress();
        self.requireRandomTON();

        acceptMessage();

        self.randomTonHandleRandomness( msg.randomTonSeed, msg.iterations );
    }

    receive( "RandomTON Subscription | Commission Refund" ) {}
}
