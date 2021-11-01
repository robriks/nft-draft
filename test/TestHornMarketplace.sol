// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/HornMarketplace.sol";

contract TestHornMarketplace {
    // Declare target HornMarketplace contract for testing
    HornMarketplace market /*= HornMarketplace(DeployedAddresses.HornMarketplace())*/;
    // probably need to target escrow contract as well **apparently not
    // EscrowContract escrow = EscrowContract(DeployedAddresses.EscrowContract());
    
    // @dev This serialNumberCounter gives a new serialNumber to mint fresh Horn NFTs for every subsequent test without any hash collisions from make and serialNumber via the nonDuplicateMint modifier
    uint8 serialNumberCounter;

    /*
        Constructor
    */
    constructor() payable { // prepares this contract with ETH funds on testnet for testing the marketplace contract
        serialNumberCounter = 68;
    }

    /* 
    *  Main Function Tests
    */
    // @dev Sanity checks for horn owner of escrow and marketplace contracts
    function testOwnerOfHornMarketplaceContract() public {
        freshMarketplaceInstance();

        address /*payable*/ returnedOwnerOfHornMarketplaceContract = market.owner();
        address /*payable*/ deployerOfHornMarketplaceContract = msg.sender; // Is this always true? in development I will be the one to call this function and deploy?
        
        assert.equal(returnedOwnerOfHornMarketplaceContract, deployerOfHornMarketplaceContract, "Owner address given by Ownable library function does not match deployer of the Marketplace contract");
    }
    function testOwnerOfEscrow() public {
        freshMarketplaceInstance();

        address /*payable*/ returnedOwnerOfEscrow = market.escrow.owner(); // this is ownable inherited function, may not work
        address /*payable*/ correctOwnerOfEscrow = DeployedAddresses.HornMarketplace();

        assert.equal(returnedOwnerOfEscrow, correctOwnerOfEscrow, "Owner of instantiated escrow contract does not match HornMarketplace contract address");
    }
    // @dev Test minting an instrument for the first time
    // @param Be sure to give the correct __hornId index of Horn struct in horns[] mapping or test will fail; finicky but other variables are private and don't to add attribute storage costs for a simple test
    function testMintThenListNewHornNFT(uint __hornId) public {
        freshMarketplaceInstance();

        uint returnedHornId = mintAndListFreshTestHorn(); // calls market.mintThenListNewHornNFT with preset parameters & incrementing serialNumber, returns hornId
        uint expectedHornId = market._hornId.current();

        /* also need to check: 
        *    nonDuplicateMint (will check if makeAndSerial are accurate) -- _mint a duplicate horn NFT to check against
        *    hornId, outcome of _mint, _setTokenURI, makeAndModel
        */
        HornStatus expectedStatus = HornStatus.ListedForSale; // does it work? HornStatus enum should be inherited from the above import of Marketplace
        // @dev Checks status of the given index of struct mapping horns[__hornId]
        // do nested tests like this work? 
        // if not, consider removing assert() line from end of these helper functions and just have them return plain values and put assert() line here in this function, like so:
        /*assert.equal(*/testGetStatusOfHornById(returnedHornId, expectedStatus)/*, 0, "HornStatus enum returned does not match expected ListedForSale value"*/; // also is this how to pass in an enum parameter? or is uint better
        // @dev Checks currentOwner in mapping vs struct attribute
        /*assert.equal(*/testGetCurrentOwnerMappingAgainstStructAttributeByHornId(returnedHornId)/*,  */;

        assert.equal(returnedHornId, expectedHornId, "HornId returned by mintAndListFreshTestHorn does not match the expectedHornId given by the Marketplace's Counter.Counter");
    }

    // @dev Test minting an instrument for the first time but NOT listing it for sale
    function testMintButDontListNewHornNFT() public {
        freshMarketplaceInstance();
        
        // market.    dkdkdkdk
        // assert.    dkdkdkkd
    } // must check that enum status is set to OwnedNotForSale
    // @dev Test listing an existing Horn NFT
    function testListingExistingHornNFT() public {
        freshMarketplaceInstance();
        mintAndListFreshTestHorn();

        uint hornId = market._hornId.current();
        market.listExistingHornNFT(hornId, 4200000000000000000);

        // assert.    dkkddkdk
    }

    // @dev Test buying an instrument
    function testHornPurchase() public payable {
        freshMarketplaceInstance();
        mintAndListFreshTestHorn();

        uint hornId = market._hornId.current();
        market.purchaseHornByHornId(hornId, "Ju St. Testing, Purchase Attempt New York, 11111");

        // assert.    dkdk
    } // should result in funds deposited to escrow

    // @dev Ensure only Sellers can mark horn shipped
    // @notice Testing for event emission is specifically NOT supported by solidity smart contracts so those tests must be done in javascript!!!

    function testMarkAsShipped() public {
        freshMarketplaceInstance();
        mintAndListFreshTestHorn();

        uint hornId = market._hornId.current();
        prepareForShipped(hornId);

        market.markHornShipped(hornId, DKDKDKDKDKDK);

        // check that approval for __hornId given to marketplace contract was carried out
        // assert.    dkdkdk
    } // javascript version should expect hornShipped event emission with correct address

    // @dev Attempts to mark shipped with a wrong address
    function testMarkAsShippedWithWrongAddress() public {
        // First sets conditions of exchange up to point where markHornShipped would be called
        freshMarketplaceInstance();
        mintAndListFreshTestHorn();
        // if this doesnt work due to internal keyword on counters.counter, add a temporary test function in marketplace contract that returns _hornId.current()
        uint hornId = market._hornId.current();
        prepareForShipped(hornId); // work following setup lines into this helper function

        // Set correct address to prepare for comparison with the mistake address later entered by seller
        realShipTo = "21 Mil St. BTCidatel, Metaverse 69696";
        // Purchase NFT so it is primed for a markHornShipped() call
        market.purchaseHornByHornId(hornId, realShipTo);

        // feed in a wrong address to ensure require() line prevents seller from shipping to the wrong place
        mistakeShipTo = "21 Million Silk Rd. Darknet, Metaverse 66666";
        bool mistakenShippingAddress = market.markHornShipped(hornId, mistakeShipTo); // wrap mistakenShippingAddress: (mistakenShippingAddress,) ?? is this what formats the error msg

        // uses helper function to check that status is still PaidFor and didn't execute change to Shipped
        /*assert.isTrue(*/testGetStatusOfHornById(hornId, HornStatus.PaidFor); // might need to remove assert from inside helper function and move it to this larger host function here

        assert.isFalse(mistakenShippingAddress, "A seller somehow managed to ship a horn to the wrong address");
    }

    // @dev Ensure markHornDeliveredAndOwnershipTransferred is working as intended
    function testMarkHornDeliveredAndOwnershipTransferred() public {
        // First sets conditions of exchange up to the point where markHornDeliveredAndOwnershipTransferred would be called
        freshMarketplaceInstance();
        mintAndListFreshTestHorn();

        uint hornId = market._hornId.current(); // if this getter doesnt work then use a temporary testing getter function to return current id
        prepareForShipped(hornId);
        market.markHornDeliveredAndOwnershipTransferred(hornId); // ^
        // Check that HornStatus status of hornNFT was correctly updated to OwnedNotForSale (== 3?)
        testGetStatusOfHornById(hornId, HornStatus.OwnedNotForSale);
        // Check that currentOwner was correctly updated to buyer
        address payable currentOwnerViaMapping = market.getCurrentOwnerByMapping(hornId);
        assert.equal(currentOwnerViaMapping, payable(address(this)), "CurrentOwner of Horn NFT as returned by storage mapping does not match expected address"); //if address(this) is not considered msg.sender, use msg.sender as second parameter instead
        // Check that currentOwner is consistent in both the mapping and the struct attribute
        testGetCurrentOwnerMappingAgainstStructAttributeByHornId(hornId);
        // Check that ERC721 method safeTransferFrom was executed properly
        // return balanceOf(address(this)); // wrap payable? use msg.sender? import ierc721?
    } // Javascript mirror test should expect HornDelivered event emission with correct seller, buyer addresses

    // @notice Modifier tests to ensure that access control and other modifier functions work properly
    // maybe put these test functions in the Helper Function section below ?
    /* 
    * // @dev Attempts to call transfer ownership function from non-buyer address without paying
      // @dev Ensures only buyer can markHornDeliveredAndOwnershipTransferred
    * function testOnlyBuyerWhoPaid() public {
        //fresh instances and minds?

        mintAndListFreshTestHorn();
        uint hornId = market._hornId.current(); // identify most recent Horn NFT
        // prepareForShipped(hornId);

        bool thieveryAttempt = market.markHornDeliveredAndOwnershipTransferred(hornId); // {from: msg.sender} may need this line because this contract isn't an IERC721TokenReceiver to pass the market's safeTransferFrom() method
        // make sure state of nft is correct except for onlyBuyer()

        assert.isFalse(thieveryAttempt, "An account that hasn't paid or been marked as buyer pilfered the NFT!");
    }
    * // @dev Attempts to call listExistingHornNFT() From non-seller address who isn't currentOwner of the horn
    * function testOnlySellerViaList() public {
        // fresh instances and mints?

        uint hornId = market._hornId.current(); // identify most recent horn NFT
        // impersonator tries to sell someone else's NFT for 1 ether
        bool sellerImpersonation = market.listExistingHornNFT(hornId, 1000000000000000000); // {from: accounts[1]} may need this line so address calling function isn't the same one who minted
        // make sure state of nft is correct except for onlySeller()

        assert.isFalse(sellerImpersonation, "A rogue account was able to sell a horn NFT that it didn't own");
    }
    * function testOnlySellerViaMarkShipped() public {
        //fresh instances and miints?

        uint hornId = market._hornId.current();
        bool shipperImpersionation = market.markHornShipped(hornId, "4 Ju St. ShipsVille, Virgin Beach 66666");

        assert.isFalse(shipperImpersonation, "A pirate just impersonated a shipper and shipped a horn they don't own");
    }
    * // attempts to call purchaseHornById without having paid enough ETH
    * function testPaidEnough() public {
        //fresh instances and mints?

    /*  uint hornId = market._hornId.current(); // identify most recent horn NFT
        bool paidTooMuch = market.purchaseHornByHornId(
            hornId, 
            "420 69th St. Phallus, Virgin Islands 42069")
            .call({ value: 1000000000000000005 }); // {from: address(this)} needed??
        // make sure state of nft is correct except for paidEnough())

        assert.isFalse(paidTooMuch, "A generous soul got ripped off and was able to purchase a horn with msg.value that didn't match listPrice");
    }
    * // attempts to call purchaseHornById on a horn that is not currently for sale
    * function testForSale() public {
        //fresh instances and mints?

        uint hornId = market._hornId.current(); // identify most recent horn NFT
        market.initiateRefundOrSetStatusToOwnedNotForSale(hornId); // set to OwnedNotForSale enum
        bool yourMoneyNotWelcomeHere = market.purchaseHornByHornId(
            hornId,
            "420 69th St. Phallus, Virgin Islands 42069")
            .call({ value: 1000000000000000000 }); // {from: address(this)} needed?
        
        assert.isFalse(yourMoneyNotWelcomeHere, "A sneaky user found a way to buy without being given consent");
    }
    
    // attempts to call markHornShipped when horn is not yet paid for in escrow
    * function testHornPaidFor() public {
        // fresh instances and mints?

        uint hornId = market._hornId.current(); // identify most recent horn NFT
        bool stillWaitingOnFunds = market.markHornShipped(hornId);
        // set state of nft to be correct except hornPaidFor()

        assert.isFalse(stillWaitingOnFunds, "A silly seller shipped a horn without receiving payment");
    }
    // attempts to call markHornDeliveredAndOwnershipTransferred when horn is not yet marked shipped by seller
    * function testShipped() public {
        // fresh instances and mints? 

        uint hornId = market._hornId.current(); // identify most recent horn NFT
        bool notShippedYet = market.
        // set state of nft to be correct except shipped()

        assert.isFalse(notShippedYet, "Horn can not be marked delivered and NFT ownership transferred since it has not yet been marked shipped");
    }
    // @dev Attempts to mint a duplicate Horn NFT, which should fail the nonDuplicateMint modifier
    function testNonDuplicateMint() public {
        // fresh instances and mints?

        market.mintAndListFreshTestHorn();

        bool copycatMint = market.mintThenListNewHornNFT(
            "Berg",
            "Double",
            "Geyer",
            serialNumberCounter,
            4200000000000000000
        );

        assert.isFalse(copycatMint, "A corrupt copycat was able to mint a Horn NFT with duplicate hash of make and serialNumber");
    }
    */

    /*
    *   Helper Functions 
    *  
    *   To be used both generally outside transactions as well as inside main tests for behavior tracking
    */
    // @dev Instantiates a fresh instance of the Horn Marketplace contract for cleaner testing
    // @notice Intended to be used prior to nearly every test, except ones that rely on having existing NFTs or hornIds
    function freshMarketplaceInstance() public {
        market = new HornMarketplace();
    }
    // @dev Mints a fresh Horn NFT for testing purposes
    // @param serialNumberCounter is incremented every time this function is called so that the nonDuplicateMint modifier hashes make and serial data without collision
    function mintAndListFreshTestHorn() public returns (uint) {
        serialNumberCounter++;
        market.mintThenListNewHornNFT(
            "Berg",
            "Double",
            "Geyer", 
            serialNumberCounter,
            4200000000000000000
        );

        return serialNumberCounter;
    }
    // @dev Prepares a given Horn NFT for markShipped testing
    function prepareForShipped(uint hornId) public {}
    // @dev Prepares a given Horn NFT for markHornDelivered and transfer testing
    function prepareForTransfer(uint hornId) public {}
    // @dev Test price getter function of listPrice attribute inside horn struct of given HornId
    // @notice This function is used as a helper at different stages of the transaction to track intended behavior
    function testGetListPriceByHornId(uint __hornId) public returns (bool) {
        uint expectedPrice = horns[__hornId].listPrice;
        uint returnedPrice = market.testGetListPriceByHornId(__hornId);
        // if this doesnt work as a nested test, just remove assert.equal and use a require() statement so this function returns (bool) which is easy to work with in the larger host functions

        assert.equal(expectedPrice == returnedPrice, "Expected listPrice attribute of horn NFT struct does not match the one given by marketplace getter function");
    }

    // @dev Test current owner getter function by getting returned address of given hornId
    // @notice This function is used as a helper at different stages of the transaction to track intended behavior
    function testGetCurrentOwnerMappingAgainstStructAttributeByHornId(uint __hornId) public {
        address payable mappingOwner = market.getCurrentOwnerByMapping(__hornId);
        address payable structOwner = market.getCurrentOwnerByStructAttribute(__hornId);
        // if this doesnt work as a nested test, just remove assert.equal and use a require() statement so this function returns (bool) which is easy to work with in the larger host functions
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
        // if this doesnt work as a nested test, just use a require() statement so this function returns (bool) which is easy to work with in the larger host functions
        assert.equal(returnedEnum, expectedEnum, "HornStatus enum uint returned by marketplace contract does not match the expected one given");
    } 
    // @dev Test the current balance of deposits for given address in escrow contract 
    function testGetEscrowDepositValue(address payee) public {
        uint returnedDepositValue = market.getEscrowDepositValue(payee);
        uint correctDepositValue = market.escrow.depositsOf(payee);
        // if this doesnt work as a nested test, just use a require() statement so this function returns (bool) which is easy to work with in the larger host functions
        assert.equal(returnedDepositValue, correctDepositValue, "Value returned by getEscrowDepositValue does not match escrow depositsOf method");
    } 
}
    // @dev Test the behavior of marketplace contract on receipt of only ETH without data
    // @dev Should revert on receipt of ETH without msg.data via fallback() function
    function testIncomingEther() public payable {
        bool dryEthSend = market.call{ value: 10000000000000000 }();

        assert.isFalse(dryEthSend, "Warning: a suspiciously generous soul donated funds to the marketplace contract without msg.data");
    }
