# Decentralized Future's Market


Possibilities: 

1) Future's market betting between two individuals: 
    Margin in the prices should be collected in prior. Eg: if the Ether price is $3000, and decided to be exchanged at $3500 after 2months, 500 shold be taken from both the individuals.
    At the end, the amounts should be settled.


2) Future's market AMM: 
    LP will provide liquidity for the pool and the traders can trade over the liquidity pool such that they can predict the value of an underlying asset at a future date and they will be provided the particular token. At the advent of the decided date, the future's contract should be settled out.

    => The overall profit made by the pool will be equally distributed to the liquidity providers


3) Implementing cross chain: people from other chains can also bet on our smart contract such that if they wish to pay 
with tokens on different chain, we will give them the option for that as well. 
    If get some profit, the profit can be claimed on any other chain as well!!

    => Liquidity pool will be created for each future's contract. eg: for SOLANA, MATIC, etc.

    => MARGIN MANAGEMENT: Implement margin requirements to make counterparty risk.
    => Settlement management: when the contract matures.
    => CHAINLINK ORACLE integration to get correct market price.
    => <----Staking and reward----->


today's silver price: 75k

    scenario 1: buy future for 70k after 1 month:
        case 1: price fell(70k) : current price and fixed price be same 😑
        case 2: price rise(80k) : someone will be bonded to sell us at low price 😎
 
    scenario 2: buy future for 80k after 1 month: 
        case 1: price fell(50k) : even after price drop, we have to buy at contract(high) price 😭
        case 2: price rise(80k) : current price and fixed price be same 😑

    scenario 3: sell future for 70k after 1 month: 
        case 1: price fell(70k) : current price and fixed price be same 😑
        case 2: price rise(80k) : contract(selling) price is less than current price 😭

    scenario 4: sell future for 80k after 1 month: 
        case 1: price fell(70k) : selling price is more than current price 😎
        case 2: price rise(80k) : current price and fixed price be same 😑

Providing security: 

    case 1: If you are selling the WETH on some future date: 
        Get your WETH stored with us, which can be taken out at any time by settling up the price which may follow
    case 2: If you are purchasing the WETH on some future date:
        Get some required USDC stored with us so that it may act as security for your contract to buy.

Settlement duration: 

    All the contracts would be settled in every 10 days: 
    If a person will give duration as 0, he will be claiming to buy/sell at the immidiate next settlement date, If they are claiming it to be 1, he will be claiming to buy/sell after the next upcoming settlement, and so on...

    Sellers: sellers can sell their WETH by claiming at any time...(from 0 to 2)

    Buyers: buyers can buy the WETH for current slot. further slots can only be claimed if some seller have already claimed to sell afterwards

Settlement process: 

    For each WETH unit to be sold, we need to create a new mapping pointing to an array of addresses for each price possible which are going to provide the available addresses which will to sell the weth at that specific price
        => like mapping (uint256 => address[]) sellerAddresses;

    when any sell or buy request will be made, we will first need to check weather any existing opposite request is already present at the same price. If yes, directly call the function to settle the contracts and change the status of both these contracts to be settled. Make an array for settled contracts as well which will get executed at the end when we will execute all the settled contract.

Execution of Settlement: 

    For each successful settlement, the buyer have to drop the remaining amount of USDC tokens to get the WETH in their account. Then the status of both the contracts, i.e. seller and the buyer will become `Executed`.

Chainlink Products: 

    POLYGON MUMBAI:
    Chainlink data feeds: to get the current price of WETH // ETH/USD: 0x0715A7794a1dc8e42615F059dD6e406A6594651A
    Chainlink automation: to automatically call the settlement function.

Futures Terminology: 
    
    -> Contract Cycle: at a time, three months contracts would be open
    -> Expiration day: last day of contract, all contracts would settled on that day
    -> Tick Size: value at which WETH could be sold in USDC. 1 USDC for us
    -> Contract Size: steps at which WETH could be sold: 1 WETH for us currently
    -> Margin Account: Initial amount deposited by the trader to use the exchange. token money. 10% to 50%
    -> Mark to market: 
    -> Circuit & hault: if buyer or seller became triple of anyone, we will hault the system => check each hour 

Further Updations: 
    
    1) Implement the feature of tick for usdc price
    2) Implement the feature of contract size(slab) for WETH
    3) Every user will be able to make multiple trades, not just one
    4) Make it applicable for upto 3 slots, i.e. _duration to be 0, 1, 2
    5) Make it possible for traders to withdraw their trade by paying a proper amount of compensation.
    6) Make it possible for the traders to call the individual execute rather than us calling it for every contract.



