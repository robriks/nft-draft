// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/HornMarketplace.sol";

contract TestHornMarketplace {
    // target HornMarketplace contract for testing
    HornMarketplace market = HornMarketplace(DeployedAddresses.HornMarketplace());
    // probably need to target escrow contract as well
    EscrowContract escrow = EscrowContract(DeployedAddresses.EscrowContract());

    /* 
        Tests!
    */

    // @dev Test minting an instrument for the first time
    function testHornListing() external {
            market.list(
                "Lukas", 
                "Double", 
                "Custom Geyer", 
                696969, 
                msg.sender, 
                address(0)
            );
    }

    // @dev Test listing an existing HornNFT
    function testListingExistingHornNFT() external {}

    // @dev Test buying an instrument
    function testHornPurchase() external {} // should result in funds deposited to escrow, shouuld access restrict to onlyBuyers

    // @dev Ensure only Sellers can mark horn shipped
    function testMarkAsShipped(uint __hornId, string _shipTo) external {} // should expect hornShipped event emission with correct address

    // @dev Ensure only Buyers can mark horn received
    function testMarkDelivered(uint __hornId) external {} // should expect HornDelivered event emission with correct seller, buyer addresses

    // @dev Test price getter function
    function testGetListPriceByHornId(uint __hornId) external {} // should return listPrice attribute of horn struct of given HornId

    // @dev Test current owner getter function
    function testGetCurrentOwnerByHornId(uint __hornId) external {} // should return address of owner of given hornId

    // @dev Test current status getter function
    function testGetStatusOfHornById(uint __hornId) external {} // should return enum status of given hornId
}
