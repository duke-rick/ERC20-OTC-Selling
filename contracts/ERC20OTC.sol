//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Imported Libraries
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20OTC {
    // Sets variable for counting amount of active OTC Orders
    using Counters for Counters.Counter;
    Counters.Counter private amount_Of_Orders;

    using SafeERC20 for IERC20;

    //Initalises OTC order nonce
    uint256 orderNonce = 1;

    // Event for when a new order is created
    event newOrder(Order order);

    // Event for when an order is completed
    event tradeCompleted(
        address indexed maker,
        address indexed taker,
        Order order
    );

    // Event for when an order is cancelled
    event orderCancelled(Order order);

    // A Struct for the different orders being created
    struct Order {
        address maker;
        address taker;
        IERC20 makerTokenAddress;
        IERC20 takerTokenAddress;
        uint256 amountMaker;
        uint256 amountTaker;
        uint256 orderId;
    }

    // Mapping of OTC Orders
    mapping(uint256 => Order) public orders;

    constructor() {
        console.log("Deployed to mainnet/testnet");
    }

    // Creates a new OTC Order
    function setOTCOrder(
        address takerAddress,
        IERC20 makerToken,
        IERC20 takerToken,
        uint256 makerAmount,
        uint256 takerAmount
    ) public {
        Order memory order = Order({
            maker: msg.sender,
            taker: takerAddress,
            makerTokenAddress: makerToken,
            takerTokenAddress: takerToken,
            amountMaker: makerAmount,
            amountTaker: takerAmount,
            orderId: orderNonce
        });

        orders[orderNonce] = order;

        emit newOrder(order);

        order.makerTokenAddress.safeTransfer(address(this), makerAmount);
        amount_Of_Orders.increment();
    }
}
