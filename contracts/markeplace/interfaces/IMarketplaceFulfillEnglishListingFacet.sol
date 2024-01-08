// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplaceFulfillEnglishListingFacet {
    /**
     * @notice Custom errors
     */
    // Revert if listing is expired
    error ListingExpired(uint256 timeExpiry);
    // Revert if listing is not expired
    error ListingNotExpired(uint256 time);
    // Revert if english bid is not enough
    error EnglishBidTooLow(uint256 bid);
    // Revert if no bidder is present
    error NoBidders();
    // Revert if not the owner
    error NotTheOwner(address owner);

    /**
     * @notice Events
     */
    // Emit when a english listing gets fulfilled
    event EnglishListingFulfilled(address collection, uint256 idToken, uint256 requestIndex);
    // Emit when a english listing gets a bid
    event EnglishBidPlaced(address collection, uint256 idToken, uint256 requestIndex);

    /**
     * @notice External functions
     */
}