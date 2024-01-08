// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IMarketplaceCloseListingFacet {
    /**
     * @notice Custom errors
     */
    // Revert if listing is not expired
    error ListingNotExpired(uint256 expiryTime);
    // Revert if listing has any bidders
    error ListingHasBidders(uint256 biddersNumber);
    // revert if is not the owner
    error NotTheListingOwner(address owner);

    /**
     * @notice Events
     */
    // Emit when standard listing is closed
    event StandardListingClosed(address token, uint256 idToken, uint256 requestIndex);
    // Emit when timer listing is closed
    event TimerListingClosed(address token, uint256 idToken, uint256 requestIndex);
    // Emit when dutch listing is closed
    event DutchListingClosed(address token, uint256 idToken, uint256 requestIndex);
    // Emit when english listing is closed
    event EnglishListingClosed(address token, uint256 idToken, uint256 requestIndex);

    /**
     * @notice External functions
     */
}