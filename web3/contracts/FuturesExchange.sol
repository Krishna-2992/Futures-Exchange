// SPDX-License-Identifier: MIT


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.20;

contract FuturesExchange {

    AggregatorV3Interface internal priceFeed;
    IERC20 internal WETHtoken;
    IERC20 internal USDCtoken;

    enum Process { Buy, Sell }
    enum Status { Created, Settled, Executed }

    uint256 private lastSettlementDate;

    /**
     * @param process used to check weather it's a seller or a buyer(and also for checking weather assetDeposited is in WETH(for seller) or USDC(for buyer))
     * @param status used to denote weather the contract have been created, settled or executed
     * @param price the price of WETH at which person claimed to sell or buy
     * @param valueAtCreation the value of the WETH at the time of contract creation
     * @param assetDeposited the amount of asset trader has deposited
     */
    struct Contract {
        address trader;
        Process process;
        Status status;
        uint256 price;
        uint256 createdAt;
        uint256 matureAt;
        uint256 valueAtCreation;
        uint256 assetDeposited;
    }

    struct SettledContracts {
        address seller; 
        address buyer;
    }
    mapping (uint256 => SettledContracts) indexToSettledContracts;
    uint256 private settledContractPairCount;

    mapping (address => Contract) public contracts;
    // mapping (address => uint256) public sellingAmount;
    // mapping (address => uint256) public buyingAmount;

    address[] public traders;
    address[] public sellers;
    address[] public buyers;

    mapping (uint256 => address[]) sellerSlotAddresses;
    mapping (uint256 => address[]) buyerSlotAddresses;

    // for tracking the index of seller/buyers in the slotAddresses. like it's the turn of 3rd buyer to get executed 
    mapping (uint256 => uint256) slotSellerIndex;
    mapping (uint256 => uint256) slotBuyerIndex;

    uint256 public totalSellingAmount;
    uint256 public totalBuyingAmount;

    uint256 public slotSellingAmount;
    uint256 public slotBuyingAmount;

    constructor(address _priceFeed, address _WETHtoken, address _USDCtoken) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        WETHtoken = IERC20(_WETHtoken);
        USDCtoken = IERC20(_USDCtoken);
        lastSettlementDate = block.timestamp;
    }

    /**
     * @dev get your WETH locked so as to sell them at a later date
     * @param _duration duration after which the asset will be sold
     * @param _price price at which asset will be sold after duration
     */
    function sellOneFutureEther(uint8 _duration, uint256 _price) public {
        // check that _duration must lie between 0 and 2
        require(_duration >= 0 && _duration <= 2, "duration must lie between 0 and 2");

        // take the WETH token from the trader
        WETHtoken.transferFrom(msg.sender, address(this), 10**18);

        // make a contract for this future trade
        uint256 maturityTime = getLastSettlementDate() + (10 days) * _duration;
        contracts[msg.sender] = Contract({
            trader: msg.sender,
            process: Process.Sell,
            status: Status.Created,
            price: _price,
            createdAt: block.timestamp,
            matureAt: maturityTime,
            valueAtCreation: getPrice(),
            assetDeposited: 10 ** 18
        });

        // update the storage variables and arrays regarding this trader
        traders.push(msg.sender);
        sellers.push(msg.sender);
        slotSellingAmount += 10**18;
        totalSellingAmount += 10**18;

        // settle the existing buyers with correspondance to this seller
        if(buyerSlotAddresses[_price].length > slotBuyerIndex[_price]) {
            // make the settlemnt between this seller and the buyer at index slotBuyerIndex
            address buyer = buyerSlotAddresses[_price][slotBuyerIndex[_price]];
            // drop the settled contract in the mapping indexToSettledContracts and increase the count
            indexToSettledContracts[settledContractPairCount] = SettledContracts(msg.sender, buyer);
            // increase the slotBuyerIndex by 1
            settledContractPairCount++;
            slotBuyerIndex[_price]++;
        } else {
            // push this seller and its contract in the sellerSlotAddresses[_price] mapping
            sellerSlotAddresses[_price].push(msg.sender);
            
        }

        // if the sellers surpass the amount of total buyers present by 200%, hault the process of selling for 1 hour and make the chainlink automation which will check for the status every hour and if the number of sellers becomes less than 150% of total buyers, then resume the exchange for selling as well

        // here the seller and the buyer refers to the amount of WETH they have claimed to buy/sell

    }

    /**
     * @dev get your USDC locked so as to get WETH at a later date
     * @param _duration duration after which the asset will be sold
     * @param _price price at which asset will be purchased after duration
     */

    function buyOneFutureEther(uint256 _duration, uint256 _price) public {
        require(_duration >= 0 && _duration <= 2, "duration must lie between 0 and 2");
        // get 25% the value of the WETH and make a receiving contract for the trader after the specified duration
        uint256 price = getPrice();
        uint256 usdcTokenReceive = (price * 1e10) / 4;
        USDCtoken.transferFrom(msg.sender, address(this), usdcTokenReceive);

        // make a contract for buy for this trader
        uint256 maturityTime = getLastSettlementDate() + (10 days) * _duration;
        contracts[msg.sender] = Contract({
            trader: msg.sender,
            process: Process.Buy,
            status: Status.Created,
            price: _price,
            createdAt: block.timestamp,
            matureAt: maturityTime,
            valueAtCreation: getPrice(),
            assetDeposited: 10 ** 18
        });
        // update the array regarding this trader
        traders.push(msg.sender);
        buyers.push(msg.sender);
        slotBuyingAmount += 10**18;
        totalBuyingAmount += 10**18;

        if(sellerSlotAddresses[_price].length > slotSellerIndex[_price]) {

            address seller = sellerSlotAddresses[_price][slotSellerIndex[_price]];

            settlePair(seller, msg.sender);


            slotSellerIndex[_price]++;

        } else {
            buyerSlotAddresses[_price].push(msg.sender);
        }
    }

    function settlePair(address seller, address buyer) internal {
        indexToSettledContracts[settledContractPairCount] = SettledContracts(seller, buyer);
        contracts[seller].status = Status.Executed;
        contracts[buyer].status = Status.Executed;
        settledContractPairCount++;
    }

    // // // function to set the deal(bond) for the buyer and the seller

    // function to settle the deal b/w a buyer and a seller

    // function to take out the WETH by settling the price

    // function to increase the security money(in case required)

    // function to get the current WETH price
    function getPrice() public view returns(uint256) {
        (, int answer, , ,) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getDecimals() public view returns(uint8) {
        uint8 decimal = priceFeed.decimals();
        return decimal;
    }

    function getLastSettlementDate() public view returns(uint256) {
        return lastSettlementDate;
    }


    // GETTERS

}

