// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/HornMarketplace.sol";

contract TestHornMarketplace {
    // target HornMarketplace contract for testing
    HornMarketplace hornmp = HornMarketplace(DeployedAddresses.HornMarketplace());
    // probably need to target escrow contract as well
    
    // test 

    // test listing an instrument
    function testHornListing() external {
            hornmp.list(
                "Lukas", 
                "Double", 
                "Custom Geyer", 
                696969, 
                msg.sender, 
                address(0)
            );
    }

    // test buying an instrument
    function testHornPurchase() external {}

    // ensure only Sellers can mark horn shipped
    function testMarkAsShipped() external {}

    // ensure only Buyers can mark horn received
    function testMarkReceived() external {}
}
