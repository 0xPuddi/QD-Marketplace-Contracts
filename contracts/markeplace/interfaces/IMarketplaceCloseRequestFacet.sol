// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplaceCloseRequestFacet {
    /**
     * @notice Custom errors
     */
    // Revert if listing is not yet expired
    error ListingNotExpired(uint256 expiryTime);

    /**
     * @notice Events
     */
    // Emit when a standard request is closed
    event StandardRequestClosed(address token, uint256 idToken, uint256 requestIndex);
    // Emit when a timer request is closed
    event TimerRequestClosed(address token, uint256 idToken, uint256 requestIndex);
    // Emit when an amount request is closed
    event AmountRequestClosed(address token, uint256 idToken, uint256 requestIndex);
    // Emit when an offer is closed
    event OfferClosed(address offeredTo, uint256 requestIndex);

    /**
     * @notice External functions
     */
}