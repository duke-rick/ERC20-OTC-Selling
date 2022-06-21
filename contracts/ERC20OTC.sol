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
        orderNonce++;
    }

    function cancelOTCOrder(uint256 orderId) public {
        Order memory order = orders[orderId];

        if ((order.maker != msg.sender))
            revert("You aren't the creater of this order");

        order.makerTokenAddress.safeTransfer(address(this), order.amountMaker);
        delete orders[orderId];
        amount_Of_Orders.decrement();
        emit orderCancelled(order);
    }

    function purchaseOTCOrder(uint256 orderId) public payable {
        Order memory order = orders[orderId];
        if ((order.amountTaker != msg.value))
            revert(
                "You don't have enough tokens to meet the requirments of this trade"
            );

        if (order.maker == address(0))
            revert("Can't fufill this order as it doesn't exist");

        order.makerTokenAddress.safeTransfer(order.taker, order.amountMaker);
        order.takerTokenAddress.safeTransfer(order.maker, order.amountTaker);

        amount_Of_Orders.decrement();
        emit tradeCompleted(order.maker, order.taker, order);
        delete orders[orderId];
    }

    function getMarketOTCOrders() public view returns (Order[] memory) {
        uint256 orderAmounts = amount_Of_Orders.current();
        uint256 order_Amount_Index = 0;

        Order[] memory pieces = new Order[](orderAmounts);

        for (uint256 i = 0; i < orderNonce; i++) {
            if (orders[i + 1].orderId == orderNonce) {
                uint256 nonce = i + 1;
                Order storage currentpiece = orders[nonce];
                pieces[order_Amount_Index] = currentpiece;
                order_Amount_Index += 1;
            }
        }

        return pieces;
    }

    function getOrder(uint256 orderId) public view returns (Order memory) {
        Order memory order = orders[orderId];

        return order;
    }

    function getMyOrders(address myaddress)
        public
        view
        returns (Order[] memory)
    {
        uint256 orderAmounts = amount_Of_Orders.current();
        uint256 order_Amount_Index = 0;

        Order[] memory pieces = new Order[](orderAmounts);

        for (uint256 i = 0; i < orderNonce; i++) {
            if (orders[i + 1].maker == myaddress) {
                uint256 nonce = i + 1;
                Order storage currentpiece = orders[nonce];
                pieces[order_Amount_Index] = currentpiece;
                order_Amount_Index += 1;
            }
        }

        return pieces;
    }
    // END OF CONTRACT
}
