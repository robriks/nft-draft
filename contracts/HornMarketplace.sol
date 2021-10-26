// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/escrow/Escrow.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // Not actually necessary but included here in case users new to NFTs send to address(this)

// use tokenURI to point to images of the listed instrument (host and store on my website)

/*
   Interfaces
*/

contract HornMarketplace is Ownable, ERC721TokenReceiver, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _hornId; // OpenZeppelin library initializes this to 0 by default
    /*
        Instantiate Escrow Contract
    */
    Escrow escrow;
    //EscrowContract escrow = EscrowContract(DEVELOPMENT_DEPLOYED_ESCROW_ADDR_HERE); // these two lines necessary?
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
    struct Horn { // optimize gas on these struct attributes- which order/size?
      string make;
      string model;
      string style;
      uint32 serialNumber;
      uint32 listPrice;
      HornStatus status;
      address currentOwner;
    }

    /*
        Enum for Status of Order
    */
    enum HornStatus {
        ListedForSale,
        PaidFor,
        Shipped,
        OwnedNotForSale
    }

    // @dev hornId is a unique, publicly accessible counter (as opposed to Counter _hornId) for each horn NFT in existence
    // @dev hornsForSale array allows for quickly viewing listed instruments
    // uint public hornId; think this is not necessary
    address payable owner;
    uint[] hornsForSale;

    // @notice horns mapping keeps track of horn owners (not just buyers/sellers) via _hornId
    mapping (uint => Horn) horns;
    // @dev sellers and buyers mappings used for roles-based function access
    // @dev add address to sellers when horn is listed, address to buyers when horn is purchased
    mapping (uint => address) currentOwners; // need a sellers mapping in addition? or loop through hornsForSale[] array to show sellers. whichever makes searching faster
    mapping (uint => address) buyers;
    mapping (address => string) shippingAddresses;
    
    // @notice tx events used for front-end
    event HornListedForSale(uint indexed hornId, address indexed seller /*, string makeAndModel*/); // make and model may be useful for front end
    // event BidReceived(uint indexed _hornId); //bidding may be a later feature
    event HornPurchased(uint indexed hornId, string indexed shipTo, address indexed buyer);
    event HornShipped(uint indexed hornId, string indexed shipTo, address indexed to);
    event HornDelivered(uint indexed hornId, address indexed from, address indexed to);
    event HornNFTOwnershipTransferred(uint indexed hornId, address indexed from, address indexed to);


    /* 
        Modifiers for Roles-based function access!
    */
    // @dev Maintain an owner address in case of emergency
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    // @dev Only buyers should be able to mark as received
    modifier onlyBuyerWhoPaid(uint hornId) {
        require(buyers[hornId] == msg.sender);
        _;
    }
    modifier onlySeller(uint hornId) {
        require(currentOwners[hornId] == msg.sender); // is this best way to check that msg sender owns the horn theyre trying to list?
        _;
    }
    // @dev Only sellers should be able to mark as shipped 
    modifier onlyFirstTimer(uint hornId) {
        require(currentOwners[hornId] == address(0)); // is this how to check for msg sender not having any horns to sell?
        _;
    }
    // @dev Checks that function caller sent exact ETH amount to purchase horn for listed price
    modifier paidEnough(uint hornId) {
        require(msg.value == horns[hornId].listPrice); // later implement logic that calculates stablecoin price equivalents
    }
    // @dev Following modifiers read enum HornStatus of _hornIds to filter functions by state
    // @notice NOT ALL OF THESE MAY END UP BEING REQUIRED FOR SMOOTH EXCHANGE
    modifier forSale(uint __hornId) {
        require(horns[__hornId], "Horn NFT does not exist"); // ensure horn NFT exists
        require(uint(horns[__hornId].status) == 0); // requires ListedForSale
        _;
    }
    modifier hornPaidFor(uint __hornId) {
        require(horns[__hornId], "Horn NFT does not exist"); // ensure horn NFT exists
        require(uint(horns[__hornId].status) == 1); // requires PaidFor
        _;
    }
    modifier shipped(uint __hornId) {
        require(horns[__hornId], "Horn NFT does not exist"); // ensure horn NFT exists
        require(uint(horns[__hornId].status) == 2); // requires Shipped
        _;
    }

    // @dev Initializes the Horn NFT with name and symbol and instantiates the escrow contract 
    constructor() ERC721("Horn", "HORN") {
        escrow = new Escrow();
        // list my own horn for sale in constructor to save mainnet deploy gas?
    }
    /*
        Marketplace Function implementations
    */
    // @notice List horn for sale by minting with metadata to fill Horn struct on-chain
    function mintThenListHorn( // change this function to have an if clause that accommodates first time listing vs listing an existing NFT
        string _make, 
        string _model, 
        string _style, 
        uint32 _serialNumber, 
        uint32 _desiredPrice) 
        public onlySeller() returns (uint /*, string*/) {
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
            currentOwner: msg.sender
          });
                    
          // @dev update mappings and arrays to reflect new listing
          currentOwners[hornId] = msg.sender;
          hornsForSale.push(hornId);
          string makeAndModel = _make + _model;

          return hornId;
          // return makeAndModel; // Might help front end to provide make and model event emission

          emit HornListedForSale(hornId, msg.sender /*, makeAndModel*/);
    }

    // @dev Require that given __hornId is forSale and not already purchased
    function purchaseHornByHornId(uint __hornId, string _shipTo) 
      public 
      payable 
      forSale(__hornId) 
      paidEnough(__hornId) {
        /* storing home addresses on-chain involves significant privacy concerns, however
        * the recent infrastructure bill classifies any developer who writes code that handles monetary value on a blockchain
        * as a legally recognized "broker" who must report customer information like Address to the IRS
        * shipping addresses are stored on-chain for legal compliance reasons ONLY
        * Can these addresses be opaquely stored on front-end instead? zk rollups would alleviate this issue
        */
        // @dev Require that buyer sent correct amt of Eth to pay for horn **later can use if clauses to support stablecoin purchases
        require(msg.value == horns[__hornId].listPrice, "Payment must exactly match list price");
        // @dev Add shipping address of buyer aka msg.sender to mapping for later confirmation
        shippingAddresses[msg.sender] = _shipTo;
        
        /// Forward payment to escrow contract for safekeeping
        // escrow.deposit{ value: msg.value }; // later use approve and .transferFrom methods of IERC20 here to send stablecoins
        // @dev Add msg.sender to buyers[] mapping for access control checking during markHornShipped function call and shipping address confirmation: 
        buyers[__hornId].push(msg.sender);
        // @dev set status to PaidFor so next function to be called must be markHornShipped by seller
        horns[__hornId].status = HornStatus.PaidFor;

        delete hornsForSale[__hornId];

        // @notice Emit event to notify seller via frontend that horn is paid for and must be shipped
        emit HornPurchased(__hornId, _shipTo, msg.sender);
    }

    function markHornShipped(uint __hornId, string shippedTo) public 
      onlySeller(__hornId) 
      hornPaidFor(__hornId) {
        // @dev Set buyer variable to confirm shipping address shipTo against shippingAddresses mapping given by buyer
        address buyer = buyers[__hornId];
        require(shippedTo == shippingAddresses[buyer]);
        // @dev Set status of __hornId to Shipped so next function to be called will finalize exchange
        horns[__hornId].status = HornStatus.Shipped;
        // @dev Approves this contract as spender of horn nft so that it will be safetransferred in next function call 
        approve(address(this), __hornId);

        emit HornShipped(__hornId, shippedTo, buyers[__hornId]);
    }

    // Trial weeks for the instrument may be added as a later feature
    function markHornDeliveredAndOwnershipTransferred(uint __hornId) public 
      onlyBuyerWhoPaid(__hornId) 
      shipped(__hornId) {  
        /// MUST be called in order to release escrow funds to seller, and transfer ownership
        buyers[__hornId] = address(0);  // wipe msg.sender from buyers[] mapping for future txs
        // shippingAddresses[msg.sender] = address(0); // wipe msg.sender's shipping address from storage for future txs 
        /// release escrowed payment funds to the seller from escrow contract Escrow.releaseFunds()
        /// by using an internal function that returns true so that the seller may ConditionalEscrow withdraw()
        horns[__hornId].status = HornStatus.OwnedNotForSale;
        horns[__hornId].currentOwner = msg.sender;
        // @dev Set previousOwner variable using currentOwners mapping, before that value is updated to reflect new owner
        address memory previousOwner = currentOwners[__hornId];
        // @dev Update currentOwners mapping to give ownership to buyer
        currentOwners[__hornId] == msg.sender;

        // @dev Transfer horn NFT from seller(currentOwner) to msg.sender using safeTransferFrom from ERC721 interface (avoids NFTs locked in contracts)
        safeTransferFrom(horns[__hornId].currentOwner, msg.sender, __hornId);

        emit HornDelivered(__hornId, previousOwner, msg.sender);
        emit HornNFTOwnershipTransferred(__hornId, previousOwner, msg.sender);
    }
    
    /*
        Helper functions that provide (internal?) getter functionality
    */

    function getCurrentHornsForSale() public view returns (uint[]) {
        // loop through hornForSale[] uint array and display them to frontend to parse via hornId (could also do array of structs)
        // for (i = 0, i < hornsForSale[].length, i++) {
            // hornId = hornsForSale[i].id;
            // return horns[hornId];
        //}
    }

    function getListPriceByHornId(uint __hornId) public returns (uint32) {
        return horns[__hornId].listPrice(); // are () needed? also could typecast this line into string or uint if needed
    }

    function getCurrentOwnerByHornId(uint __hornId) public returns (address) {
        return currentOwners[__hornId];
    }

    function getStatusOfHornbyHornId(uint __hornId) public returns (uint) {
        return horns[__hornId].status;  // is this how to return the state of an enum within a struct?? typecast as uint(kdkdk)? returns (uint8???)
    }

    // in future, can add filter functions as well to display only doubles or only Lukas, etc
    /* in future, can add support for ERC20 stablecoin payments via a price getter helper function that uses chainlink to calculate current Eth amount to match listed price in dollars:
        something like require(msg.value == hornMarketplace.HORNPRICEGETTERFUNCTIONHERE()) but needs to aid user in submitting tx with correct ETH amount
    */


    /*
        Administrative Functions
    */
    /* 
    // Allows owner of the marketplace to withdraw fees accumulated by trading
    function withdrawAccumulatedFees() external onlyOwner {
        owner.call{value: address(this).balance};
    }
    function pause() external onlyOwner {
        _pause() // how does this work with pausable openzeppelin library?
    }
    */
}
