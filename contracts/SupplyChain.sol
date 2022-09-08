// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract SupplyChain is AccessControlEnumerableUpgradeable, ERC20Upgradeable {
    
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only WAREHOUSE_MANAGER holders can update inventory.
    bytes32 public constant WAREHOUSE_MANAGER_ROLE = keccak256("WAREHOUSE_MANAGER");

    /// @dev Fungible token name
    string private constant _name = "WIDGET";

    /// @dev Fungible token symbol
    string private constant _symbol = "WID";

    /// @dev Price of a widget in wei
    uint256 public price;

    /// @dev Purchase Status
    enum Status {
        ORDERED,
        SHIPPED
    }

    /// @dev Purchase Order info

    struct Order {
        Status status;
        uint256 quantity;
        address customer;
    }

    /// @dev Purchase orders
    mapping (uint256 => Order) public orders;

    /// @dev Next purchase order ID
    uint256 public nextPurchaseOrderId;

    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event StockAdded (
        uint256 quantity,
        address user
    );

    event PriceUpdated (
        uint256 oldPrice,
        uint256 newPrice,
        address user
    );

    event NewOrder (
        uint256 orderId,
        uint256 quantity,
        address user,
        uint256 price,
        uint256 cost
    );

    event OrderShipped (
        uint256 orderId,
        address user
    );

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize() external initializer {
        __ERC20_init(_name, _symbol);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(WAREHOUSE_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Prevent token transfers
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        revert("you are not allowed to transfer widgets");
    }

    /// @dev Widgets are not divisible
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /// @dev Add stock to inventory
    function addStock(uint256 amount) public onlyRole(WAREHOUSE_MANAGER_ROLE) {
        _mint(address(this), amount);
        emit StockAdded(amount, msg.sender);
    }

    /// @dev Set widget price
    function setPrice(uint256 _price) public onlyRole(DEFAULT_ADMIN_ROLE) {
        emit PriceUpdated(price, _price, msg.sender);
        price = _price;
    }

    /// @dev Purchase widget
    function purchase(uint256 _amount) payable public {
        require(totalSupply() >= _amount, "insufficient widgets in inventory");
        require(_amount * price == msg.value, "insufficient funds to make the purchase");
        require(price != 0, "price is not yet set");

        _burn(address(this), _amount);
        orders[nextPurchaseOrderId] = Order(Status.ORDERED, _amount, msg.sender);

        emit NewOrder(nextPurchaseOrderId, _amount, msg.sender, price, price * _amount);
        nextPurchaseOrderId++;
    }

    /// @dev Ship order
    function ship(uint256 _orderId) public onlyRole(WAREHOUSE_MANAGER_ROLE) {
        Order storage order = orders[_orderId];
        require(order.customer != address(0) && order.status == Status.ORDERED, "order cannot be shipped");
        order.status = Status.SHIPPED;

        emit OrderShipped(_orderId, msg.sender);
    }
}