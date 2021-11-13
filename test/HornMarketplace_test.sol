// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "remix_tests.sol"; // injected by remix-tests CLI
import "../contracts/HornMarketplace.sol";
import "remix_accounts.sol";
import "./Seller.sol";

contract HornMarketplace_test is HornMarketplace {

    // @param Declare targeted HornMarketplace, Seller, and Buyer addresses for instantiating and subsequent testing
    HornMarketplace market;
    Seller seller;
    //Buyer buyer;
    // @param This serialNumberCounter gives a new serialNumber to mint fresh Horn NFTs for every subsequent test without any hash collisions from make and serialNumber via the nonDuplicateMint modifier
    // uint serialNumberCounter;
    uint defaultListPrice;

    function beforeAll() public {

        // UNCOMMENT next three lines for Development only
        market = new HornMarketplace();
        seller = new Seller();
        // buyer = new Buyer();

        // UNCOMMENT next three lines for Rinkeby only
        //market = HornMarketplace(0x);
        //seller = Seller(0x);
        //buyer = Buyer(0x);

        // serialNumberCounter = 0;
        defaultListPrice = 420; // lelz
    }

    /* 
    *  Test Functions
    */

    // @notice Testing for event emission is specifically NOT supported by solidity smart contracts so those tests must be done in javascript
    // @dev Sanity checks for horn owner of marketplace and escrow contracts
    function testOwnerOfHornMarketplaceContract() public {

        address returnedOwnerOfHornMarketplaceContract = market.owner(); // uses openzeppelin Ownable.sol function call
        address deployerOfHornMarketplaceContract = address(this);
        
        Assert.equal(returnedOwnerOfHornMarketplaceContract, deployerOfHornMarketplaceContract, "Owner address given by Ownable library function does not match deployer of the Marketplace contract");
    }

    function testOwnerOfEscrow() public {

        address returnedOwnerOfEscrow = market.getEscrowOwner();
        address correctOwnerOfEscrow = address(market); //DeployedAddresses.HornMarketplace()

        Assert.equal(returnedOwnerOfEscrow, correctOwnerOfEscrow, "Owner of instantiated escrow contract does not match HornMarketplace contract address");
    }

    // @dev Test minting an instrument for the first time
    function testMintThenListNewHornNFT() public {
        //serialNumberCounter++;
        // Mints a fresh Horn NFT with defaultListPrice, increments serialNumber, returns currentHornId
        uint returnedHornId = seller.mintThenListTestHornNFT(address(market));
        uint expectedHornId = 1; // Expected current hornId should be 0 after minting to a fresh contract instance
        // Check that a fresh hornId was created
        Assert.equal(returnedHornId, expectedHornId, "returnedHornId given by mintAndListFreshTestHorn's Counter.Counter does not match the expectedHornId of 1 for a fresh contract instance's first mint");
    }
    
    function testBalanceOfSeller() public {
        uint returnedBalanceHornId = market.getBalanceOf(address(seller)); 
        uint expectedBalance = 1;
        // Check that Horn NFT was _minted properly to the seller address
        Assert.equal(returnedBalanceHornId, expectedBalance, "Balance of sellerAddress as returned by ERC721 method does not match the expected Horn NFT tokenId of 1");
    }

    function testListPrice() public {
        uint returnedListPrice = market.getListPriceByHornId(1);
        // Check that listPrice was updated properly
        Assert.equal(returnedListPrice, defaultListPrice, "ListPrice error");
    }
    // @param Uint array hornsForSale[] takes the horn struct at index 0
    function testAddedToForSaleArray() public {
        uint addedToForSaleArray = market.hornsForSale(0);
        uint currentHornId = 1;
        // Check that hornsForSale[] uint[] array was updated to include returnedHornId
        Assert.equal(addedToForSaleArray, currentHornId, "NFT hornId returned by hornsForSale[] uint[] array does not match the hornId that should have been pushed. Check index and execution of listExistingHornNFT()");
    }

    function testSerialNumber() public {
        uint returnedSerialNumber = market.getHornById(1).serialNumber;
        uint expectedSerialNumber = 1;
        // Check that serialNumber was properly set
        Assert.equal(returnedSerialNumber, expectedSerialNumber, "SerialNumber error");
    }

    function testMake() public {
        string memory returnedMake = market.getHornById(1).make;
        string memory expectedMake = "Berg";
        // Check that make was properly set
        Assert.equal(returnedMake, expectedMake, "Make error");
    }

    // function testTokenURI() public {
        // tokenURI variables here
    // }

    function testModel() public {
        string memory returnedModel = market.getHornById(1).model;
        string memory expectedModel = "Double";
        // Check that model was properly set
        Assert.equal(returnedModel, expectedModel, "Model error");
    }

    function testStyle() public {
        string memory returnedStyle = market.getHornById(1).style;
        string memory expectedStyle = "Geyer";
        // Check that style was properly set
        Assert.equal(returnedStyle, expectedStyle, "Style error");
    }

    function testCurrentOwner() public {
        address payable returnedCurrentOwner = market.getHornById(1).currentOwner;
        address payable expectedCurrentOwner = payable(address(seller));
        // Check that currentOwner of NFT was set to minter, in this case the seller address
        Assert.equal(returnedCurrentOwner, expectedCurrentOwner, "Horn NFT was minted to a different address than the seller address, check execution of mint and the currentOwner attribute");
    }

    // @dev Test current owner getter function by getting returned address of given hornId
    function testGetCurrentOwnerMappingAgainstStructAttributeByHornId() public returns (bool) {
        address payable mappingOwner = market.getCurrentOwnerByMapping(1);
        address payable structOwner = market.getCurrentOwnerByStructAttribute(1);
        
        Assert.equal(mappingOwner, structOwner, "currentOwner of horn NFT via mapping does not match that of currentOwner via struct attribute");
        return true;
    }

    // @dev Test price getter function of listPrice attribute inside horn struct of given HornId
    function testGetListPriceByHornId() public returns (bool) {
        uint testHornId = 1;
        require(market.getHornById(testHornId).listPrice > 0, "Horn NFT listPrice appears to be 0, check mint execution");
        uint expectedPrice = market.getHornById(testHornId).listPrice;
        uint returnedPrice = market.getListPriceByHornId(testHornId);

        Assert.equal(expectedPrice, returnedPrice, "Expected listPrice attribute of horn NFT struct does not match the one given by marketplace getter function");
        return true;
    }

    function testGetStatusOfHornByHornId() public returns (bool) {
        uint testHornId = 1;
        uint expectedStatus = 0; // 0 = ListedForSale, 1 = PaidFor, 2 = Shipped, 3 = OwnedNotForSale
        uint returnedStatus = uint(market.getStatusOfHornByHornId(testHornId));

        Assert.equal(returnedStatus, expectedStatus, "HornStatus enum uint returned by marketplace contract does not match the expected one given");
        return true;
    }

    // @notice Modifier tests to ensure that access control and other modifier functions work properly
    // @dev Attempts to mint a duplicate Horn NFT, which should fail the nonDuplicateMint modifier
    // @param serialNumber provided (1) causes a hash collision against serialNumberCounter since it was used to mint the test horn in Marketplace contract by beforeAll()
    // function testNonDuplicateMint() public returns (bool) {
    //     // Function intended to throw on execution because the provided serialNumber and make cause a collision
    //     try market.mintThenListNewHornNFT(
    //       "Berg",
    //       "Double",
    //       "Geyer",
    //       1, 
    //       defaultListPrice) 
    //       returns (uint hn) {
    //           Assert.ok(false, "A corrupt copycat was able to mint a Horn NFT with duplicate hash of make and serialNumber");
    //       } catch Error(string memory reason) {
    //           Assert.equal(reason, "This Horn NFT has already been minted", "Failed with unexpected reason"); 
    //       } catch (bytes memory /*lowLevelData*/) {
    //           Assert.ok(false, "failed unexpectedly");
    //     }
    // }

    // @dev Attempts to call transfer ownership function from non-buyer address without paying
    // @dev Ensures only buyer can markHornDeliveredAndOwnershipTransferred
    function testOnlyBuyerWhoPaidOnListedForSale() public returns (bool) {
        uint testHornId = 1;

        try market.markHornDeliveredAndOwnershipTransferred(testHornId) returns (uint256 amt) {
            Assert.ok(false, "An account that hasn't paid or been marked as buyer pilfered the NFT!");
        } catch Error(string memory reason) {
            Assert.equal(reason, "This function may only be called by a buyer who has already paid", "Failed with unexpected reason");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, "Failed unexpectedly");
        }
    }
    
    // @dev Tests internal enum HornStatus functions to ensure that a currentOwner may change their mind about whether to list an instrument for sale
    function testSellerInitiateRefundOrSetStatusToOwnedNotForSale() public {
       // Identify the test NFT that is ListedForSale
       uint testHornId = 1;

       uint returnedStatus = uint(market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(testHornId));
       uint expectedStatus = 3;

       Assert.equal(returnedStatus, expectedStatus, "HornStatus returned by sellerInitiateRefundOrSetStatusToOwnedNotForSale() did not match HornStatus.OwnedNotForSale");
    }

    // function testSellerInitiateRefundOrSetStatusToOwnedNotForSaleOnOwnedNotForSale() public {
    //     // Set conditions to identify an NFT that is OwnedNotForSale
    //     uint testHornId = 1;

    //     // Function intended to throw on execution because Horn is already ListedForSale
    //     try market.sellerInitiateRefundOrSetStatusToOwnedNotForSale(testHornId) returns (HornMarketplace.HornStatus ho) {
    //         Assert.ok(false, "Function should have reverted because Horn is already set to OwnedNotForSale");
    //     } catch Error(string memory reason) {
    //         Assert.equal(reason, "Horn is already marked as owned and not for sale", "Failed with unexpected reason");
    //     } catch (bytes memory /*lowLevelData*/) {
    //         Assert.ok(false, "Failed unexpectedly");
    //     }
    // }

    // function testOnlyBuyerWhoPaidOnOwnedNotForSale() public {
    //     uint testHornId = 1;

    //     try market.markHornDeliveredAndOwnershipTransferred(testHornId) returns (uint256 amt) {
    //         Assert.ok(false, "An account that hasn't paid or been marked as buyer pilfered the NFT!");
    //     } catch Error(string memory reason) {
    //         Assert.equal(reason, "This function may only be called by a buyer who has already paid", "Failed with unexpected reason");
    //     } catch (bytes memory /*lowLevelData*/) {
    //         Assert.ok(false, "Failed unexpectedly");
    //     }
    // }

    // @dev Test minting an instrument for the first time but NOT listing it for sale
    function testMintButDontListNewHornNFT() public {
        // Mints but does not list a new Horn NFT from this contract and returns currentHornId
        uint returnedHornId = seller.mintDontListTestHornNFT(address(market));
        uint expectedHornId = 2; // Expected currentHornId is 2 as this is the second test Horn NFT minted
        
        Assert.equal(returnedHornId, expectedHornId, "returnedHornId given by mintAndListFreshTestHorn's Counter.Counter does not match the expectedHornId of 1 for a fresh contract instance's first mint");
    }

    function testBalanceOfSellerAgain() public {
        uint returnedBalanceHornId = market.getBalanceOf(address(seller)); 
        uint expectedBalance = 2;
        // Check that Horn NFT was _minted properly to the seller address
        Assert.equal(returnedBalanceHornId, expectedBalance, "Balance of sellerAddress as returned by ERC721 method does not match the expected Horn NFT tokenId of 1");
    }

    function testSerialNumberAgain() public {
        uint returnedSerialNumber = market.getHornById(2).serialNumber;
        uint expectedSerialNumber = 2;
        // Check that serialNumber was properly set
        Assert.equal(returnedSerialNumber, expectedSerialNumber, "SerialNumber error");
    }

    function testMakeAgain() public {
        string memory returnedMake = market.getHornById(2).make;
        string memory expectedMake = "Berg";
        // Check that make was properly set
        Assert.equal(returnedMake, expectedMake, "Make error");
    }

    // function testTokenURI() public {
        // tokenURI variables here
    // }

    function testModelAgain() public {
        string memory returnedModel = market.getHornById(2).model;
        string memory expectedModel = "Double";
        // Check that model was properly set
        Assert.equal(returnedModel, expectedModel, "Model error");
    }

    function testStyleAgain() public {
        string memory returnedStyle = market.getHornById(2).style;
        string memory expectedStyle = "Geyer";
        // Check that style was properly set
        Assert.equal(returnedStyle, expectedStyle, "Style error");
    }

    function testCurrentOwnerAgain() public {
        address payable returnedCurrentOwner = market.getHornById(2).currentOwner;
        address payable expectedCurrentOwner = payable(address(seller));
        // Check that currentOwner of NFT was set to minter, in this case the seller address
        Assert.equal(returnedCurrentOwner, expectedCurrentOwner, "Horn NFT was minted to a different address than the seller address, check execution of mint and the currentOwner attribute");
    }

}


// contract Buyer is HornMarketplace {

//     constructor(address __mkt) public {

//     }

// }




    // mintdontlist, getstatus, onlysellervialist, forsale, sellerinitiaterefund

    // testlistingexisting( on minted), getstatus, getcurrenthornsforsale, sellerinitiaterefund, getlistprice, paidenough, paidfor

    // testpurchase, getstatus, getescrowdepositvalue, sellerinitiaterefund, getcurrenthornsforsaleafterdelete, onlysellerviamarkshipped, markshippedwithwrongaddress, testshipped

    // testmarkhornshipped, getstatus, sellerinitiaterefund, onlybuyerwhopaid

    // testmarkhorndelivered, getstatus, sellerinitiaterefund, incomingETH

