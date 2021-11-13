// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface hornMarketplace {
        function mintThenListNewHornNFT(string calldata _make, string calldata _model, string calldata _style, uint _serialNumber, uint _listPrice) external returns (uint);
        function mintButDontListNewHornNFT(string calldata _make, string calldata _model, string calldata _style, uint _serialNumber) external returns (uint);
    }

contract Seller {

    hornMarketplace _market; // store marketplace contract address for low level calls
    uint serialNumberCounter;
    uint _defaultListPrice;

    // @param Constructor parameter _mkt passed in by the HornMarketplace_test contract that instantiates this one
    constructor() public { // in morning delete this constructor parameter and use deployed address of market
        serialNumberCounter = 1;
        _defaultListPrice = 420;
    }


    function mintThenListTestHornNFT(address _mkt) public returns (uint) {
        _market = hornMarketplace(_mkt);
        _market.mintThenListNewHornNFT(
            "Berg", 
            "Double", 
            "Geyer", 
            serialNumberCounter, 
            _defaultListPrice
            );

        uint currentHornId = serialNumberCounter;
        serialNumberCounter++;
        return currentHornId;
    }

    function mintDontListTestHornNFT(address _mkt) public returns (uint) {
        _market = hornMarketplace(_mkt);
        _market.mintButDontListNewHornNFT(
            "Berg",
            "Double",
            "Geyer", 
            serialNumberCounter
        );
        uint currentHornId = serialNumberCounter;
        serialNumberCounter++;
        return currentHornId;
    }
}
