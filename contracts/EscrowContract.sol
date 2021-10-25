// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// this contract accepts stablecoins (dai, usdc, usdt, gusd) from horn buyers
/// which are securely held until the horn is shipped by seller and subsequently received by buyer
/// at which time funds are released to seller

import "@openzeppelin-contracts/contracts/utils/escrow/ConditionalEscrow.sol";


// probably need an interface for HornMarketplace.sol
interface HornMarketplace {}
/* If accepting stablecoins in future, need an interface for the supported ERC20 stablecoins (dai,usdc,usdt,gusd)
  interface IERC20 {} // maybe convert eth to stables at time of tx? 
*/

contract Escrow is ConditionalEscrow {
    
    // @dev Target the HornMarketplace contract
    // HornMarketplace hornMarketplace = HornMarketplace(DEVELOPMENT_DEPLOYED_MARKETPLACE_HERE);
    // HornMarketplace hornMarketplace = HornMarketplace(RINKEBY_DEPLOYED_MARKETPLACE_HERE);

    // @dev Modifier logic to check buyer paid exactly the listed price ** moved to hornmarketplace.sol, delete when done
    // modifier hornPaidFor() {
        /// approve and .transferFrom are the erc20 methods to be examined

        // require(msg.value == hornMarketplace.HORNPRICEGETTERFUNCTIONHERE())
        _;
    }

    // safeguards escrowed funds paid by buyer until buyer receives of horn
    function safelyHoldPaymentFunds() public payable paidEnough() {
        /// approve and .transferFrom are the erc20 methods to use for stablecoin payment
        // call marketplace contract ?
    }

    function releasePaymentFunds() public {
        // release escrowed funds to seller upon receipt of horn

    }
}
