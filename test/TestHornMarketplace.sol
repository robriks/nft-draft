// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/HornMarketplace.sol";

contract TestHornMarketplace {
    // target HornMarketplace contract for testing
    HornMarketplace market = HornMarketplace(DeployedAddresses.HornMarketplace());
    // probably need to target escrow contract as well **apparently not
    // EscrowContract escrow = EscrowContract(DeployedAddresses.EscrowContract());

    /*
        Constructor
    */
    constructor() payable { // prepares this contract with ETH funds for testing the marketplace contract
    }

    /* 
    *  Main Tests
    */
    // @dev Sanity checks forhorn owner of escrow and marketplace contracts
    function testOwnerOfHornMarketplaceContract() public {
        address /*payable*/ returnedOwnerOfHornMarketplaceContract = market.owner();
        address /*payable*/ deployerOfHornMarketplaceContract = msg.sender; // Is this always true? in development I will be the one to call this function and deploy?
        
        assert.equal(returnedOwnerOfHornMarketplaceContract, deployerOfHornMarketplaceContract, "Owner address given by Ownable library function does not match deployer of the Marketplace contract");
    }
    function testOwnerOfEscrow() public {
        address /*payable*/ returnedOwnerOfEscrow = market.escrow.owner(); // this is ownable inherited function, may not work
        address /*payable*/ correctOwnerOfEscrow = DeployedAddresses.HornMarketplace();

        assert.equal(returnedOwnerOfEscrow, correctOwnerOfEscrow, "Owner of instantiated escrow contract does not match HornMarketplace contract address");
    }
    // @dev Test minting an instrument for the first time
    // @param Be sure to give the correct __hornId index of Horn struct in horns[] mapping or test will fail; finicky but other variables are private and don't to add attribute storage costs for a simple test
    function testMintThenListNewHornNFT(uint __hornId) public {
            market.mintThenListNewHornNFT(
                "Lukas", 
                "Double", 
                "Custom Geyer", 
                696969, 
                16000,
            );

            /* need to check: 
            *    nonDuplicateListing (will check if makeAndSerial are accurate) -- _mint a duplicate horn NFT to check against
            *    hornId, outcome of _mint, _setTokenURI, makeAndModel
            */

            // do nested tests like this work? otherwise separate them in order
            // this test checks status of the given index of struct mapping horns[__hornId], be sure to give correct index and correct enum status
            testGetStatusOfHornById(__hornId, ListedForSale); // is this how to pass in an enum parameter?
            testGetCurrentOwnerMappingAgainstStructAttributeByHornId(__hornId);

            assert.equal(returned_hornId, expected_hornId, "");
    }

    // @dev Test listing an existing HornNFT
    function testListingExistingHornNFT() public {}

    // @dev Test buying an instrument
    function testHornPurchase() public {} // should result in funds deposited to escrow, shouuld access restrict to onlyBuyers

    // @dev Ensure only Sellers can mark horn shipped
    function testMarkAsShipped(uint __hornId, string _shipTo) public {} // should expect hornShipped event emission with correct address

    // @dev Ensure only Buyers can mark horn received
    function testMarkHornDeliveredAndOwnershipTransferred(uint __hornId) public {
        market.markHornDeliveredAndOwnershipTransferred(__hornId);
        // Check that HornStatus status of hornNFT was correctly updated to OwnedNotForSale (== 3)
        testGetStatusOfHornById(__hornId, 3);
        // Check that currentOwner was correctly updated to buyer
        address payable currentOwnerViaMapping = market.getCurrentOwnerByMapping(__hornId);
        assert.equal(currentOwnerViaMapping, payable(address(this)), "errmsg"); //if address(this) is not considered msg.sender, use msg.sender as second parameter instead
        // Check that currentOwner is consistent in both the mapping and the struct attribute
        testGetCurrentOwnerMappingAgainstStructAttributeByHornId(__hornId);
    } // should expect HornDelivered event emission with correct seller, buyer addresses

    // @notice Modifier tests ensure that access control and other modifier functions work properly
    // These test functions may be incorporated into the Helper Function section below ?
    /* 
    * function testOnlyBuyerWhoPaid(uint __hornId) {
        try calling a function with onlybuyerwhopaid modifier from a non-buyer address who didn't pay

        // CHECK IF STRUCTS HAVE DEFAULT GETTERS - if so, reading Counters.Counter _hornId should be useful (made public for testing)
        hornId = market._hornId.current();
        bool thieveryAttempt = market.markHornDeliveredAndOwnershipTransferred(hornId);

        assert.isFalse(thieveryAttempt, "An account that hasn't paid or been marked as buyer pilfered the NFT!");
    }
    */

    /*
    *   Helper Functions 
    *  
    *   To be used both generally outside transactions as well as inside main tests for behavior tracking
    */
    // @dev Test price getter function of listPrice attribute inside horn struct of given HornId
    // @notice This function is used as a helper at different stages of the transaction to track intended behavior
    function testGetListPriceByHornId(uint __hornId) public {} 

    // @dev Test current owner getter function by getting returned address of given hornId
    // @notice This function is used as a helper at different stages of the transaction to track intended behavior
    function testGetCurrentOwnerMappingAgainstStructAttributeByHornId(uint __hornId) public {
        address payable mappingOwner = market.getCurrentOwnerByMapping(__hornId);
        address payable structOwner = market.getCurrentOwnerByStructAttribute();

        assert.equal(mappingOwner, structOwner, "currentOwner of horn NFT via mapping does not match that of currentOwner via struct attribute");
    }

    // @dev Test current enum status getter function via given hornId
    // @notice This function is used as a helper at different stages of the transaction to track intended behavior
    function testGetStatusOfHornById(uint __hornId, HornStatus _expectedStatus) public {
        // convert given expected HornStatus enum to a uint for comparison to market's function returnedEnum
        if (uint(expectedStatus) == 0) {
            uint expectedEnum = 0; 
        } else if (uint(expectedStatus) == 1) {
            uint expectedEnum = 1;
        } else if (uint(expectedStatus) == 2) {
            uint expectedEnum = 2;
        } else if (uint(expectedStatus) == 3) {
            uint expectedEnum = 3;
        }
        uint returnedEnum = uint(market.getStatusOfHornByHornId(__hornId));

        assert.equal(returnedEnum, expectedEnum, "HornStatus enum uint returned by marketplace contract does not match the expected one given");
    } 
    // @dev Test the current balance of deposits for given address in escrow contract 
    function testGetEscrowDepositValue(address payee) public {
        uint returnedDepositValue = market.getEscrowDepositValue(payee);
        uint correctDepositValue = market.escrow.depositsOf(payee);

        assert.equal(returnedDepositValue, correctDepositValue, "Value returned by getEscrowDepositValue does not match escrow depositsOf method");
    } 
}

    function testIncomingEther() public {} // should revert on receipt of solely ETH without msg.data via fallback() function
