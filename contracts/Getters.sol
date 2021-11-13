// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./HornMarketplace.sol";

contract Getters is HornMarketplace {

    /*
        Helper functions that provide getter functionality
    */
    // @dev Returns an array of hornId uints that are read by the front end to display Horns listed for sale
//     function getHornById(uint _index) public view returns (Horn memory) {
//         return horns[_index];
//     }

//     function getCurrentHornsForSale() public view returns (uint[] memory) {
//         return hornsForSale;
//     }

//     function getListPriceByHornId(uint __hornId) public view returns (uint) {
//         return horns[__hornId].listPrice; 
//     }

//     function getCurrentOwnerByMapping(uint __hornId) public view returns (address payable) {
//         return payable(currentOwners[__hornId]);
//     }

//     function getCurrentOwnerByStructAttribute(uint __hornId) public view returns (address payable) {
//         return horns[__hornId].currentOwner;
//     }

//     function getStatusOfHornByHornId(uint __hornId) public view returns (HornStatus) {
//         return horns[__hornId].status;
//     }

//     function getEscrowDepositValue(address payee) public view returns (uint) {
//         uint escrowBalance = escrow.depositsOf(payee);
//         return escrowBalance;
//     }

//     function getBalanceOf(address _owner) public view returns (uint) {
//         uint hornBalance = balanceOf(_owner);
//         return hornBalance;
//     }

//     function getApprovedToSpend(uint _tokenId) public view returns (address) {
//         address _approved = getApproved(_tokenId);
//         return _approved;
//     }

//     function getEscrowOwner() public view returns (address) {
//         address escrowOwner = escrow.owner();
//         return escrowOwner;
//     }
}
