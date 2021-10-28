// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// this contract accepts ETH (later stablecoins (dai, usdc, usdt, gusd)) from horn buyers
/// which are securely held until the horn is shipped by seller and subsequently received by buyer
/// at which time funds are released to seller
/// MUST IMPLEMENT REFUNDABLE FUNCTIONALITY
// @notice Safeguards escrowed funds paid by buyer until buyer receives instrument
import "@openzeppelin/contracts/utils/escrow/Escrow.sol";

interface HornMarketplace {}
/* If accepting stablecoins in future, need an interface for the supported ERC20 stablecoins (dai,usdc,usdt,gusd)
  interface IERC20 {} // maybe convert eth to stables at time of tx? 
*/

contract EscrowContract is Escrow {
    
    // @dev Target the HornMarketplace contract
    // HornMarketplace hornMarketplace = HornMarketplace(DEVELOPMENT_DEPLOYED_MARKETPLACE_HERE);
    // HornMarketplace hornMarketplace = HornMarketplace(RINKEBY_DEPLOYED_MARKETPLACE_HERE);
        /// approve and .transferFrom are the erc20 methods to use for stablecoin payment

}
