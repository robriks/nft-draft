// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/** 
  * @title Peer to peer Horn Marketplace using NFTs and Escrow Smart Contract
  * @author Markus Osterlund, 2nd Horn of National Symphony Orchestra and hopeful Ethereum Engineer @Consensys Academy Bootcamp
 */

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/escrow/Escrow.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // Not actually necessary but included here in case users new to NFTs send to address(this)

// use tokenURI to point to images of the listed instrument (host and store on my website)

/*
   Interfaces
*/

contract HornMarketplace is Ownable, /*IERC721Receiver, */ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter /*private*/ public _hornId; // OpenZeppelin library initializes this to 0 by default
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
      uint32 listPrice; // this attribute probably needs to be labeled as 'inWei' and converted from eth at time of listing
      HornStatus status;
      address payable currentOwner;
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
    // @dev hornsForSale array allows for quickly viewing listed instruments via frontend
    // address payable owner;
    uint[] hornsForSale;

    // @notice horns mapping keeps track of all horn NFT owners & histories via _hornId (s/o to OpenZep Counter.counter library)
    mapping (uint => Horn) horns;
    // @dev Add hash of horn NFT make and serialNumber using Counter.counter to compare all hashes to new mints in an effort to avoid duplicate NFTs of single instruments
    // mapping (uint => bytes memory) makeAndSerialHashes; // bytes32? 
    // @dev currentOwners and buyers mappings used for function access control
    // @dev Add address to buyers when horn is paid for via escrow, address to currentOwners when sale and exchange is complete
    mapping (uint => address) currentOwners;
    mapping (uint => address) buyers;
    mapping (address => string) shippingAddresses;
    
    // @notice NFT and IRL exchange events and escrow transaction events used for front-end
    event HornListedForSale(uint indexed hornId, address indexed seller /*, string makeAndModel*/); // make and model may be useful for front end
    // event BidReceived(uint indexed _hornId); //bidding may be a later feature
    event HornPurchased(uint indexed hornId, string indexed shipTo, address indexed buyer);
    event HornShipped(uint indexed hornId, string indexed shipTo, address indexed to);
    event HornDeliveredAndNFTOwnershipTransferred(uint indexed hornId, address indexed from, address indexed to);
    event DepositedToEscrow(address indexed payee, uint indexed amountInWei);
    event WithdrawnFromEscrow(address indexed payee, uint indexed amountInWei);
    event SellerPaid(uint indexed hornId, address indexed payer, address indexed payee);


    /* 
        Modifiers for Roles-based function access!
    */
    // @dev Maintain an owner address in case of emergency
    // modifier onlyOwner() {
    //     require(msg.sender == owner);
    //     _;
    // }
    // @dev Restrict to only users who are minting their instrument as an NFT for the first time by checking hashes of concatenated make and serial number
    // modifier nonDuplicateListing(uint hornId??, string make, uint serialNumber) {
        // require(!_exists(hornId), "This horn NFT has already been minted");
        // checkIfAlreadyMinted(_make, _serialNumber);

    // @dev Helper function to ensure that duplicate NFTs of the same horn are not minted by comparing hashes in a mapping
    // function checkIfAlreadyMinted(string make, uint32 serialNumber) internal pure returns (bool) {
    //   bytes memory hashOfMakeAndSerial = keccak256(abi.encodePacked(_make + _serialNumber)); // bytes32?
    //   for (i = 0, i < horns[].length, i++) {
    //     require(makeAndSerialHashes[i] != hashOfMakeAndSerial);
    //   } 
    // }

    // @dev Restrict to only buyer who paid and was added to buyers[] mapping
    modifier onlyBuyerWhoPaid(uint hornId) {
        require(buyers[hornId] == msg.sender, "This function may only be called by a buyer who has already paid");
        _;
    }
    // @dev Restrict to only the current owner of already minted horn NFT
    modifier onlySeller(uint hornId) {
        require(currentOwners[hornId] == msg.sender, "This function may only be called by the horn NFT's owner");
        _;
    }
    // @dev Checks that function caller sent exact ETH amount to purchase horn for listed price **later can use if/or clauses to support stablecoin purchases
    modifier paidEnough(uint hornId) {
        require(msg.value == horns[hornId].listPrice, "Payment amount must exactly match listed price"); // later implement logic that calculates stablecoin price equivalents
        _;
    }
    // @dev Following modifiers read enum HornStatus of _hornIds and escrow deposits to maintain security and correct order of function calls thru sale process
    modifier forSale(uint __hornId) {
        require(horns[__hornId].listPrice > 0, "Horn NFT must exist and cannot be free"); // ensure horn NFT exists and is listPrice is non 0
        require(uint(horns[__hornId].status) == 0, "Horn is not currently listed for sale"); // requires ListedForSale status
        _;
    }
    modifier hornPaidFor(uint __hornId) {
        require(escrow.depositsOf(msg.sender) == horns[__hornId].listPrice, "Buyer must send payment for Horn NFT to escrow first"); // ensure buyer has already deposited payment (listPrice) in escrow
        require(uint(horns[__hornId].status) == 1, "Horn has not been marked as paid for yet"); // requires PaidFor status
        _;
    }
    modifier shipped(uint __hornId) {
        require(_isApprovedOrOwner(address(this), __hornId), "This contract must first be approved by current horn owner"); // ensure this contract is approved to spend horn NFT by the seller
        require(uint(horns[__hornId].status) == 2, "Horn has not been marked as shipped yet"); // requires Shipped status
        _;
    }

    // @dev Initializes the Horn NFT with name and symbol and instantiates the escrow contract 
    constructor() ERC721("Horn", "HORN") {
        escrow = new Escrow();
    }
    /*
        Marketplace Function implementations
    */
    // @notice List horn for sale by minting with metadata to fill Horn struct on-chain
    // CHANGE THIS function to have an if clause that accommodates first time listing vs listing an existing NFT or create new function for existing horn nFTs? 
    // IF NEW FUNCTION, MAKE SURE ALL MAPPINGS/ATTRIBUTES ARE PROPERLY SET so escrow functions still work on correct addresses (ie line 191)
    function mintThenListNewHornNFT( 
        string calldata _make, 
        string calldata _model, 
        string calldata _style, 
        uint32 _serialNumber, 
        uint32 _desiredPrice) 
        external /* nonDuplicateListing(_hornId.current(), _make, _serialNumber) */ // double check how the Counter.counter works with _hornId in a modifier _; setting
        returns (uint /*, string*/) {
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
            currentOwner: payable(msg.sender)
          });
                    
          // @dev update mappings and arrays to reflect new listing
          currentOwners[hornId] = msg.sender;
          hornsForSale.push(hornId);

          // string makeAndModel = _make + _model; // for emitting new listing events on front end?
          // return makeAndModel; // Might help front end to provide make and model event emission

          emit HornListedForSale(hornId, msg.sender /*, makeAndModel*/);

          return hornId;

    }
    
    // following function must check that the hornNFT already exists!  and onlySeller(id) checks that it is owned by the caller of the function
    /* function listExistingHornNFT(uint __hornId, uint32 _desiredPrice) public onlySeller(__hornId) {
        add to hornsforsale uint[] array // consider adding a boolean struct attribute: forsale which may be easier than using uint[] array?
        set hornstatus to forsale
    }
    */

    // @dev Require that given __hornId is forSale and not already purchased
    function purchaseHornByHornId(uint __hornId, string calldata _shipTo) 
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
        // @dev Forward payment to escrow contract for safekeeping
        escrow.deposit(currentOwners[__hornId]);
        // @dev Add shipping address of buyer aka msg.sender to mapping for later confirmation
        shippingAddresses[msg.sender] = _shipTo;
        // @dev Add msg.sender to buyers[] mapping for access control checking during markHornShipped function call and shipping address confirmation: 
        buyers[__hornId] = msg.sender;
        // @dev Set status to PaidFor so next function to be called must be markHornShipped by seller
        horns[__hornId].status = HornStatus.PaidFor;
        // @dev Delete hornId from hornsForSale uint[] array so it is no longer displayed
        delete hornsForSale[__hornId];

        // @notice Emit event to notify seller via frontend that horn is paid for and must be shipped
        emit HornPurchased(__hornId, _shipTo, msg.sender);
        emit DepositedToEscrow(horns[__hornId].currentOwner, msg.value);
    }

    function markHornShipped(uint __hornId, string calldata shippedTo) public 
      onlySeller(__hornId) 
      hornPaidFor(__hornId) {
        // @dev Set buyer variable to confirm shipping address shipTo against shippingAddresses mapping given by buyer
        address buyer = buyers[__hornId];
        // @notice The addresses must match exactly as they are hashed- an issue considering extremely common user error, data fields must be explicit on front end for proper resolution
        require(keccak256(abi.encodePacked(shippedTo)) == keccak256(abi.encodePacked(shippingAddresses[buyer])), "Address given does not match the one on file for the buyer");
        // @dev Set status of __hornId to Shipped so next function to be called will finalize exchange
        horns[__hornId].status = HornStatus.Shipped;
        // @dev Approves this contract as spender of horn nft so that it will be safetransferred in next function call 
        approve(address(this), __hornId);
        
        // @notice Emit event to notify buyer via frontend that horn is on its way
        emit HornShipped(__hornId, shippedTo, buyers[__hornId]);
    }

    // This function MUST be called in order to release escrow funds to seller, and transfer NFT ownership
    function markHornDeliveredAndOwnershipTransferred(uint __hornId) public 
      onlyBuyerWhoPaid(__hornId) 
      shipped(__hornId) 
      returns (uint256) {
        // @dev Save payment amount in uint variable to be visually returned for improved UX/UI
        uint paymentAmt = escrow.depositsOf(horns[__hornId].currentOwner);
        // @dev Release escrowed payment funds to the seller from escrow contract
        escrow.withdraw(horns[__hornId].currentOwner);
        // @dev Wipe msg.sender from buyers[] and shippingaddresses[] for future txs in case buyer changes address
        buyers[__hornId] = address(0);
        shippingAddresses[msg.sender] = "";
        // @dev Set horn status to no longer be for sale and update horn ownership record history
        horns[__hornId].status = HornStatus.OwnedNotForSale;
        horns[__hornId].currentOwner = payable(msg.sender);
        // @dev Set previousOwner variable using currentOwners mapping, before that value is updated to reflect new owner
        address previousOwner = currentOwners[__hornId];
        // @dev Update currentOwners mapping to give ownership to buyer
        currentOwners[__hornId] == msg.sender;

        // @dev Transfer horn NFT from seller(currentOwner) to msg.sender using safeTransferFrom from ERC721 interface (avoids NFTs locked in contracts)
        safeTransferFrom(horns[__hornId].currentOwner, msg.sender, __hornId);

        emit HornDeliveredAndNFTOwnershipTransferred(__hornId, previousOwner, msg.sender);
        emit SellerPaid(__hornId, previousOwner, msg.sender);
        emit WithdrawnFromEscrow(previousOwner, paymentAmt);

        return paymentAmt;
    }
    
    /*
        Helper functions that provide (internal?) getter functionality
    */

    function getCurrentHornsForSale() public view returns (uint[] memory) {
        // loop through hornForSale[] uint array and display them to frontend to parse via hornId (could also do array of structs)
        // for (i = 0, i < hornsForSale[].length, i++) {
            // hornId = hornsForSale[i].id; // if I go this route i must add an id attribute to the horn structs- is there another way to view hornids of hornsforsale
            // return horns[hornId];
        //}
    }

    function getListPriceByHornId(uint __hornId) public view returns (uint32) {
        return horns[__hornId].listPrice;
    }

    function getCurrentOwnerByMapping(uint __hornId) public view returns (address payable) {
        return currentOwners[__hornId];
    }

    function getCurrentOwnerByStructAttribute(uint __hornId) public view returns (address payable) {
        return horns[__hornId].currentOwner;
    }

    function getStatusOfHornByHornId(uint __hornId) public view returns (HornStatus) {
        return horns[__hornId].status;
    }

    function getEscrowDepositValue(address payee) public view returns (uint) {
        escrow.depositsOf(payee);
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