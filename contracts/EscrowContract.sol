// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// this contract accepts stablecoins (dai, usdc, usdt, gusd) from horn buyers
/// which are securely held until the horn is shipped by seller and subsequently received by buyer
/// at which time funds are released to seller

// probably need an interface for HornMarketplace.sol
interface HornMarketplace {}
// need an interface for the supported ERC20 stablecoins (dai,usdc,usdt,gusd)
interface IERC20 {}

contract Escrow {
    
    // modifier logic to check buyer paid at least the listed price
    modifier paidEnough() {
        // approve and .transferFrom are the erc20 methods to be examined
    }

    // safeguards escrowed funds paid by buyer until buyer receives of horn
    function safelyHoldPaymentFunds() public {
        /// approve and .transferFrom are the erc20 methods to use for stablecoin payment
        // 
    }

    function releasePaymentFunds() public {
        // release escrowed funds to seller upon receipt of horn

    }
}
