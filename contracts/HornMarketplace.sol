// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/* import openzeppelin dependency lines here:
Ownable (for management), 
Roles (for buyer/seller access control), 
ERC721Full (for horns & compatability w/ the following contracts), 
TokenReceiver (to manage transfers --necessary?), 
MetaData (on chain storing of (make, model, year, serial number), 
Enumerable (for easy viewing on the front-end website marketplace)
*/

/*
use tokenURI to point to images of the listed instrument (host and store on my website?)

*/

contract HornMarketplace is // Ownable, Roles, ERC721, ERC721TokenReceiver, ERC721MetaData, ERC721Enumerable {
    
    /*
        On-chain Horn data: Metadata Struct, HornId Index
    */
    // @param make denotes builder/manufacturer of the instrument 
    // @param model denotes model name of the instrument
    // @param style denotes double/triple/descant/single/compensating and wrap ie geyer/kruspe/knopf/other
    // @param serialNumber denotes serial number
    // @param seller denotes seller who listed
    // @param buyer denotes buyer who purchased
    struct Horn {
      string: make,
      string: model,
      string: style,
      uint: serialNumber,
      address: seller,
      address: buyer,
    }

    uint HornId;

    // @notice horns mapping keeps track of horn owners via hornIndex
    mapping (uint => Horn) horns;
    // @dev sellers and buyers mappings used for roles-based function access
    // @dev add address to sellers when horn is listed, address to buyers when horn is purchased
    mapping (uint => address) sellers;
    mapping (uint => address) buyers;
    
    // @notice tx events used for front-end
    event HornListedForSale(uint indexed hornId);
    event HornPurchased(uint indexed hornId);

    /* 
        Modifiers for Roles-based function access!
    */
    // @dev only buyers should be able to mark as received
    modifier onlyBuyer() {}
    // @dev only sellers should be able to mark as shipped 
    modifier onlySeller() {}

    constructor() public {
        HornId = 0;
    }
    /*
        Marketplace Function implementations
    */
    //list horn for sale by minting with metadata to fill Horn struct on-chain
    function list(
        string _make, 
        string _model, 
        string _style, 
        uint _serialNumber, 
        address _seller, 
        address _buyer) {
        _seller = msg.sender;
    }

    function purchaseHornById(uint _hornId) public {
        /// wait for escrow contract to receive payment
        /// add msg.sender to buyers[] mapping: 
        // buyers[hornId].push(msg.sender)
        /// notify seller that horn is paid for and must be shipped
        // emit HornPurchased(hornId);
    }

    function markHornShipped(uint _hornId) public onlySeller() {}
}
