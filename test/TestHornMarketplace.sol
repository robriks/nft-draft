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
    // EscrowContract escrow = EscrowContract(DeployedAddresses.EscrowContract());
    
    uint32 defaultSerialNumber;
    uint32 defaultListPrice;

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
        
        Assert.equal(returnedOwnerOfHornMarketplaceContract, deployerOfHornMarketplaceContract, "Owner address given by Ownable library function does not match deployer of the Marketplace contract");
    }
    function testOwnerOfEscrow() public {
        freshMarketplaceAndSellerBuyerInstance();

        address /*payable*/ returnedOwnerOfEscrow = market.getEscrowOwner(); // uses openzeppelin Ownable.sol function call
        address /*payable*/ correctOwnerOfEscrow = DeployedAddresses.HornMarketplace();

        Assert.equal(returnedOwnerOfEscrow, correctOwnerOfEscrow, "Owner of instantiated escrow contract does not match HornMarketplace contract address");
    }
    // @dev Test minting an instrument for the first time
    // @param Be sure to give the correct __hornId index of Horn struct in horns[] mapping or test will fail; finicky but other variables are private and don't want to add attribute storage costs for a simple test
    function testMintThenListNewHornNFT() public {
        freshMarketplaceAndSellerBuyerInstance();
        // Mints a fresh Horn NFT with defaultListPrice, increments serialNumber, returns currentHornId
        uint returnedHornId = seller.mintAndListFreshTestHorn();
        uint expectedHornId = 1; // Expected currentHornId should be 1 after minting to a fresh contract instance
        uint returnedBalanceHornId = market.getBalanceOf(address(seller)); 
        uint32 returnedListPrice = market.getListPriceByHornId(returnedHornId);
        uint addedToForSaleArray = market.getHornForSaleByIndex(0);
        uint32 returnedSerialNumber = market.getHornById(returnedHornId).serialNumber;
        string memory returnedMake = market.getHornById(returnedHornId).make;
        string memory expectedMake = "Berg";
        string memory returnedModel = market.getHornById(returnedHornId).model;
        string memory expectedModel = "Double";
        string memory returnedStyle = market.getHornById(returnedHornId).style;
        string memory expectedStyle = "Geyer";
        // tokenURI variables here
        address payable returnedCurrentOwner = market.getHornById(returnedHornId).currentOwner;
        address payable expectedCurrentOwner = payable(address(seller));

        // Check that a fresh hornId was created
        Assert.equal(returnedHornId, expectedHornId, "returnedHornId given by mintAndListFreshTestHorn's Counter.Counter does not match the expectedHornId of 1 for a fresh contract instance's first mint");
        // Check that Horn NFT was _minted properly to the seller address
        Assert.equal(returnedBalanceHornId, expectedHornId, "Balance of sellerAddress as returned by ERC721 method does not match the expected Horn NFT tokenId of 1");
        // test _setTokenURI
        // Assert.tokenURI
        // Check that make was properly set
        Assert.equal(returnedMake, expectedMake, "Make error");
        // Check that model was properly set
        Assert.equal(returnedModel, expectedModel, "Model error");
        // Check that style was properly set
        Assert.equal(returnedStyle, expectedStyle, "Style error");
        // Check that serialNumber was properly set
        Assert.equal(returnedSerialNumber, defaultSerialNumber, "SerialNumber error");
        // Check status of the given index of struct mapping horns[__hornId]
        Assert.isTrue(testGetStatusOfHornById(returnedHornId, 0), "HornStatus enum returned does not match expected ListedForSale value");
        // Check that currentOwner of NFT was set to minter, in this case the seller address
        Assert.equal(returnedCurrentOwner, expectedCurrentOwner, "Horn NFT was minted to a different address than the seller address, check execution of mint and the currentOwner attribute");
        // Check currentOwner in mapping vs struct attribute
        Assert.isTrue(testGetCurrentOwnerMappingAgainstStructAttributeByHornId(returnedHornId), "Current Owner returned by mapping does not match the one returned by the Horn NFT attribute");
        // Check that listPrice was updated
        Assert.equal(returnedListPrice, defaultListPrice, "ListPrice error");
        // Check that hornsForSale[] uint[] array was updated to include returnedHornId
        Assert.equal(addedToForSaleArray, returnedHornId, "NFT hornId returned by hornsForSale[] uint[] array does not match the hornId that should have been pushed. Check index and execution of listExistingHornNFT()");
    }

    // @dev Test minting an instrument for the first time but NOT listing it for sale
    function testMintButDontListNewHornNFT() public {
        freshMarketplaceAndSellerBuyerInstance();
        // Mints but does not list a new Horn NFT from this contract and returns currentHornId
        uint returnedHornId = market.mintButDontListNewHornNFT(
            "Berg",
            "Double",
            "Geyer", 
            defaultSerialNumber
        );
        uint expectedHornId = 1; //Expected currentHornId should be 1 after minting to a fresh contract instance

        // tokenURI variables here

        string memory returnedMake = market.getHornById(returnedHornId).make;
        string memory expectedMake = "Berg";
        string memory returnedModel = market.getHornById(returnedHornId).model;
        string memory expectedModel = "Double";
        string memory returnedStyle = market.getHornById(returnedHornId).style;
        string memory expectedStyle = "Geyer";
        uint32 returnedSerialNumber = market.getHornById(returnedHornId).serialNumber;
        uint32 returnedListPrice = market.getListPriceByHornId(returnedHornId);
        address payable returnedCurrentOwner = market.getHornById(returnedHornId).currentOwner;
        address payable expectedCurrentOwner = payable(address(this));

        // Check that a fresh hornId was created
        Assert.equal(returnedHornId, expectedHornId, "returnedHornId given by market contract does not match expectedHornId of 1 for a fresh contract instance's first mint");
        // Check that tokenURI was properly set by _setTokenURI
        // Assert.tokenURI
        // Check that make was properly set
        Assert.equal(returnedMake, expectedMake, "Make error");
        // Check that model was properly set
        Assert.equal(returnedModel, expectedModel, "Model error");
        // Check that style was properly set
        Assert.equal(returnedStyle, expectedStyle, "Style error");
        // Check that serialNumber was properly set
        Assert.equal(returnedSerialNumber, defaultSerialNumber, "SerialNumber error");
        // Check that listPrice was properly set
        Assert.equal(returnedListPrice, defaultListPrice, "Listprice error");
        // Check that HornStatus was set to OwnedNotForSale
        Assert.isTrue(testGetStatusOfHornById(returnedHornId, 3), "HornStatus was not successfully set to OwnedNotForSale, be sure nothing is throwing beforehand");
        // Check that currentOwner was set to this contract's address(this)
        Assert.equal(returnedCurrentOwner, expectedCurrentOwner, "The test contract minted the Horn NFT and should be currentOwner but isn't, check execution of mintButDontListNewHornNFT(");
    }
    // @dev Test listing an existing Horn NFT
    function testListingExistingHornNFT() public {
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = market.mintButDontListNewHornNFT(
            "Berg",
            "Double",
            "Geyer", 
            defaultSerialNumber
        );

        //tokenURI variables here
        uint32 newListPrice = defaultListPrice + 1000;
        market.listExistingHornNFT(hornId, newListPrice);
        uint32 returnedListPrice = market.getListPriceByHornId(hornId);
        uint addedToForSaleArray = market.getHornForSaleByIndex(0);

        
        // Check that hornId was pushed into hornsForSale[] uint[] array
        Assert.equal(addedToForSaleArray, hornId, "NFT hornId returned by hornsForSale[] uint[] array does not match the hornId that should have been pushed. Check index and execution of listExistingHornNFT()");
        // Check that tokenURI was updated by _setTokenURI if new images were uploaded
        // Assert.tokenURI
        // Check that listPrice was updated
        Assert.equal(returnedListPrice, newListPrice, "List price of the new listing of an already existing NFT did not update properly, check execution of listExistingHornNFT()");
        // Check that HornStatus was updated to ListedForSale
        Assert.isTrue(testGetStatusOfHornById(hornId, 0), "HornStatus was not successfully changed to ListedForSale");
    }   // Javascript test for event emission


    // @dev Test buying an instrument with this contract
    // @param Since only one horn was minted the index within hornsForSale[] array that is deleted upon execution of purchase is 0. This setup would not work for testing multiple mints
    function testHornPurchase() public payable {
        // Set conditions to prepare for purchaseHornByHornId()
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = seller.mintAndListFreshTestHorn();

        string memory testAddress = "Ju St. Testing, Purchase Attempt New York, 11111";
        // This line uses this contract to buy, to provide some variety in testing
        market.purchaseHornByHornId(hornId, testAddress); // {value:}

        // @param Seller contract referenced because depositsOf refers to the payee, in this case the seller
        uint returnedDeposits = market.escrow.depositsOf(address(seller));
        uint32 hornListPrice = market.getListPriceByHornId(hornId);
        string memory returnedShippingAddress = market.shippingAddresses[address(this)];
        address returnedBuyerAddress = market.buyers[hornId];
        uint shouldHaveBeenDeleted = market.hornsForSale[0];

        // Check that escrow deposit was executed properly
        Assert.equal(returnedDeposits, hornListPrice, "Amount of deposited funds to escrow contract does not match the listPrice attribute of the horn NFT, check escrow deposit execution");
        // Check that shippingAddresses mapping was updated with 2nd parameter
        Assert.equal(returnedShippingAddress, testAddress, "Shipping address returned by shippingAddresses[] mapping does not match the test address provided to purchaseHornByHornId function");
        // Check that buyers mapping was updated to msg.sender, in this case address(this)
        Assert.equal(returnedBuyerAddress, address(this), "Address returned by market buyers[] mapping does not match the one that purchased the instrument, in this case this contract");
        // Check that status was updated to PaidFor
        Assert.isTrue(testGetStatusOfHornById(hornId, 1), "HornStatus was not successfully updated to PaidFor, check execution of purchaseHornByHornId()");
        // Check that hornId was deleted from hornsForSale[] uint[] array
        Assert.isZero(shouldHaveBeenDeleted, "Value returned by hornsForSale[] uint[] array was not 0, meaning it was not properly deleted upon execution of purchase");
        // javascript tests for event emission
    }

    // @dev Ensure only Sellers can mark horn shipped
    function testMarkHornShipped() public {
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = seller.mintAndListFreshTestHorn();

        buyer.prepareForShipped(hornId); // {value: }
        seller.prepareForTransfer(hornId);
        
        // Check that approval for __hornId given to marketplace contract was carried out
        address returnedApprovedAddressForHornId = market.getApprovedToSpend(hornId);
        address expectedApprovedAddressForHornId = DeployedAddresses.Buyer();
        
        Assert.Equal(returnedApprovedAddressForHornId, expectedApprovedAddressForHornId, "Returned approved address for tokenId doesn't match expected address, check execution of Approve()");

        // Use helper function to check that status was updated to Shipped
        Assert.isTrue(testGetStatusOfHornById(hornId, 2), "HornStatus was not successfully updated to Shipped, check execution of markHornShipped()");
    } // javascript version should expect hornShipped event emission with correct address

    // @dev Attempts to mark shipped with a wrong address
    function testMarkHornShippedWithWrongAddress() public {
        // First sets conditions of exchange up to point where markHornShipped would be called
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = seller.mintAndListFreshTestHorn();

        // Set correct address to prepare for comparison with the mistake address later entered by seller
        string memory realShipTo = buyer.prepareForShipped(hornId); // {value: }

        // Feed in a wrong address to ensure require() line prevents seller from shipping to the wrong place
        string memory mistakeShipTo = "21 Million Silk Rd. Darknet, Metaverse 66666";
        bool mistakenShippingAddress = market.markHornShipped(hornId, mistakeShipTo);

        // Use helper function to check that status is still PaidFor and didn't execute change to Shipped
        Assert.isTrue(testGetStatusOfHornById(hornId, 1), "HornStatus was somehow changed, check execution of markHornShipped");
        // Ascertain mistakenShippingAddress is falsy and didn't execute markHornShipped
        Assert.isFalse(mistakenShippingAddress, "A seller somehow managed to ship a horn to the wrong address");
    }

    // @dev Ensure markHornDeliveredAndOwnershipTransferred is working as intended
    function testMarkHornDeliveredAndOwnershipTransferred() public {
        // Set conditions of exchange up to the point where markHornDeliveredAndOwnershipTransferred would be called
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = seller.mintAndListFreshTestHorn();

        buyer.prepareForShipped(hornId); // {value: listPrice} 

        uint returnedPaymentAmt = buyer.deliveredAndTransfer(hornId);
        uint32 hornListPrice = market.getListPriceByHornId(hornId);


        address payable currentOwnerViaMapping = market.getCurrentOwnerByMapping(hornId);
        
        address returnedBuyerOfHornId = market.buyers[hornId];
        address expectedBuyerOfHornIdShouldBe0 = address(0); // can address(0) be payable?

        string memory returnedShippingAddressesString = market.shippingAddresses[buyer];
        string memory expectedShippingAddressesStringShouldBeEmpty = "";

        
        uint escrowBalanceOfSeller = market.escrow.depositsOf(DeployedAddresses.Seller());
        //@notice ERC721 balanceOf() method actually returns a uint[] array, so in case of multiple NFTs the following line would need to be reworked to loop through the returned array
        uint tokenIdTransferredToBuyer = market.getBalanceOf(buyer);

        // Check escrow.withdraw(horns[__hornId].currentOwner) was properly sent to the seller
        Assert.equal(returnedPaymentAmt, hornListPrice, "Payment amount returned by markHornDeliveredAndOwnershipTransferred() does not match Horn NFT listPrice attribute");
        Assert.isZero(escrowBalanceOfSeller, "Escrow contract was not properly drained of funds intended for seller"); //expects depositsOf() the payee aka seller to have been drained
        
        // Check that buyers[hornId] was set to address(0)
        Assert.equal(returnedBuyerOfHornId, expectedBuyerOfHornIdShouldBe0, "Address returned by buyers[hornId] was not successfully zeroed out");
        // Check that shippingAddresses[msg.sender], here msg.sender is instead represented by buyer, was set to ""
        Assert.equal(returnedShippingAddressesString, expectedShippingAddressesStringShouldBeEmpty, "String returned by shippingAddresses[buyer] was not successfully zeroed out");

        // Check that HornStatus status of hornNFT was correctly updated to OwnedNotForSale (== 3)
        Assert.isTrue(testGetStatusOfHornById(hornId, 3));
        // Check that currentOwner was correctly updated to buyer
        Assert.equal(currentOwnerViaMapping, payable(DeployedAddresses.Buyer()), "CurrentOwner of Horn NFT as returned by storage mapping does not match expected address");
        // Check that currentOwner is consistent in both the mapping and the struct attribute
        Assert.isTrue(testGetCurrentOwnerMappingAgainstStructAttributeByHornId(hornId));

        // Check that ERC721 method safeTransferFrom was executed properly
        Assert.equal(tokenIdTransferredToBuyer, hornId, "BalanceOf buyer address doesn't reflect the hornId that should have been transferred, check execution of safeTransferFrom()");
    } // Javascript mirror test should expect HornDelivered event emission with correct seller, buyer addresses

    // @notice Modifier tests to ensure that access control and other modifier functions work properly
    // @dev Attempts to call transfer ownership function from non-buyer address without paying
    // @dev Ensures only buyer can markHornDeliveredAndOwnershipTransferred
    function testOnlyBuyerWhoPaid() public {
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = seller.mintAndListFreshTestHorn();

        buyer.prepareForShipped(hornId); // {value:}
        seller.prepareForTransfer(hornId);

        bool thieveryAttempt = market.markHornDeliveredAndOwnershipTransferred(hornId); // {from: msg.sender} may need this line because this contract isn't an IERC721TokenReceiver to pass the market's safeTransferFrom() method
        
        Assert.isFalse(thieveryAttempt, "An account that hasn't paid or been marked as buyer pilfered the NFT!");
    }
    // @dev Attempts to call listExistingHornNFT() from non-seller address who isn't currentOwner of the horn NFT
    function testOnlySellerViaList() public {
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = seller.mintAndListFreshTestHorn();

        // @dev Impersonator tries to sell someone else's NFT for 1 ether
        // @notice Following function is called by an account that isn't the same one who minted
        bool sellerImpersonation = market.listExistingHornNFT(hornId, 1000000000000000000); // {from: accounts[1]}

        Assert.isFalse(sellerImpersonation, "A rogue account was able to sell a horn NFT that it didn't own");
    }
    // @dev Attempts to call markHornShipped() from non-seller address who isn't currentOwner of the horn NFT
    function testOnlySellerViaMarkShipped() public {
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = seller.mintAndListFreshTestHorn();

        string memory testShipTo = buyer.prepareForShipped(hornId); // {value:}

        bool shipperImpersonation = market.markHornShipped(hornId, testShipTo);

        Assert.isFalse(shipperImpersonation, "A pirate just impersonated a shipper and shipped a horn they don't own");
    }
    // @dev Attempts to call purchaseHornById without having paid enough ETH in msg.value
    function testPaidEnough() public {
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = seller.mintAndListFreshTestHorn();

        bool paidTooMuch = market.purchaseHornByHornId{ value: 5000000000000000005 }
            (    //{from:buyer} address(this) ??
            hornId, 
            "420 69th St. Phallus, Virgin Islands 42069"
            ); 

        Assert.isFalse(paidTooMuch, "A generous soul got ripped off and was able to purchase a horn with msg.value that didn't match listPrice");
    }
    // @dev Attempts to call purchaseHornById on a horn that is not currently listed for sale
    function testForSale() public {
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = seller.mintAndListFreshTestHorn();

        // Set minted NFT to OwnedNotForSale status
        market.initiateRefundOrSetStatusToOwnedNotForSale(hornId);

        bool yourMoneyNotWelcomeHere = market.purchaseHornByHornId{ value: 420000000000000000 }
            (
            hornId,
            "420 69th St. Phallus, Virgin Islands 42069"
            );

        Assert.isFalse(yourMoneyNotWelcomeHere, "A sneaky user found a way to buy without being given consent");
    }
    
    // @dev Attempts to call markHornShipped when horn is not yet paid for in escrow
    function testHornPaidFor() public {
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = seller.mintAndListFreshTestHorn();

        bool stillWaitingOnFunds = market.markHornShipped(hornId, "No moneys in Escrow yet lelz"); // {from: seller}

        Assert.isFalse(stillWaitingOnFunds, "A silly seller somehow shipped a horn without receiving payment");
    }
    // @dev Attempts to call markHornDeliveredAndOwnershipTransferred when horn is not yet marked shipped by seller
    function testShipped() public {
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = seller.mintAndListFreshTestHorn();

        buyer.prepareForShipped(hornId); // {value: listPrice}

        bool notShippedYet = market.markHornDeliveredAndOwnershipTransferred(hornId); // {from: buyer}

        Assert.isFalse(notShippedYet, "Horn can not be marked delivered and NFT ownership transferred since it has not yet been marked shipped");
    }
    // @dev Attempts to mint a duplicate Horn NFT, which should fail the nonDuplicateMint modifier
    function testNonDuplicateMint() public {
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshTestHorn();

        // @param serialNumberCounter causes a hash collision against 1 since it was reset in the re-instantiated Seller contract above and incremented by mintAndListFreshTestHorn
        bool copycatMint = market.mintThenListNewHornNFT( // minting from address(this), not the seller contract as above
            "Berg",
            "Double",
            "Geyer",
            1, 
            defaultListPrice
        );

        Assert.isFalse(copycatMint, "A corrupt copycat was able to mint a Horn NFT with duplicate hash of make and serialNumber");
    }


    // @dev Tests internal enum HornStatus functions to ensure that a currentOwner may change their mind about whether to list an instrument for sale
    function testSellerInitiateRefundOrSetStatusToOwnedNotForSale() public {
       // set conditions to identify an NFT that is ListedForSale
       freshMarketplaceAndSellerBuyerInstance();
       uint hornId = seller.mintAndListFreshHorn();

       uint returnedStatus = uint(market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(hornId));
       uint expectedStatus = 3;

       Assert.equal(returnedStatus, expectedStatus, "HornStatus returned by sellerInitiateRefundOrSetStatusToOwnedNotForSale() did not match HornStatus.OwnedNotForSale");
    }

    // @dev Tests internal function from every angle to ascertain that if and else if clauses in sellerInitiateRefundOrSetStatusToOwnedNotForSale are working as intended
    function testSellerInitiateRefundOrSetStatusToOwnedNotForSaleFromOwnedNotForSale() public {
        // set conditions to identify an NFT that is OwnedNotForSale
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = market.mintButDontListNewHornNFT(
            "Berg",
            "Double",
            "Geyer", 
            defaultSerialNumber, // serialNumberCounter is inside of Seller contract and not accessible by this function, so a default was made
            defaultListPrice
        );

        bool revertedByElseIf = market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(hornId);

        Assert.isFalse(revertedByElseIf, "Function call error; it should have reverted because Horn is already set to OwnedNotForSale");
    }

    // @notice This test MUST be updated when/if refund logic is implemented in the marketplace and escrow contracts
    function testSellerInitiateRefundOrSetStatusToOwnedNotForSaleFromPaidFor() public {
        // set conditions to identify an NFT that is PaidFor
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = seller.mintAndListFreshHorn();

        buyer.prepareForShipped(hornId); // {value:}

        bool tooLateTakeTheMoney = market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(hornId);

        Assert.isFalse(tooLateTakeTheMoney, "Seller broke the rules and manipulated HornStatus even after Horn NFT was purchased and paid for by a buyer. That should only be possible after refunds are enabled");
    }
    // @notice This test has seller attempt to initiate refund despite them already having shipped the instrument
    function testSellerInitiateRefundOrSetStatusToOwnedNotForSaleFromShipped() public {
        // set conditions to identify an NFT that is Shipped
        freshMarketplaceAndSellerBuyerInstance();
        uint hornId = seller.mintAndListFreshHorn();

        buyer.prepareForShipped(hornId); // {value:}
        seller.prepareForTransfer(hornId);

        bool youAlreadyShippedItYouScammer = market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(hornId);

        Assert.isFalse(youAlreadyShippedItYouScammer, "Evil scammer managed to set Horn NFT to OwnedNotForSale even after shipping the instrument");
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
        
        uint[] memory returnedIds = market.getCurrentHornsForSale();
        uint[] memory expectedIds = [1, 2, 4];

        Assert.equal(returnedIds, expectedIds, "hornsForSale[] uint[] array does not return expected hornIds of the lovely mints being tested");
    }
    // @dev Tests the more complicated behavior of the hornsForSale[] uint[] array by calling purchaseHornByHornId which deletes hornIds when they are purchased
    function testGetCurrentHornsForSaleAfterDeletionViaPurchaseHornByHornId() public {
        // set conditions to have three NFTs for sale and one not for sale, then purchases 2 and 4, removing them from hornsForSale[] array
        freshMarketplaceAndSellerBuyerInstance();
        seller.mintAndListFreshHorn(); // Id should == 1
        uint firstTestHornId = seller.mintAndListFreshHorn(); // Id should == 2
        market.mintButDontListNewHornNFT( // Id should == 3
            "Berg",
            "Double",
            "Geyer", 
            defaultSerialNumber,
            defaultListPrice
        );
        // @dev Purchases the listed firstTestHornId and thereby 'deletes' it from the hornsForSale[] uint[] array by resetting its value to 0
        buyer.prepareForShipped(firstTestHornId); // {value: listPrice}
        uint secondTestHornId = seller.mintAndListFreshHorn(); // Id should == 4
        buyer.prepareForShipped(secondTestHornId); // {value: listPrice}
        // @dev Purchases the listed secondTestHornId and thereby 'deletes' it from the hornsForSale[] uint[] array by resetting its value to 0
        
        uint[] memory returnedIds = market.getCurrentHornsForSale();
        uint[] memory expectedIds = [1, 0, 0]; // originally [1, 2, 4] but 2 and 4 get zeroed out by purchases

        Assert.equal(returnedIds, expectedIds, "hornsForSale[] uint[] array does not return expected hornId values after minting/listing/purchasing a selection of juicy NFTs");
    }

    // @dev Test price getter function of listPrice attribute inside horn struct of given HornId
    // @notice This function is used as a helper at different stages of the transaction to track intended behavior
    function testGetListPriceByHornId(uint __hornId) public returns (bool) {
        require(market.getHornById(__hornId).listPrice > 0, "Horn NFT listPrice appears to be 0, check mint execution");
        uint32 expectedPrice = market.getHornById(__hornId).listPrice;
        uint32 returnedPrice = market.getListPriceByHornId(__hornId);

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
    function testGetStatusOfHornById(uint __hornId, uint _expectedHornStatus) public returns (bool) {
        // convert given expected HornStatus enum to a uint for comparison to market's function returnedEnum
        uint expectedEnum = _expectedHornStatus; // 0 = ListedForSale, 1 = PaidFor, 2 = Shipped, 3 = OwnedNotForSale
        uint returnedEnum = uint(market.getStatusOfHornByHornId(__hornId));

        require(returnedEnum == expectedEnum, "HornStatus enum uint returned by marketplace contract does not match the expected one given");
        return true;
    } 
    // @dev Test the current balance of deposits for given address in escrow contract against market getter function
    function testGetEscrowDepositValue(address payee) public {
        uint returnedDepositValue = market.getEscrowDepositValue(payee);
        uint correctDepositValue = market.escrow.depositsOf(payee);

        Assert.equal(returnedDepositValue, correctDepositValue, "Value returned by getEscrowDepositValue does not match escrow depositsOf method");
    }

    // @dev Test the behavior of marketplace contract on receipt of only ETH without data
    // @dev Should revert on receipt of ETH without msg.data via fallback() function
    function testIncomingEther() public payable {
        bool dryEthSend = market.call{ value: 10000000000000000 }();

        Assert.isFalse(dryEthSend, "Warning: a suspiciously generous soul donated funds to the marketplace contract without msg.data");
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



contract Seller {

    // @dev This serialNumberCounter gives a new serialNumber to mint fresh Horn NFTs for every subsequent test without any hash collisions from make and serialNumber via the nonDuplicateMint modifier
    uint serialNumberCounter;
    uint defaultListPrice;
    HornMarketplace market;

    constructor() {
        serialNumberCounter = 0;
        defaultListPrice = 420;
        market = DeployedAddresses.HornMarketplace(); // also can try msg.sender since marketplace contract instantiates this contract
    }
    // @dev Mints a fresh Horn NFT from the seller contract for testing purposes
    // @param serialNumberCounter is incremented every time this function is called so that the nonDuplicateMint modifier hashes make and serial data without collision
    function mintAndListFreshTestHorn() public returns (uint) {
        serialNumberCounter++;

        uint currentHornId = market.mintThenListNewHornNFT(
            "Berg",
            "Double",
            "Geyer", 
            serialNumberCounter,
            defaultListPrice
        );

        return currentHornId;
    }

    // @dev Prepares a given Horn NFT for markHornDelivered and transfer testing
    function prepareForTransfer(uint hornId) public returns (string memory) {
        string memory testShipTo = "21 Mil St. BTCidatel, Metaverse 69696";
        
        market.markHornShipped(hornId, testShipTo);

        return testShipTo;
    }
}


contract Buyer {
    
    HornMarketplace market;

    constructor() {
        market = DeployedAddresses.HornMarketplace();
    }
    // @dev Prepares a given Horn NFT for markShipped testing
    // @param This function is payable and must be given a msg.value to carry out the market.purchaseHornByHornId line
    function prepareForShipped(uint hornId) public payable returns (string memory) {
        string memory testShipTo = "21 Mil St. BTCidatel, Metaverse 69696";

        market.purchaseHornByHornId(hornId, testShipTo); // {value:} ?

        return testShipTo;
    }

    function deliveredAndTransfer(uint hornId) public returns (uint) {
        uint paymentAmt = market.markHornDeliveredAndOwnershipTransferred(hornId);

        return paymentAmt;
    }
}
