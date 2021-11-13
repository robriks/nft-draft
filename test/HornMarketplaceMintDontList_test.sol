// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.0;

// import "remix_tests.sol"; // injected by remix-tests CLI
// import "../contracts/HornMarketplace.sol";
// import "remix_accounts.sol";
// import "./Seller.sol";

//     // @param Declare targeted HornMarketplace, Seller, and Buyer addresses for instantiating and subsequent testing
//     HornMarketplace market;
//     Seller seller;
//     //Buyer buyer;
//     // @param This serialNumberCounter gives a new serialNumber to mint fresh Horn NFTs for every subsequent test without any hash collisions from make and serialNumber via the nonDuplicateMint modifier
//     // uint serialNumberCounter;
//     uint defaultListPrice;

//     function beforeAll() public {

//         // UNCOMMENT next three lines for Development only
//         market = new HornMarketplace();
//         seller = new Seller();
//         // buyer = new Buyer();

//         // UNCOMMENT next three lines for Rinkeby only
//         //market = HornMarketplace(0x);
//         //seller = Seller(0x);
//         //buyer = Buyer(0x);

//         // serialNumberCounter = 0;
//         defaultListPrice = 420; // lelz
//     }

// // @dev Test minting an instrument for the first time but NOT listing it for sale
//     function testMintButDontListNewHornNFT() public {
//         // Mints but does not list a new Horn NFT from this contract and returns currentHornId
//         uint returnedHornId = seller.mintDontListTestHornNFT(address(market));
//         uint expectedHornId = 2; // Expected currentHornId is 2 as this is the second test Horn NFT minted
        
//         Assert.equal(returnedHornId, expectedHornId, "returnedHornId given by mintAndListFreshTestHorn's Counter.Counter does not match the expectedHornId of 1 for a fresh contract instance's first mint");
//     }

//     function testBalanceOfSellerAgain() public {
//         uint returnedBalanceHornId = market.getBalanceOf(address(seller)); 
//         uint expectedBalance = 2;
//         // Check that Horn NFT was _minted properly to the seller address
//         Assert.equal(returnedBalanceHornId, expectedBalance, "Balance of sellerAddress as returned by ERC721 method does not match the expected Horn NFT tokenId of 1");
//     }

//     function testSerialNumberAgain() public {
//         uint returnedSerialNumber = market.getHornById(2).serialNumber;
//         uint expectedSerialNumber = 2;
//         // Check that serialNumber was properly set
//         Assert.equal(returnedSerialNumber, expectedSerialNumber, "SerialNumber error");
//     }

//     function testMakeAgain() public {
//         string memory returnedMake = market.getHornById(2).make;
//         string memory expectedMake = "Berg";
//         // Check that make was properly set
//         Assert.equal(returnedMake, expectedMake, "Make error");
//     }

//     // function testTokenURI() public {
//         // tokenURI variables here
//     // }

//     function testModelAgain() public {
//         string memory returnedModel = market.getHornById(2).model;
//         string memory expectedModel = "Double";
//         // Check that model was properly set
//         Assert.equal(returnedModel, expectedModel, "Model error");
//     }

//     function testStyleAgain() public {
//         string memory returnedStyle = market.getHornById(2).style;
//         string memory expectedStyle = "Geyer";
//         // Check that style was properly set
//         Assert.equal(returnedStyle, expectedStyle, "Style error");
//     }

//     function testCurrentOwnerAgain() public {
//         address payable returnedCurrentOwner = market.getHornById(2).currentOwner;
//         address payable expectedCurrentOwner = payable(address(seller));
//         // Check that currentOwner of NFT was set to minter, in this case the seller address
//         Assert.equal(returnedCurrentOwner, expectedCurrentOwner, "Horn NFT was minted to a different address than the seller address, check execution of mint and the currentOwner attribute");
//     }
