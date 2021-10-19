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
        Target Escrow Contract
    */
    //EscrowContract escrow = EscrowContract(DEVELOPMENT_DEPLOYED_ESCROW_ADDR_HERE);
    //EscrowContract escrow = EscrowContract(RINKEBY_DEPLOYED_ESCROW_ADDR_HERE)

    /*
        On-chain Horn data: Metadata Struct
    */
    // @param make denotes builder/manufacturer of the instrument 
    // @param model denotes model name of the instrument
    // @param style denotes double/triple/descant/single/compensating and wrap ie geyer/kruspe/knopf/other
    // @param serialNumber denotes serial number
    // @param currentOwner denotes musician who currently owns the instrument
    // @param buyer denotes buyer who purchased
    struct Horn {
      string make,
      string model,
      string style,
      uint serialNumber,
      uint listPrice,
      HornStatus status, 
      address currentOwner,
      address buyer,
    }

    /*
        Enum for Status of Order
    */
    enum HornStatus {
        NotForSale,
        ListedForSale,
        PaidFor,
        Shipped,
        Delivered,
        Completed
    }

    // @dev HornId is a unique counter for each horn NFT in existence
    // @dev hornsForSale array allows for quickly viewing listed instruments
    uint HornId;
    uint[] hornsForSale;

    // @notice horns mapping keeps track of horn owners (not just buyers/sellers) via hornId
    mapping (uint => Horn) horns;
    // @dev sellers and buyers mappings used for roles-based function access
    // @dev add address to sellers when horn is listed, address to buyers when horn is purchased
    mapping (uint => address) currentOwners; // need a sellers mapping in addition? or loop through hornsForSale[] array to show sellers. whichever makes searching faster
    mapping (uint => address) buyers;
    
    // @notice tx events used for front-end
    event HornListedForSale(uint indexed hornId);
    // event BidReceived(uint indexed hornId); //bidding may be a later feature
    event HornPurchased(uint indexed hornId, string indexed shipTo, address indexed buyer);
    event HornShipped(uint indexed hornId);
    event HornDelivered(uint indexed hornId);


    /* 
        Modifiers for Roles-based function access!
    */
    // @dev Owner role provided in case of emergency bugs or exploits
    modifier onlyOwner() {}
    // @dev only buyers should be able to mark as received
    modifier onlyBuyer() {}
    // @dev only sellers should be able to mark as shipped 
    modifier onlySeller() {}
    // @dev Following modifiers read enum HornStatus of hornIds to filter functions by state
    // @notice NOT ALL OF THESE MAY END UP BEING REQUIRED FOR SMOOTH EXCHANGE
    modifier forSale(uint hornId) {
        require(uint(horns[hornId].status) == 1); // requires ListedForSale
    }
    //modifier paidFor(uint hornId) {
    //   require(uint(horns[hornId].status) == 2); // requires PaidFor
    //}
    modifier shipped(uint hornId) {
        require(uint(horns[hornId].status) == 3); // requires Shipped
    }


    constructor() public {
        HornId = 0;
        // list my own horn for sale in constructor to save mainnet deploy gas?
    }
    /*
        Marketplace Function implementations
    */
    // @notice list horn for sale by minting with metadata to fill Horn struct on-chain
    function createListing(
        string _make, 
        string _model, 
        string _style, 
        uint _serialNumber, 
        uint _desiredPrice,
        // address _currentOwner *dont think this is needd
        // address _buyer  *dont think this is needed
        ) public {
          hornId++;
        
          horns[hornId] = Horn({
            make: _make,
            model: _model,
            style: _style,
            serialNumber: _serialNumber,
            listPrice: _desiredPrice,
            status: HornStatus.ListedForSale,
            currentOwner: msg.sender,
            buyer: address(0)
          )};
          
          // @dev update mappings and arrays to reflect new listing
          currentOwners[hornId] = msg.sender;
          hornsForSale.push(hornId);

          emit HornListedForSale(hornId);
    }

    function purchaseHornById(uint _hornId, string shipTo) public {
        /// MUST provide shipping address !!!
        /// 
        /// send payment to escrow contract
        // use approve and .transferFrom methods of IERC20 here to send stablecoins
        /// add msg.sender to buyers[] mapping: 
        // buyers[hornId].push(msg.sender)
        /// notify seller that horn is paid for and must be shipped
        // emit HornPurchased(hornId, shipTo, buyers[hornId]);
    }

    function markHornShipped(uint _hornId) public onlySeller() {
        // emit HornShipped(_hornId);
    }

    function markHornReceived(uint _hornId) public onlyBuyer() {}
}
