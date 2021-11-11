// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "remix_tests.sol"; // injected by remix-tests CLI
// import "truffle/Assert.sol"; // Assert.stuff conflict with remix-tests
import "truffle/DeployedAddresses.sol"; // necessary?
import "../contracts/HornMarketplace.sol";


contract HornMarketplace_test {
    // Declare targeted HornMarketplace, Seller, and Buyer contracts for instantiating and subsequent testing
    HornMarketplace market;
    address seller = TestsAccounts.getAccount(1);
    address buyer = TestAccounts.getAccount(2);
    
    // @param This serialNumberCounter gives a new serialNumber to mint fresh Horn NFTs for every subsequent test without any hash collisions from make and serialNumber via the nonDuplicateMint modifier
    uint serialNumberCounter;
    uint defaultListPrice;

    /*
        Constructor
    */
    constructor() payable { // Marked payable to prepare this contract with ETH funds on testnet for testing the marketplace contract    
        serialNumberCounter = 0;
        defaultListPrice = 420; // lelz
    }


    // @dev Instantiates a fresh instance of the Horn Marketplace contract for cleaner and simpler testing of contract behavior
    // @notice Intended to be used prior to nearly every test, except ones that rely on having existing NFTs or hornIds
    function beforeEach() public {
        market = new HornMarketplace();
    }

    /* 
    *  Main Function Tests
    */
    // @notice Testing for event emission is specifically NOT supported by solidity smart contracts so those tests must be done in javascript
    // @dev Sanity checks for horn owner of escrow and marketplace contracts
    function testOwnerOfHornMarketplaceContract() public {

        address returnedOwnerOfHornMarketplaceContract = market.owner(); // uses openzeppelin Ownable.sol function call
        address deployerOfHornMarketplaceContract = msg.sender;
        
        Assert.equal(returnedOwnerOfHornMarketplaceContract, deployerOfHornMarketplaceContract, "Owner address given by Ownable library function does not match deployer of the Marketplace contract");
    }
    function testOwnerOfEscrow() public {

        address returnedOwnerOfEscrow = market.getEscrowOwner();
        address correctOwnerOfEscrow = address(market); //DeployedAddresses.HornMarketplace()

        Assert.equal(returnedOwnerOfEscrow, correctOwnerOfEscrow, "Owner of instantiated escrow contract does not match HornMarketplace contract address");
    }
    // @dev Test minting an instrument for the first time
    // @param Be sure to give the correct __hornId index of Horn struct in horns[] mapping or test will fail; finicky but other variables are private and don't want to add attribute storage costs for a simple test
    function testMintThenListNewHornNFT() public {
        // Mints a fresh Horn NFT with defaultListPrice, increments serialNumber, returns currentHornId
        uint returnedHornId = mintAndListFreshTestHorn();
        uint expectedHornId = 1; // Expected currentHornId should be 1 after minting to a fresh contract instance
        uint returnedBalanceHornId = market.getBalanceOf(seller); 
        uint returnedListPrice = market.getListPriceByHornId(returnedHornId);
        uint addedToForSaleArray = market.hornsForSale(0);
        uint returnedSerialNumber = market.getHornById(returnedHornId).serialNumber;
        string memory returnedMake = market.getHornById(returnedHornId).make;
        string memory expectedMake = "Berg";
        string memory returnedModel = market.getHornById(returnedHornId).model;
        string memory expectedModel = "Double";
        string memory returnedStyle = market.getHornById(returnedHornId).style;
        string memory expectedStyle = "Geyer";
        // tokenURI variables here
        address payable returnedCurrentOwner = market.getHornById(returnedHornId).currentOwner;
        address payable expectedCurrentOwner = payable(seller);

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
        Assert.equal(returnedSerialNumber, serialNumberCounter, "SerialNumber error");

        // @dev Check status of the given index of struct mapping horns[__hornId]        
        try market.getStatusOfHornByHornId(hornId) returns (int8 s) { // may need to change getStatusOfHorn function to wrap enum in uint8
            Assert.equal(s, 0, "HornStatus enum returned does not match expected ListedForSale value");
        } catch (bytes memory /* lowLevelData */) {
            return (false);
        }

        // Check that currentOwner of NFT was set to minter, in this case the seller address
        Assert.equal(returnedCurrentOwner, expectedCurrentOwner, "Horn NFT was minted to a different address than the seller address, check execution of mint and the currentOwner attribute");
        
        try market.testGetCurrentOwnerMappingAgainstStructAttributeByHornId(returnedHornId) returns (bool o) {
            Assert.equal(o, true, "Current Owner returned by mapping does not match the one returned by the Horn NFT attribute");
        } catch (bytes memory /* lowLevelData */) {
            return (false);
        }

        // Check that listPrice was updated
        Assert.equal(returnedListPrice, defaultListPrice, "ListPrice error");
        // Check that hornsForSale[] uint[] array was updated to include returnedHornId
        Assert.equal(addedToForSaleArray, returnedHornId, "NFT hornId returned by hornsForSale[] uint[] array does not match the hornId that should have been pushed. Check index and execution of listExistingHornNFT()");
    }

    // @dev Test minting an instrument for the first time but NOT listing it for sale
    function testMintButDontListNewHornNFT() public {
        // Mints but does not list a new Horn NFT from this contract and returns currentHornId
        uint returnedHornId = market.mintButDontListNewHornNFT(
            "Berg",
            "Double",
            "Geyer", 
            serialNumberCounter
        );
        uint expectedHornId = 1; //Expected currentHornId should be 1 after minting to a fresh contract instance

        // tokenURI variables here

        string memory returnedMake = market.getHornById(returnedHornId).make;
        string memory expectedMake = "Berg";
        string memory returnedModel = market.getHornById(returnedHornId).model;
        string memory expectedModel = "Double";
        string memory returnedStyle = market.getHornById(returnedHornId).style;
        string memory expectedStyle = "Geyer";
        uint returnedSerialNumber = market.getHornById(returnedHornId).serialNumber;
        uint returnedListPrice = market.getListPriceByHornId(returnedHornId);
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
        Assert.equal(returnedSerialNumber, serialNumberCounter, "SerialNumber error");
        // Check that listPrice was properly set
        Assert.equal(returnedListPrice, defaultListPrice, "Listprice error");

        // @dev Check that HornStatus was set to OwnedNotForSale aka int8 == 3
        try market.getStatusOfHornByHornId(hornId) returns (int8 s) { // may need to change getStatusOfHorn function to wrap enum in uint8
            Assert.equal(s, 3, "HornStatus was not successfully set to OwnedNotForSale, be sure nothing is throwing beforehand");
        } catch (bytes memory /* lowLevelData */) {
            return (false);
        }

        // Check that currentOwner was set to this contract's address(this)
        Assert.equal(returnedCurrentOwner, expectedCurrentOwner, "The test contract minted the Horn NFT and should be currentOwner but isn't, check execution of mintButDontListNewHornNFT(");
    }
    // @dev Test listing an existing Horn NFT
    function testListingExistingHornNFT() public {
        uint hornId = market.mintButDontListNewHornNFT(
            "Berg",
            "Double",
            "Geyer", 
            serialNumberCounter
        );

        //tokenURI variables here
        uint newListPrice = defaultListPrice + 1000;
        market.listExistingHornNFT(hornId, newListPrice);
        uint returnedListPrice = market.getListPriceByHornId(hornId);
        uint addedToForSaleArray = market.hornsForSale(0);

        
        // Check that hornId was pushed into hornsForSale[] uint[] array
        Assert.equal(addedToForSaleArray, hornId, "NFT hornId returned by hornsForSale[] uint[] array does not match the hornId that should have been pushed. Check index and execution of listExistingHornNFT()");
        // Check that tokenURI was updated by _setTokenURI if new images were uploaded
        // Assert.tokenURI
        // Check that listPrice was updated
        Assert.equal(returnedListPrice, newListPrice, "List price of the new listing of an already existing NFT did not update properly, check execution of listExistingHornNFT()");
        
        // @dev Check that HornStatus was updated to ListedForSale
        try market.getStatusOfHornByHornId(hornId) returns (int8 s) { // may need to change getStatusOfHorn function to wrap enum in uint8
            Assert.equal(s, 0, "HornStatus was not successfully changed to ListedForSale");
        } catch (bytes memory /* lowLevelData */) {
            return (false);
        }
    }   // Javascript test for event emission


    // @dev Test buying an instrument with this contract
    // @param Since only one horn was minted the index within hornsForSale[] array that is deleted upon execution of purchase is 0. This setup would not work for testing multiple mints
    function testHornPurchase() public payable {
        // Set conditions to prepare for purchaseHornByHornId()
        uint hornId = mintAndListFreshTestHorn();

        string memory testAddress = "Ju St. Testing, Purchase Attempt New York, 11111";
        // This line uses this contract to buy, to test if contracts can purchase as well as EOA users
        market.purchaseHornByHornId(hornId, testAddress);

        // @param Seller address referenced because depositsOf refers to the payee, in this case the seller
        uint returnedDeposits = market.getEscrowDepositValue(seller);
        uint hornListPrice = market.getListPriceByHornId(hornId);
        string memory returnedShippingAddress = market.shippingAddresses(address(this));
        address returnedBuyerAddress = market.buyers(hornId);
        uint shouldHaveBeenDeleted = market.hornsForSale(0);

        // Check that escrow deposit was executed properly
        Assert.equal(returnedDeposits, hornListPrice, "Amount of deposited funds to escrow contract does not match the listPrice attribute of the horn NFT, check escrow deposit execution");
        // Check that shippingAddresses mapping was updated with 2nd parameter
        Assert.equal(returnedShippingAddress, testAddress, "Shipping address returned by shippingAddresses[] mapping does not match the test address provided to purchaseHornByHornId function");
        // Check that buyers mapping was updated to msg.sender, in this case address(this)
        Assert.equal(returnedBuyerAddress, address(this), "Address returned by market buyers[] mapping does not match the one that purchased the instrument, in this case this contract");
        
        // @dev Check that status was updated to PaidFor
        try market.getStatusOfHornByHornId(hornId) returns (int8 s) { // may need to change getStatusOfHorn function to wrap enum in uint8
            Assert.equal(s, 1, "HornStatus was not successfully updated to PaidFor, check execution of purchaseHornByHornId()");
        } catch (bytes memory /* lowLevelData */) {
            return (false);
        }
        
        // Check that hornId was deleted from hornsForSale[] uint[] array
        Assert.equal(shouldHaveBeenDeleted, 0, "Value returned by hornsForSale[] uint[] array was not 0, meaning it was not properly deleted upon execution of purchase");
        // javascript tests for event emission
    }

    // @dev Ensure only Sellers can mark horn shipped
    function testMarkHornShipped() public {
        uint hornId = mintAndListFreshTestHorn();

        prepareForShipped(hornId);
        prepareForTransfer(hornId);
        
        // Check that approval for __hornId given to marketplace contract was carried out
        address returnedApprovedAddressForHornId = market.getApprovedToSpend(hornId);
        address expectedApprovedAddressForHornId = market.buyers(hornId);
        
        Assert.equal(returnedApprovedAddressForHornId, expectedApprovedAddressForHornId, "Returned approved address for tokenId doesn't match expected address, check execution of Approve()");

        // Use helper function to check that status was updated to Shipped aka int8 = 2
        try market.getStatusOfHornByHornId(hornId) returns (int8 s) { // may need to change getStatusOfHorn function to wrap enum in uint8
            Assert.equal(s, 2, "HornStatus was not successfully updated to Shipped, check execution of markHornShipped()");
        } catch (bytes memory /* lowLevelData */) {
            return (false);
        }
    } // javascript version should expect hornShipped event emission with correct address

    // @dev Attempts to mark shipped with a wrong address
    function testMarkHornShippedWithWrongAddress() public {
        // First sets conditions of exchange up to point where markHornShipped would be called
        uint hornId = mintAndListFreshTestHorn();

        // Set correct address to prepare for comparison with the mistake address later entered by seller
        // string memory realShipTo = prepareForShipped(hornId); // DELETE WHEN THIS TEST FOR EXCEPTION WORKS

        // Feed in a wrong address to ensure require() line prevents seller from shipping to the wrong place
        string memory mistakeShipTo = "21 Million Silk Rd. Darknet, Metaverse 66666";
        try market.markHornShipped(_hornId, mistakeShipTo) {
            Assert.ok(false, "Against all odds, a seller somehow managed to ship a horn to the wrong address");
        } catch Error(string memory reason) {
            return (false);
        }

        // @param Use helper function to check that status is still PaidFor aka (int8 = 1) and therefore didn't execute change to Shipped
        try market.getStatusOfHornByHornId(hornId) returns (int8 s) { // may need to change getStatusOfHorn function to wrap enum in uint8
            Assert.equal(s, 1, "HornStatus was somehow changed, check execution of markHornShipped");
        } catch (bytes memory /* lowLevelData */) {
            return (false);
        }

        // Assert.isTrue(testGetStatusOfHornById(hornId, 1), "HornStatus was somehow altered, check execution of markHornShipped"); DELETE WHEN THIS TEST FOR EXCEPTION WORKS
        // Ascertain mistakenShippingAddress is falsy and didn't execute markHornShipped
        // Assert.isFalse(mistakenShippingAddress, "Against all odds, a seller somehow managed to ship a horn to the wrong address");
    }

    // DELETE NEXT 7 LINES WHEN EXCEPTION TEST ABOVE IS WORKING
    // // @dev Helper function that is intended to throw on execution due to shippingAddress mismatch
    // function wrongAddressThrows() public {
    //     uint _hornId = 1;
    //     // Feed in a wrong address to ensure require() line prevents seller from shipping to the wrong place
    //     string memory mistakeShipTo = "21 Million Silk Rd. Darknet, Metaverse 66666";
    //     market.markHornShipped(_hornId, mistakeShipTo);
    // }


    // @dev Ensure markHornDeliveredAndOwnershipTransferred is working as intended
    function testMarkHornDeliveredAndOwnershipTransferred() public {
        // Set conditions of exchange up to the point where markHornDeliveredAndOwnershipTransferred would be called
        uint hornId = mintAndListFreshTestHorn();

        prepareForShipped(hornId);

        uint returnedPaymentAmt = deliveredAndTransfer(hornId);
        uint hornListPrice = market.getListPriceByHornId(hornId);

        address payable currentOwnerViaMapping = market.getCurrentOwnerByMapping(hornId);
        
        address returnedBuyerOfHornId = market.buyers(hornId);
        address expectedBuyerOfHornIdShouldBe0 = address(0);

        string memory returnedShippingAddressesString = market.shippingAddresses(buyer);
        string memory expectedShippingAddressesStringShouldBeEmpty = "";
        
        uint escrowBalanceOfSeller = market.getEscrowDepositValue(seller);
        //@notice ERC721 balanceOf() method actually returns a uint[] array, so in case of multiple NFTs the following line would need to be reworked to loop through the returned array
        uint tokenIdTransferredToBuyer = market.getBalanceOf(buyer);

        // Check escrow.withdraw(horns[__hornId].currentOwner) was properly sent to the seller
        Assert.equal(returnedPaymentAmt, hornListPrice, "Payment amount returned by markHornDeliveredAndOwnershipTransferred() does not match Horn NFT listPrice attribute");
        // Checks that depositsOf() the payee aka seller to have been drained to 0
        Assert.equal(escrowBalanceOfSeller, 0, "Escrow contract was not properly drained of funds intended for seller");
        // Check that buyers[hornId] was set to address(0)
        Assert.equal(returnedBuyerOfHornId, expectedBuyerOfHornIdShouldBe0, "Address returned by buyers[hornId] was not successfully zeroed out");
        // Check that shippingAddresses[msg.sender], here msg.sender is instead represented by buyer, was set to ""
        Assert.equal(returnedShippingAddressesString, expectedShippingAddressesStringShouldBeEmpty, "String returned by shippingAddresses[buyer] was not successfully zeroed out");

        // @dev Check that HornStatus status of hornNFT was correctly updated to OwnedNotForSale (== 3)
        try market.getStatusOfHornByHornId(hornId) returns (int8 s) { // may need to change getStatusOfHorn function to wrap enum in uint8
            Assert.equal(s, 3, "HornStatus of Horn NFT was not correctly updated to OwnedNotForSale");
        } catch (bytes memory /* lowLevelData */) {
            return (false);
        }

        // Check that currentOwner was correctly updated to buyer
        Assert.equal(currentOwnerViaMapping, buyer, "CurrentOwner of Horn NFT as returned by storage mapping does not match expected address");
        
        // Check that currentOwner is consistent in both the mapping and the struct attribute
        try market.testGetCurrentOwnerMappingAgainstStructAttributeByHornId(hornId) returns (bool o) {
            Assert.equal(o, true, "Current Owner returned by mapping does not match the one returned by the Horn NFT attribute");
        } catch (bytes memory /* lowLevelData */) {
            return (false);
        }

        // Check that ERC721 method safeTransferFrom was executed properly
        Assert.equal(tokenIdTransferredToBuyer, hornId, "BalanceOf buyer address doesn't reflect the hornId that should have been transferred, check execution of safeTransferFrom()");
    } // Javascript mirror test should expect HornDelivered event emission with correct seller, buyer addresses

    // @notice Modifier tests to ensure that access control and other modifier functions work properly
    // @dev Attempts to call transfer ownership function from non-buyer address without paying
    // @dev Ensures only buyer can markHornDeliveredAndOwnershipTransferred
    function testOnlyBuyerWhoPaid() public {
        uint hornId = mintAndListFreshTestHorn();

        prepareForShipped(hornId);
        prepareForTransfer(hornId);

        try market.markHornDeliveredAndOwnershipTransferred(hornId) returns (uint256 amt) {
            Assert.ok(false, "An account that hasn't paid or been marked as buyer pilfered the NFT!");
        } catch (bytes memory /*lowLevelData*/) {
            return (false);
        }
    }
    // // @dev Helper function that is intended to throw on execution due to this contract not being a buyer who already paid
    // function noPayNoWay() public {
    //     market.markHornDeliveredAndOwnershipTransferred(1);
    // }  DELETE WHEN TEST PASSES

    // @dev Attempts to call listExistingHornNFT() from non-seller address who isn't currentOwner of the horn NFT
    function testOnlySellerViaList() public {
        uint hornId = mintButDontListFreshTestHorn();

        // @dev Impersonator tries to sell someone else's NFT
        // @notice Following function is called by an account that isn't the same one who minted

        try market.listExistingHornNFT(hornId, defaultListPrice) returns (uint h) {
            Assert.ok(false, "A rogue account was able to sell a horn NFT that it didn't own");
        } catch (bytes memory /* lowLevelData */) {
            return (false);
        }
    }
    // // @dev Helper function intended to throw on execution via this contract not being the owner of the token
    // function noGoodsNoGo() public {
    //     market.listExistingHornNFT(1, defaultListPrice);
    // } DELETE WHEN TEST PASSES

    // @dev Attempts to call markHornShipped() from non-seller address who isn't currentOwner of the horn NFT
    function testOnlySellerViaMarkShipped() public {
        uint hornId = mintAndListFreshTestHorn();
        prepareForShipped(hornId);
        string memory testShipTo = "TrumpTower";

        try market.markHornShipped(hornId, testShipTo) {
            Assert.ok(false, "A pirate just impersonated a shipper and shipped a horn they don't own");
        } catch (bytes memory /* lowLevelData */) {
            return (false);
        }
    }
    // // @dev Helper function intended to throw on execution via this contract not being the seller who can ship
    // function noShippingForYou() public {
    //     market.markHornShipped(1, "TrumpTower");
    // } DELETE WHEN TEST PASSES

    // @dev Attempts to call purchaseHornById without having paid enough ETH in msg.value
    /// #value: 42489
    function testPaidEnough() public payable {
        uint hornId = mintAndListFreshTestHorn();
        uint tooMuch = defaultListPrice + 42069; //lol

        // Function intended to throw on execution via msg.value being more than the listPrice
        try market.purchaseHornByHornId{ value: tooMuch }( // 42489wei provided in msg.value
            hornId, 
            "420 69th St. Phallus, Virgin Islands 42069") {
                Assert.ok(false, "A generous soul got ripped off and was able to purchase a horn with msg.value that didn't match listPrice");
            } catch (bytes memory /*lowLevelData*/) {
                return (false);
            }
    }

    // @dev Attempts to call purchaseHornById on a horn that is not currently listed for sale
    function testForSale() public {
        uint hornId = mintAndListFreshTestHorn();

        // Set minted NFT to OwnedNotForSale status
        market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(hornId);
        
        // Function intended to throw on execution via Horn not being ListedForSale
        try prepareForShipped(hornId) returns (string memory s) {
            Assert.ok(false, "A sneaky user found a way to buy without being given consent");
        } catch (bytes memory /*lowLevelData*/) {
            return (false);
        }
    }

    // function cannotBeBought() public {
    //     market.purchaseHornByHornId{ value: defaultListPrice }
    //         (
    //         1,
    //         "420 69th St. Phallus, Virgin Islands 42069"
    //         );
    // } DELETE WHEN TEST PASSES
    
    // @dev Attempts to call markHornShipped when horn is not yet paid for in escrow
    function testHornPaidFor() public {
        uint hornId = mintAndListFreshTestHorn();

        // Function intended to throw on execution because Escrow has not received funds yet
        try prepareForTransfer(hornId) returns (string memory st) {
            Assert.ok(false, "A silly seller somehow shipped a horn without receiving payment");
        } catch (bytes memory /*lowLevelData*/) {
            return (false);
        }
    }
    // function wheresTheMoney() public {
    //     market.markHornShipped(1, "No moneys in Escrow yet lelz");
    // } DELETE WHEN TEST PASSES

    // @dev Attempts to call markHornDeliveredAndOwnershipTransferred when horn is not yet marked shipped by seller
    function testShipped() public {
        uint hornId = mintAndListFreshTestHorn();

        prepareForShipped(hornId);

        // Function intended to throw on execution because Horn has not been shipped yet
        try deliveredAndTransfer(hornId) returns (uint256 a) {
            Assert.ok(false, "Horn can not be marked delivered and NFT ownership transferred since it has not yet been marked shipped");
        } catch (bytes memory /*lowLevelData*/) {
            return (false);
        }
    }

    // @dev Attempts to mint a duplicate Horn NFT, which should fail the nonDuplicateMint modifier
    // @param 1 causes a hash collision against serialNumberCounter since it was reset in the re-instantiated Marketplace contract by beforeEach() and then incremented once by mintAndListFreshTestHorn
    function testNonDuplicateMint() public {
        mintAndListFreshTestHorn(); // serialNumberCounter should == 1 here

        // Function intended to throw on execution because the provided serialNumber and make cause a collision
        try market.mintThenListNewHornNFT(
          "Berg",
          "Double",
          "Geyer",
          1, 
          defaultListPrice) 
          returns (uint hn) {
            Assert.ok(false, "A corrupt copycat was able to mint a Horn NFT with duplicate hash of make and serialNumber");
          } catch (bytes memory /*lowLevelData*/) {
            return (false);
        }
    }

    // @dev Tests internal enum HornStatus functions to ensure that a currentOwner may change their mind about whether to list an instrument for sale
    function testSellerInitiateRefundOrSetStatusToOwnedNotForSale() public {
       // set conditions to identify an NFT that is ListedForSale
       uint hornId = mintAndListFreshTestHorn();

       uint returnedStatus = uint(market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(hornId));
       uint expectedStatus = 3;

       Assert.equal(returnedStatus, expectedStatus, "HornStatus returned by sellerInitiateRefundOrSetStatusToOwnedNotForSale() did not match HornStatus.OwnedNotForSale");
    }

    // @dev Tests internal function from every angle to ascertain that if and else if clauses in sellerInitiateRefundOrSetStatusToOwnedNotForSale are working as intended
    function testSellerInitiateRefundOrSetStatusToOwnedNotForSaleFromOwnedNotForSale() public {
        // Set conditions to identify an NFT that is OwnedNotForSale
        uint hornId = market.mintButDontListNewHornNFT(
            "Berg",
            "Double",
            "Geyer", 
            serialNumberCounter
        );

        // Function intended to throw on execution because Horn is already ListedForSale
        try market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(hornId) returns (uint ho) {
            Assert.ok(false, "Function call error; it should have reverted because Horn is already set to OwnedNotForSale");
        } catch (bytes memory /*lowLevelData*/) {
            return (false);
        }
    }

    // @notice This test MUST be updated when refund logic is implemented in the marketplace and escrow contracts
    function testSellerInitiateRefundOrSetStatusToOwnedNotForSaleFromPaidFor() public {
        // set conditions to identify an NFT that is PaidFor
        uint hornId = mintAndListFreshTestHorn();

        prepareForShipped(hornId);

        try market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(hornId) returns (uint ho) {
            Assert.ok(false, "Seller broke the rules and manipulated HornStatus even after Horn NFT was purchased and paid for by a buyer. That should only be possible after refunds are enabled");
        } catch (bytes memory /*lowLevelData*/) {
            return (false);
        }
    }

    // @notice This test has seller attempt to initiate refund despite them already having shipped the instrument
    function testSellerInitiateRefundOrSetStatusToOwnedNotForSaleFromShipped() public {
        // Set conditions to identify an NFT that is Shipped
        uint hornId = mintAndListFreshTestHorn();
        prepareForShipped(hornId);
        prepareForTransfer(hornId);
        try market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(hornId) returns (uint ho) {
            Assert.ok(false, "Evil scammer managed to set Horn NFT to OwnedNotForSale even after shipping the instrument");
        } catch (bytes memory /*lowLevelData*/) {
            return (false);
        }
    }

    /*
        Tests for getter functions
    */
    // @dev Tests the basic behavior of the hornsForSale[] uint[] array
    function testGetCurrentHornsForSale() public {
        // set conditions to have three NFTs for sale and one not for sale
        mintAndListFreshTestHorn(); // Id should == 1
        mintAndListFreshTestHorn(); // Id should == 2
        market.mintButDontListNewHornNFT( // Id should == 3
            "Berg",
            "Double",
            "Geyer", 
            serialNumberCounter
        );
        mintAndListFreshTestHorn(); // Id should == 4
        
        uint[] memory returnedIds = market.getCurrentHornsForSale();
        uint[] memory expectedIds = new uint[](3); // MAY NEED TO DO 3 ASSERT.EQUALS FOR EACH INDEX IN ARRAY BC OF REMIX-TESTS
        expectedIds[0] = 1;
        expectedIds[1] = 2;
        expectedIds[2] = 4;

        Assert.equal(returnedIds, expectedIds, "hornsForSale[] uint[] array does not return expected hornIds of the lovely mints being tested");
    }
    // @dev Tests the more complicated behavior of the hornsForSale[] uint[] array by calling purchaseHornByHornId which deletes hornIds when they are purchased
    function testGetCurrentHornsForSaleAfterDeletionViaPurchaseHornByHornId() public {
        // set conditions to have three NFTs for sale and one not for sale, then purchases 2 and 4, removing them from hornsForSale[] array
        mintAndListFreshTestHorn(); // Id should == 1
        uint firstTestHornId = mintAndListFreshTestHorn(); // Id should == 2
        market.mintButDontListNewHornNFT( // Id should == 3
            "Berg",
            "Double",
            "Geyer", 
            serialNumberCounter
        );
        // @dev Purchases the listed firstTestHornId and thereby 'deletes' it from the hornsForSale[] uint[] array by resetting its value to 0
        prepareForShipped(firstTestHornId);
        uint secondTestHornId = mintAndListFreshTestHorn(); // Id should == 4
        prepareForShipped(secondTestHornId);
        // @dev Purchases the listed secondTestHornId and thereby 'deletes' it from the hornsForSale[] uint[] array by resetting its value to 0
        
        uint[] memory returnedIds = uint[](market.getCurrentHornsForSale());
        uint[] memory expectedIds = new uint[](3); // originally [1, 2, 4] but 2 and 4 get zeroed out by purchases
        expectedIds[0] = 1;
        expectedIds[1] = 0;
        expectedIds[1] = 0;


        Assert.equal(returnedIds, expectedIds, "hornsForSale[] uint[] array does not return expected hornId values after minting/listing/purchasing a selection of juicy NFTs");
    }

    // @dev Test price getter function of listPrice attribute inside horn struct of given HornId
    // @notice This function is used as a helper at different stages of the transaction to track intended behavior
    function testGetListPriceByHornId(uint __hornId) public view returns (bool) {
        require(market.getHornById(__hornId).listPrice > 0, "Horn NFT listPrice appears to be 0, check mint execution");
        uint expectedPrice = market.getHornById(__hornId).listPrice;
        uint returnedPrice = market.getListPriceByHornId(__hornId);

        Assert.equal(expectedPrice, returnedPrice, "Expected listPrice attribute of horn NFT struct does not match the one given by marketplace getter function");
    }

    // @dev Test current owner getter function by getting returned address of given hornId
    // @notice This function is used as a helper at different stages of the transaction to track intended behavior
    function testGetCurrentOwnerMappingAgainstStructAttributeByHornId(uint __hornId) public view returns (bool) {
        address payable mappingOwner = market.getCurrentOwnerByMapping(__hornId);
        address payable structOwner = market.getCurrentOwnerByStructAttribute(__hornId);
        
        Assert.equal(mappingOwner, structOwner, "currentOwner of horn NFT via mapping does not match that of currentOwner via struct attribute");
        return true;
    }

    // @dev Test current enum status getter function via given hornId
    // @notice This function is used as a helper at different stages of the transaction to track intended behavior
    function testGetStatusOfHornById(uint __hornId, uint _expectedHornStatus) public view returns (bool) {
        // convert given expected HornStatus enum to a uint for comparison to market's function returnedEnum
        uint expectedEnum = _expectedHornStatus; // 0 = ListedForSale, 1 = PaidFor, 2 = Shipped, 3 = OwnedNotForSale
        uint returnedEnum = uint(market.getStatusOfHornByHornId(__hornId));

        Assert.equal(returnedEnum, expectedEnum, "HornStatus enum uint returned by marketplace contract does not match the expected one given");
    } 

    // @dev Test the current balance of deposits for given address in escrow contract against market getter function
    function testGetEscrowDepositValue(address payee) public {
        uint returnedDepositValue = market.getEscrowDepositValue(payee);
        uint correctDepositValue = market.getEscrowDepositValue(payee);

        Assert.equal(returnedDepositValue, correctDepositValue, "Value returned by getEscrowDepositValue does not match escrow depositsOf method");
    }

    // @dev Test the behavior of marketplace contract on receipt of only ETH without data
    // @dev Should revert on receipt of ETH without msg.data via fallback() function
    function testIncomingEther() public {
        try sendEtherTest() {
            Assert.ok(false, "Warning: a suspiciously generous soul donated funds to the marketplace contract without msg.data, check fallback");
        } catch (bytes memory /*lowLevelData*/) {
            return (false);
        }
    }

    /*
    *   Helper Functions 
    */

    // @dev Mints a fresh Horn NFT from the seller contract for testing purposes
    // @param serialNumberCounter is incremented every time this function is called so that the nonDuplicateMint modifier hashes make and serial data without collision
    function mintAndListFreshTestHorn() public returns (uint) {
        serialNumberCounter++;

        /// #sender: account-1
        uint currentHornId = market.mintThenListNewHornNFT( // MAKE SURE ABOVE LINE WORKS EVEN WITH UINT ASSIGNMENT ON THIS LINE ++ IF THEY DONT WORK INSIDE FUNCTIONS JUST DELETE THESE HELPER FUNCTIONS AND MOVE THE WORKING LOGIC TO THE TEST FUNCTIONS
            "Berg",
            "Double",
            "Geyer", 
            serialNumberCounter,
            defaultListPrice
        );

        return currentHornId;
    }
    
    // @dev Mints but does not list a fresh Horn NFT from the seller for testing purposes
    // @param serialNumberCounter is incremented every time this function is called so that the nonDuplicateMint modifier hashes make and serial data without collision
    function mintButDontListFreshTestHorn() public returns (uint) {
        serialNumberCounter++;

        /// #sender: account-1
        uint currentHornId = market.mintButDontListNewHornNFT(
            "Berg",
            "Double",
            "Geyer", 
            serialNumberCounter
        );

        return currentHornId;
    }

    // @dev Prepares a given Horn NFT for markShipped testing
    // @param This function is payable and must be given a msg.value to carry out the market.purchaseHornByHornId line
    function prepareForShipped(uint hornId) public payable returns (string memory) {
        string memory testShipTo = "21 Mil St. BTCidatel, Metaverse 69696";

        /// #sender: account-2
        /// #value: 420
        market.purchaseHornByHornId(hornId, testShipTo);

        return testShipTo;
    }

    // @dev Prepares a given Horn NFT for markHornDelivered and transfer testing
    function prepareForTransfer(uint hornId) public returns (string memory) {
        string memory testShipTo = "21 Mil St. BTCidatel, Metaverse 69696";
        
        /// #sender: account-1
        market.markHornShipped(hornId, testShipTo);

        return testShipTo;
    }

    // @dev Finalizes the transfer of a given Horn NFT upon delivery
    function deliveredAndTransfer(uint hornId) public returns (uint) {
        /// #sender: account-2
        uint paymentAmt = market.markHornDeliveredAndOwnershipTransferred(hornId);

        return paymentAmt;
    }

    // @dev Helper function intended to throw on execution as dry Ether is rejected by the marketplace contract
    function sendEtherTest() public payable {
    /// #sender: account-0
    /// #value: 1000000000000000000
        address(market).call("");
    }
}
