// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin-contracts/access/ownable.sol";
import "@openzeppelin-contracts/contracts/utils/Counters.sol";
import "@openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol"; // necessary?
import "@openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // necessary?

// ERC721Full (for horns & compatability w/ the following contracts), ??


// use tokenURI to point to images of the listed instrument (host and store on my website?)

/*
   Interfaces
*/

contract HornMarketplace is Ownable, ERC721TokenReceiver, ERC721URIStorage, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _hornId;
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

    // @dev hornId is a unique, publicly accessible counter (as opposed to Counter _hornId) for each horn NFT in existence
    // @dev hornsForSale array allows for quickly viewing listed instruments
    // uint public hornId; think this is not necessary
    // address public owner; how to make myself owner?
    uint[] hornsForSale;

    // @notice horns mapping keeps track of horn owners (not just buyers/sellers) via _hornId
    mapping (uint => Horn) horns;
    // @dev sellers and buyers mappings used for roles-based function access
    // @dev add address to sellers when horn is listed, address to buyers when horn is purchased
    mapping (uint => address) currentOwners; // need a sellers mapping in addition? or loop through hornsForSale[] array to show sellers. whichever makes searching faster
    mapping (uint => address) buyers;
    
    // @notice tx events used for front-end
    event HornListedForSale(uint indexed _hornId);
    // event BidReceived(uint indexed _hornId); //bidding may be a later feature
    event HornPurchased(uint indexed hornId, string indexed shipTo, address indexed buyer);
    event HornShipped(uint indexed hornId);
    event HornDelivered(uint indexed hornId);


    /* 
        Modifiers for Roles-based function access!
    */
    // @dev Owner role provided in case of emergency bugs or exploits
    modifier onlyOwner() {
        _;
    }
    // @dev only buyers should be able to mark as received
    modifier onlyBuyer() {
        _;
    }
    // @dev only sellers should be able to mark as shipped 
    modifier onlySeller() {
        _;
    }
    // @dev Following modifiers read enum HornStatus of _hornIds to filter functions by state
    // @notice NOT ALL OF THESE MAY END UP BEING REQUIRED FOR SMOOTH EXCHANGE
    modifier forSale(uint hornId) {
        require(uint(horns[_hornId].status) == 1); // requires ListedForSale
        _;
    }
    //modifier paidFor(uint _hornId) {
    //   require(uint(horns[_hornId].status) == 2); // requires PaidFor
    //   _;
    //}
    modifier shipped(uint _hornId) {
        require(uint(horns[_hornId].status) == 3); // requires Shipped
        _;
    }


    constructor() public {
        _hornId = 0; //may not be necessary if initialized to 0 anyway
        // owner = msg.sender; how to make myself owner?
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
        uint _desiredPrice) 
        public onlySeller() returns (uint) {
          // @dev Increment counter _hornId then store publicly accessible hornId using current counter
          _hornId.increment();
          uint hornId = _hornId.current();
          _mint(msg.sender, hornId);
          // _setTokenURI logic still needs to be implemented
          
          // @dev Store all horn metadata on-chain EXCEPT images which are stored externally via URI
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

          return hornId;

          emit HornListedForSale(_hornId);
    }

    function purchaseHornById(uint hornId, string _shipTo) public onlyBuyer() {
        /// MUST provide shipping address !!!
        /// string shipTo = _shipTo;
        /// send payment to escrow contract
        // use approve and .transferFrom methods of IERC20 here to send stablecoins
        /// add msg.sender to buyers[] mapping: 
        // buyers[_hornId].push(msg.sender)
        /// notify seller that horn is paid for and must be shipped
        // emit HornPurchased(_hornId, shipTo, buyers[_hornId]);
    }

    function markHornShipped(uint _hornId) public onlySeller() {
        // confirm shipping address shipTo?
        // change horns[_hornId].status = Shipped;

        // approve this contract as spender of horn nft

        // emit HornShipped(_hornId);
    }

    function markHornReceived(uint _hornId) public onlyBuyer() {
        // change horns[_hornId].status = Received;  or Owned??
        // emit HornDelivered(_hornId);
    }
    
    function getHornIdPrice(uint hornId) external returns (uint) {
        return horns[_hornId]
    }
}
