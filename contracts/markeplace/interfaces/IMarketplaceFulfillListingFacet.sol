// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplaceFulfillListingFacet {
    /**
     * @notice Custom errors
     */
    // Revert if payment isn't matched
    error PaymentNotMatched(uint256 payment, uint256 actualPayment);
    // Revert if token transfer is missing
    error MissingTokenTransfer(address token);
    // Revert if no bidder is present
    error NoBidders();
    // Revert if not the owner
    error NotTheOwner(address owner);
    // Deposit value too low
    error DepositTooLow();
    // Revert if listing is expired
    error ListingExpired(uint256 timeExpiry);

    /**
     * @notice Events
     */
    // Emit when a standard listing gets fulfilled
    event StandardListingFulfilled(address collection, uint256 idToken, uint256 requestIndex);
    // Emit when a timer listing gets fulfilled
    event TimerListingFulfilled(address collection, uint256 idToken, uint256 requestIndex);
    // Emit when a dutch listing gets fulfilled
    event DutchListingFulfilled(address collection, uint256 idToken, uint256 requestIndex);

    /**
     * @notice External functions
     */
}