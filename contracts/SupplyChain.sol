// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SupplyChain is AccessControlEnumerableUpgradeable, ERC20Upgradeable {
    
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only WAREHOUSE_MANAGER holders can update inventory.
    bytes32 private constant WAREHOUSE_MANAGER_ROLE = keccak256("WAREHOUSE_MANAGER");

    /// @dev Fungible token name
    string private constant _name = "WIDGET";

    /// @dev Fungible token symbol
    string private constant _symbol = "WID";

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
    function addStock() public onlyRole(WAREHOUSE_MANAGER_ROLE) {

    }
}