// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/HornMarketplace.sol";

contract TestHornMarketplace {
    // Declare targeted HornMarketplace, Seller, and Buyer contracts for instantiating and subsequent testing
    HornMarketplace market /*= HornMarketplace(DeployedAddresses.HornMarketplace())*/;
    Seller seller;
    Buyer buyer;
    // may need to target escrow contract as well? it's instantiated by Marketplace contract
    // EscrowContract escrow = EscrowContract(DeployedAddresses.EscrowContract());
    
    uint defaultSerialNumber;
    uint defaultListPrice;

    /*
        Constructor
    */
    constructor() payable { // prepares this contract with ETH funds on testnet for testing the marketplace contract    
        defaultSerialNumber = 69; // lelz
        defaultListPrice = 420; // lelz
    }

    /* 
    *  Main Function Tests
    */
    // @notice Testing for event emission is specifically NOT supported by solidity smart contracts so those tests must be done in javascript
    // @dev Sanity checks for horn owner of escrow and marketplace contracts
    function testOwnerOfHornMarketplaceContract() public {
        freshMarketplaceAndSellerBuyerInstance();

        address /*payable*/ returnedOwnerOfHornMarketplaceContract = market.owner();
        address /*payable*/ deployerOfHornMarketplaceContract = msg.sender; // Is this always true? in development I will be the one to call this function and deploy?
        
        assert.equal(returnedOwnerOfHornMarketplaceContract, deployerOfHornMarketplaceContract, "Owner address given by Ownable library function does not match deployer of the Marketplace contract");
    }
    function testOwnerOfEscrow() public {
        freshMarketplaceAndSellerBuyerInstance();

        address /*payable*/ returnedOwnerOfEscrow = market.escrow.owner(); // this is ownable inherited function, may need to import ownable
        address /*payable*/ correctOwnerOfEscrow = DeployedAddresses.HornMarketplace();

        assert.equal(returnedOwnerOfEscrow, correctOwnerOfEscrow, "Owner of instantiated escrow contract does not match HornMarketplace contract address");
    }
    // @dev Test minting an instrument for the first time
    // @param Be sure to give the correct __hornId index of Horn struct in horns[] mapping or test will fail; finicky but other variables are private and don't to add attribute storage costs for a simple test
    function testMintThenListNewHornNFT() public {
        freshMarketplaceAndSellerBuyerInstance();

        uint returnedHornId = seller.mintAndListFreshTestHorn(); // calls market.mintThenListNewHornNFT with preset parameters & incrementing serialNumber, returns currentHornId
        uint expectedHornId = 1; // Expected currentHornId should be 1 after minting to a fresh contract instance

        // test hornId, 
        // test outcome of _mint
        // test _setTokenURI

        // @dev Checks status of the given index of struct mapping horns[__hornId]
        assert.isTrue(testGetStatusOfHornById(returnedHornId, HornStatus.ListedForSale), "HornStatus enum returned does not match expected ListedForSale value";
        // @dev Checks currentOwner in mapping vs struct attribute
        /*assert.equal(*/testGetCurrentOwnerMappingAgainstStructAttributeByHornId(returnedHornId)/*,  */;

        assert.equal(returnedHornId, expectedHornId, "returnedHornId given by mintAndListFreshTestHorn's Counter.Counter does not match the expectedHornId of 1 for a fresh contract instance's first mint");
        // check that listprice was updated
        assert.isTrue(testGetListPriceByHornId(returnedHornId));
    }

    // @dev Test minting an instrument for the first time but NOT listing it for sale
    function testMintButDontListNewHornNFT() public {
        freshMarketplaceAndSellerBuyerInstance();
        
        // market.    dkdkdkdk
        // assert.    dkdkdkkd
    } // must check that enum status is set to OwnedNotForSale
    // @dev Test listing an existing Horn NFT
    function testListingExistingHornNFT() public {
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();

        uint hornId = market._hornId.current();
        market.listExistingHornNFT(hornId, 4200000000000000000);

        // Check that listPrice was updated
        // assert.    dkkddkdk
    }

    // @dev Test buying an instrument with this contract
    // @param Since only one horn was minted, hornId is used here for an extra purpose: as the index within hornsForSale[] array that is deleted upon execution of purchase. This would not work for testing multiple mints
    function testHornPurchase() public payable {
        // Set conditions to prepare for purchaseHornByHornId()
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();

        uint hornId = market._hornId.current();
        string memory testAddress = "Ju St. Testing, Purchase Attempt New York, 11111";
        // THIS LINE USES THIS CONTRACT TO BUY, seems reasonable unless it breaks testing
        market.purchaseHornByHornId(hornId, testAddress); // {value:}

        // @param Seller contract referenced because depositsOf refers to the payee, in this case the seller
        uint returnedDeposits = escrow.depositsOf(DeployedAddresses.Seller());
        uint hornListPrice = market.horns[hornId].listPrice;
        string memory returnedShippingAddress = market.shippingAddresses[address(this)];
        address returnedBuyerAddress = market.buyers[hornId];
        uint shouldHaveBeenDeleted = market.hornsForSale[hornId];

        // Check that escrow deposit was executed properly
        assert.equal(returnedDeposits, hornListPrice, "Amount of deposited funds to escrow contract does not match the listPrice attribute of the horn NFT, check escrow deposit execution");
        // Check that shippingAddresses mapping was updated with 2nd parameter
        assert.equal(returnedShippingAddress, testAddress, "Shipping address returned by shippingAddresses[] mapping does not match the test address provided to purchaseHornByHornId function");
        // Check that buyers mapping was updated to msg.sender, in this case address(this)
        assert.equal(returnedBuyerAddress, address(this), "Address returned by market buyers[] mapping does not match the one that purchased the instrument, in this case this contract");
        // Check that status was updated to PaidFor
        assert.equal(testGetStatusOfHornById(hornId, HornStatus.PaidFor), "HornStatus was not successfully updated to PaidFor, check execution of purchaseHornByHornId()");
        // Check that hornId was deleted from hornsForSale[] uint[] array
        assert.isZero(shouldHaveBeenDeleted, "Value returned by hornsForSale[] uint[] array was not 0, meaning it was not properly deleted upon execution of purchase");
        // javascript tests for event emissions
    }

    // @dev Ensure only Sellers can mark horn shipped
    function testMarkHornShipped() public {
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();

        uint hornId = market._hornId.current();
        buyer.prepareForShipped(hornId); // {value: }
        seller.prepareForTransfer(hornId);
        
        // Check that approval for __hornId given to marketplace contract was carried out
        address returnedApprovedAddressForHornId = getApproved(hornId); // import ERC721?
        address expectedApprovedAddressForHornId = DeployedAddresses.Buyer();
        
        assert.Equal(returnedApprovedAddressForHornId, expectedApprovedAddressForHornId, "Returned approved address for tokenId doesn't match expected address, check execution of Approve()");

        // Use helper function to check that status was updated to Shipped
        assert.isTrue(testGetStatusOfHornById(hornId, HornStatus.Shipped), "HornStatus was not successfully updated to Shipped, check execution of markHornShipped()");
    } // javascript version should expect hornShipped event emission with correct address

    // @dev Attempts to mark shipped with a wrong address
    function testMarkHornShippedWithWrongAddress() public {
        // First sets conditions of exchange up to point where markHornShipped would be called
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();

        uint hornId = market._hornId.current(); // may need to add a temporary test function in marketplace contract that returns _hornId.current()
        // Set correct address to prepare for comparison with the mistake address later entered by seller
        string memory realShipTo = buyer.prepareForShipped(hornId); // {value: }

        // Feed in a wrong address to ensure require() line prevents seller from shipping to the wrong place
        string memory mistakeShipTo = "21 Million Silk Rd. Darknet, Metaverse 66666";
        bool mistakenShippingAddress = market.markHornShipped(hornId, mistakeShipTo);

        // Use helper function to check that status is still PaidFor and didn't execute change to Shipped
        assert.isTrue(testGetStatusOfHornById(hornId, HornStatus.PaidFor), "HornStatus was somehow changed, check execution of markHornShipped");
        // Ascertain mistakenShippingAddress is falsy and didn't execute markHornShipped
        assert.isFalse(mistakenShippingAddress, "A seller somehow managed to ship a horn to the wrong address");
    }

    // @dev Ensure markHornDeliveredAndOwnershipTransferred is working as intended
    function testMarkHornDeliveredAndOwnershipTransferred() public {
        // Set conditions of exchange up to the point where markHornDeliveredAndOwnershipTransferred would be called
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();

        uint hornId = market._hornId.current();
        buyer.prepareForShipped(hornId); // {value: listPrice} 

        uint returnedPaymentAmt = buyer.deliveredAndTransfer(hornId);

        address payable currentOwnerViaMapping = market.getCurrentOwnerByMapping(hornId);
        
        address returnedBuyerOfHornId = market.buyers[hornId];
        address expectedBuyerOfHornIdShouldBe0 = address(0); // can address(0) be payable?

        string memory returnedShippingAddressesString = market.shippingAddresses[buyer];
        string memory expectedShippingAddressesStringShouldBeEmpty = "";

        
        uint escrowBalanceOfSeller = escrow.depositsOf(DeployedAddresses.Seller());
        //@notice ERC721 balanceOf() method actually returns a uint[] array, so in case of multiple NFTs the following line would need to be reworked to loop through the returned array
        uint tokenIdTransferredToBuyer = balanceOf(buyer); // need to import ierc721?

        // Check escrow.withdraw(horns[__hornId].currentOwner) was properly sent to the seller
        assert.equal(returnedPaymentAmt, hornListPrice, "Payment amount returned by markHornDeliveredAndOwnershipTransferred() does not match Horn NFT listPrice attribute");
        assert.isZero(escrowBalanceOfSeller, "Escrow contract was not properly drained of funds intended for seller"); //expects depositsOf() the payee aka seller to have been drained
        
        // Check that buyers[hornId] was set to address(0)
        assert.equal(returnedBuyerOfHornId, expectedBuyerOfHornIdShouldBe0, "Address returned by buyers[hornId] was not successfully zeroed out");
        // Check that shippingAddresses[msg.sender], here msg.sender is instead represented by buyer, was set to ""
        assert.equal(returnedShippingAddressString, expectedShippingAddressStringShouldBeEmpty, "String returned by shippingAddresses[buyer] was not successfully zeroed out");

        // Check that HornStatus status of hornNFT was correctly updated to OwnedNotForSale (== 3)
        assert.isTrue(testGetStatusOfHornById(hornId, HornStatus.OwnedNotForSale));
        // Check that currentOwner was correctly updated to buyer
        assert.equal(currentOwnerViaMapping, payable(DeployedAddresses.Buyer()), "CurrentOwner of Horn NFT as returned by storage mapping does not match expected address");
        // Check that currentOwner is consistent in both the mapping and the struct attribute
        assert.isTrue(testGetCurrentOwnerMappingAgainstStructAttributeByHornId(hornId));

        // Check that ERC721 method safeTransferFrom was executed properly
        assert.equal(tokenIdTransferredToBuyer, hornId, "BalanceOf buyer address doesn't reflect the hornId that should have been transferred, check execution of safeTransferFrom()");
    } // Javascript mirror test should expect HornDelivered event emission with correct seller, buyer addresses

    // @notice Modifier tests to ensure that access control and other modifier functions work properly
    // @dev Attempts to call transfer ownership function from non-buyer address without paying
    // @dev Ensures only buyer can markHornDeliveredAndOwnershipTransferred
    function testOnlyBuyerWhoPaid() public {
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();

        uint hornId = market._hornId.current();
        buyer.prepareForShipped(hornId); // {value:}
        seller.prepareForTransfer(hornId);

        bool thieveryAttempt = market.markHornDeliveredAndOwnershipTransferred(hornId); // {from: msg.sender} may need this line because this contract isn't an IERC721TokenReceiver to pass the market's safeTransferFrom() method
        
        assert.isFalse(thieveryAttempt, "An account that hasn't paid or been marked as buyer pilfered the NFT!");
    }
    // @dev Attempts to call listExistingHornNFT() from non-seller address who isn't currentOwner of the horn NFT
    function testOnlySellerViaList() public {
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();

        uint hornId = market._hornId.current();
        // @dev Impersonator tries to sell someone else's NFT for 1 ether
        // @notice Following function is called by an account that isn't the same one who minted
        bool sellerImpersonation = market.listExistingHornNFT(hornId, 1000000000000000000); // {from: accounts[1]}

        assert.isFalse(sellerImpersonation, "A rogue account was able to sell a horn NFT that it didn't own");
    }
    // @dev Attempts to call markHornShipped() from non-seller address who isn't currentOwner of the horn NFT
    function testOnlySellerViaMarkShipped() public {
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();

        uint hornId = market._hornId.current();
        string memory testShipTo = buyer.prepareForShipped(hornId); // {value:}

        bool shipperImpersonation = market.markHornShipped(hornId, testShipTo);

        assert.isFalse(shipperImpersonation, "A pirate just impersonated a shipper and shipped a horn they don't own");
    }
    // @dev Attempts to call purchaseHornById without having paid enough ETH in msg.value
    function testPaidEnough() public {
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();

        uint hornId = market._hornId.current();
        bool paidTooMuch = market.purchaseHornByHornId{ value: 5000000000000000005 }
            (    //{from:buyer} address(this) ??
            hornId, 
            "420 69th St. Phallus, Virgin Islands 42069"
            ); 

        assert.isFalse(paidTooMuch, "A generous soul got ripped off and was able to purchase a horn with msg.value that didn't match listPrice");
    }
    // @dev Attempts to call purchaseHornById on a horn that is not currently listed for sale
    function testForSale() public {
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();
        // market.mintButDontListNewHornNFT( // ONLY IF INITIATEREFUND FUNCTION HAVING ISSUES
        //     "Berg",
        //     "Double",
        //     "Geyer",
        //     serialNumberCounter,
        //     420000000000000000
        // );

        uint hornId = market._hornId.current(); 
        // Set minted NFT to OwnedNotForSale status
        market.initiateRefundOrSetStatusToOwnedNotForSale(hornId);

        bool yourMoneyNotWelcomeHere = market.purchaseHornByHornId{ value: 420000000000000000 }
            (
            hornId,
            "420 69th St. Phallus, Virgin Islands 42069"
            );

        assert.isFalse(yourMoneyNotWelcomeHere, "A sneaky user found a way to buy without being given consent");
    }
    
    // @dev Attempts to call markHornShipped when horn is not yet paid for in escrow
    function testHornPaidFor() public {
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();

        uint hornId = market._hornId.current();
        bool stillWaitingOnFunds = market.markHornShipped(hornId, "No moneys in Escrow yet lelz"); // {from: seller}

        assert.isFalse(stillWaitingOnFunds, "A silly seller somehow shipped a horn without receiving payment");
    }
    // @dev Attempts to call markHornDeliveredAndOwnershipTransferred when horn is not yet marked shipped by seller
    function testShipped() public {
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();

        uint hornId = market._hornId.current();
        buyer.prepareForShipped(hornId); // {value: listPrice}

        bool notShippedYet = market.markHornDeliveredAndOwnershipTransferred(hornId); // {from: buyer}

        assert.isFalse(notShippedYet, "Horn can not be marked delivered and NFT ownership transferred since it has not yet been marked shipped");
    }
    // @dev Attempts to mint a duplicate Horn NFT, which should fail the nonDuplicateMint modifier
    function testNonDuplicateMint() public {
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();

        // @param serialNumberCounter causes a hash collision against 1 since it was reset in the re-instantiated Seller contract above and incremented by mintAndListFreshTestHorn
        bool copycatMint = market.mintThenListNewHornNFT( // {from: buyer} (NOT ACTUALLY A BUYER BUT WORKS AS DIFF ADDRESS)
            "Berg",
            "Double",
            "Geyer",
            1, 
            4200000000000000000
        );

        assert.isFalse(copycatMint, "A corrupt copycat was able to mint a Horn NFT with duplicate hash of make and serialNumber");
    }


    // @dev Tests internal enum HornStatus functions to ensure that a currentOwner may change their mind about whether to list an instrument for sale
    function testSellerInitiateRefundOrSetStatusToOwnedNotForSale() public {
       // set conditions to identify an NFT that is ListedForSale
       freshMarketplaceAndSellerBuyerInstance();
       seller.mintAndListFreshHorn();

       uint hornId = market._hornId.current();
       HornStatus returnedStatus = market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(hornId);
       HornStatus expectedStatus = HornStatus.OwnedNotForSale;

       assert.equal(returnedStatus, expectedStatus, "HornStatus returned by sellerInitiateRefundOrSetStatusToOwnedNotForSale() did not match HornStatus.OwnedNotForSale");
    }

    // @dev Tests internal function from every angle to ascertain that if and else if clauses in sellerInitiateRefundOrSetStatusToOwnedNotForSale are working as intended
    function testSellerInitiateRefundOrSetStatusToOwnedNotForSaleFromOwnedNotForSale() public {
        // set conditions to identify an NFT that is OwnedNotForSale
        freshMarketplaceAndSellerBuyerInstance();
        market.mintButDontListNewHornNFT(
            "Berg",
            "Double",
            "Geyer", 
            defaultSerialNumber, // serialNumberCounter is now inside of Seller contract and not accessible by this function, so a default was made
            defaultListPrice
        );

        uint hornId = market._hornId.current();
        bool revertedByElseIf = market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(hornId);

        assert.isFalse(revertedByElseIf, "Function call error; it should have reverted because Horn is already set to OwnedNotForSale");
    }

    // @notice This test MUST be updated when/if refund logic is implemented in the marketplace and escrow contracts
    function testSellerInitiateRefundOrSetStatusToOwnedNotForSaleFromPaidFor() public {
        // set conditions to identify an NFT that is PaidFor
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshHorn();

        uint hornId = market._hornId.current();
        buyer.prepareForShipped(hornId); // {value:}

        bool tooLateTakeTheMoney = market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(hornId);

        assert.isFalse(tooLateTakeTheMoney, "Seller broke the rules and manipulated HornStatus even after Horn NFT was purchased and paid for by a buyer. That should only be possible after refunds are enabled");
    }
    // @notice This test has seller attempt to initiate refund despite them already having shipped the instrument
    function testSellerInitiateRefundOrSetStatusToOwnedNotForSaleFromShipped() public {
        // set conditions to identify an NFT that is Shipped
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshHorn();

        uint hornId = market._hornId.current();
        buyer.prepareForShipped(hornId); // {value:}
        seller.prepareForTransfer(hornId);

        bool youAlreadyShippedItYouScammer = market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(hornId);

        assert.isFalse(youAlreadyShippedItYouScammer, "Evil scammer managed to set Horn NFT to OwnedNotForSale even after shipping the instrument");
    }

    /*
        Tests for getter functions
    */
    // @dev Tests the basic behavior of the hornsForSale[] uint[] array
    function testGetCurrentHornsForSale() public {
        // set conditions to have three NFTs for sale and one not for sale
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshHorn(); // Id should == 1
        seller.mintAndListFreshHorn(); // Id should == 2
        market.mintButDontListNewHornNFT( // Id should == 3
            "Berg",
            "Double",
            "Geyer", 
            defaultSerialNumber,
            defaultListPrice
        );
        seller.mintAndListFreshHorn(); // Id should == 4
        
        uint[] returnedIds = market.getCurrentHornsForSale();
        uint[] expectedIds = [1, 2, 4];

        assert.equal(returnedIds, expectedIds, "hornsForSale[] uint[] array does not return expected hornIds of the lovely mints being tested");
    }
    // @dev Tests the more complicated behavior of the hornsForSale[] uint[] array by calling purchaseHornByHornId which deletes hornIds when they are purchased
    function testGetCurrentHornsForSaleAfterDeletionViaPurchaseHornByHornId() public {
        // set conditions to have three NFTs for sale and one not for sale, then purchases 2 and 4, removing them from hornsForSale[] array
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshHorn(); // Id should == 1
        seller.mintAndListFreshHorn(); // Id should == 2
        uint firstTestHornId = market._hornId.current(); // should == 2
        market.mintButDontListNewHornNFT( // Id should == 3
            "Berg",
            "Double",
            "Geyer", 
            defaultSerialNumber,
            defaultListPrice
        );
        // @dev Purchases the listed firstTestHornId and thereby 'deletes' it from the hornsForSale[] uint[] array by resetting its value to 0
        buyer.prepareForShipped(firstTestHornId); // {value: listPrice}
        seller.mintAndListFreshHorn(); // Id should == 4
        uint secondTestHornId = market._hornId.current(); // should == 4
        buyer.prepareForShipped(secondTestHornId); // {value: listPrice}
        // @dev Purchases the listed secondTestHornId and thereby 'deletes' it from the hornsForSale[] uint[] array by resetting its value to 0
        
        uint[] returnedIds = market.getCurrentHornsForSale();
        uint[] expectedIds = [1, 0, 0]; // originally [1, 2, 4] but 2 and 4 get zeroed out by purchases

        assert.equal(returnedIds, expectedIds, "hornsForSale[] uint[] array does not return expected hornId values after minting/listing/purchasing a selection of juicy NFTs");
    }

    // @dev Test price getter function of listPrice attribute inside horn struct of given HornId
    // @notice This function is used as a helper at different stages of the transaction to track intended behavior
    function testGetListPriceByHornId(uint __hornId) public returns (bool) {
        require(market.horns[__hornId].listPrice > 0, "Horn NFT listPrice appears to be 0, check mint execution");
        uint expectedPrice = market.horns[__hornId].listPrice;
        uint returnedPrice = market.getListPriceByHornId(__hornId);

        require(expectedPrice == returnedPrice, "Expected listPrice attribute of horn NFT struct does not match the one given by marketplace getter function");
        return true;
    }

    // @dev Test current owner getter function by getting returned address of given hornId
    // @notice This function is used as a helper at different stages of the transaction to track intended behavior
    function testGetCurrentOwnerMappingAgainstStructAttributeByHornId(uint __hornId) public returns (bool) {
        address payable mappingOwner = market.getCurrentOwnerByMapping(__hornId);
        address payable structOwner = market.getCurrentOwnerByStructAttribute(__hornId);
        
        require(mappingOwner == structOwner, "currentOwner of horn NFT via mapping does not match that of currentOwner via struct attribute");
        return true;
    }

    // @dev Test current enum status getter function via given hornId
    // @notice This function is used as a helper at different stages of the transaction to track intended behavior
    function testGetStatusOfHornById(uint __hornId, HornStatus _expectedStatus) public returns (bool) {
        // convert given expected HornStatus enum to a uint for comparison to market's function returnedEnum
        uint expectedEnum;

        if (uint(expectedStatus) == 0) {
            expectedEnum = 0; 
        } else if (uint(expectedStatus) == 1) {
            expectedEnum = 1;
        } else if (uint(expectedStatus) == 2) {
            expectedEnum = 2;
        } else if (uint(expectedStatus) == 3) {
            expectedEnum = 3;
        }
        uint returnedEnum = uint(market.getStatusOfHornByHornId(__hornId));

        require(returnedEnum == expectedEnum, "HornStatus enum uint returned by marketplace contract does not match the expected one given");
        return true;
    } 
    // @dev Test the current balance of deposits for given address in escrow contract 
    function testGetEscrowDepositValue(address payee) public {
        uint returnedDepositValue = market.getEscrowDepositValue(payee);
        uint correctDepositValue = market.escrow.depositsOf(payee);
        // if this doesnt work as a nested test, just use a require() statement so this function returns (bool) which is easy to work with in the larger host functions
        assert.equal(returnedDepositValue, correctDepositValue, "Value returned by getEscrowDepositValue does not match escrow depositsOf method");
    }

    // @dev Test the behavior of marketplace contract on receipt of only ETH without data
    // @dev Should revert on receipt of ETH without msg.data via fallback() function
    function testIncomingEther() public payable {
        bool dryEthSend = market.call{ value: 10000000000000000 }();

        assert.isFalse(dryEthSend, "Warning: a suspiciously generous soul donated funds to the marketplace contract without msg.data");
    }

    /*
    *   Helper Functions 
    */
    //  To be used inside main tests for faster and simpler behavior tracking

    // @dev Instantiates a fresh instance of the Horn Marketplace contract for cleaner testing
    // @notice Intended to be used prior to nearly every test, except ones that rely on having existing NFTs or hornIds
    function freshMarketplaceAndSellerBuyerInstance() public {
        market = new HornMarketplace();
        seller = new Seller();
        buyer = new Buyer();
    }
}



// MAKE SURE THAT SERIALNUMBERCOUNTER AND HORNIDS ARE PROPERLY PRESERVED AND PASSED BETWEEN CONTRACTS
contract Seller {

    // @dev This serialNumberCounter gives a new serialNumber to mint fresh Horn NFTs for every subsequent test without any hash collisions from make and serialNumber via the nonDuplicateMint modifier
    uint serialNumberCounter;

    constructor() {
        serialNumberCounter = 0;
    }
    // @dev Mints a fresh Horn NFT from the seller contract for testing purposes
    // @param serialNumberCounter is incremented every time this function is called so that the nonDuplicateMint modifier hashes make and serial data without collision
    function mintAndListFreshTestHorn() public returns (uint) {
        serialNumberCounter++;

        market.mintThenListNewHornNFT( // WILL THIS refer to the newly instantiated market?
            "Berg",
            "Double",
            "Geyer", 
            serialNumberCounter,
            4200000000000000000
        );
        uint currentHornId = market._hornId.current();

        return currentHornId;
    }

    // @dev Prepares a given Horn NFT for markHornDelivered and transfer testing
    function prepareForTransfer(uint hornId) public returns (string) {
        string memory testShipTo = "21 Mil St. BTCidatel, Metaverse 69696";
        
        market.markHornShipped(hornId, testShipTo);

        return testShipTo;
    }
}


contract Buyer {

    // @dev Prepares a given Horn NFT for markShipped testing
    // @param This function is payable and must be given a msg.value to carry out the market.purchaseHornByHornId line
    function prepareForShipped(uint hornId) public payable returns (string) {
        string memory testShipTo = "21 Mil St. BTCidatel, Metaverse 69696";

        market.purchaseHornByHornId(hornId, testShipTo); // {value:} ?

        return testShipTo;
    }

    function deliveredAndTransfer(uint hornId) public returns (uint) {
        uint paymentAmt = market.markHornDeliveredAndOwnershipTransferred(hornId);

        return paymentAmt
    }
}
