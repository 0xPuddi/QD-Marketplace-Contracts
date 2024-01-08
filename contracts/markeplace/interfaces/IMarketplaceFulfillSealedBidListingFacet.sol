// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplaceFulfillSealedBidListingFacet {
    /**
     * @notice Custom errors
     */
    // Revert if listing is expired
    error ListingExpired(uint256 timeExpiry);
    // Revert if listing is not expired
    error ListingNotExpired(uint256 time);
    // Revert is sealed bid hash is incorrect
    error WrongSealedBidHash();
    // Revert if sealer bid bid or place or close time is wrong
    error NotSealedBidBidTime();
    error NotSealedBidPlaceTime();
    error NotSealedBidCloseTime();
    // Revert if amount cap for sealed bid listing is reached
    error BidsCapLimitReached();
    // Revert if floor price is not reached on a sealed bid listing
    error FloorPriceNotReached();
    // Revert if winner is not a participant
    error WinnerNotAParticipant(address winningPlayer);
    // Revert if no bidder is present
    error NoBidders();
    // Revert if not the owner
    error NotTheOwner(address owner);

    /**
     * @notice Events
     */
    // Emit when a sealed bid listing gets fulfilled
    event SealedBidListingFulfilled(address collection, uint256 idToken, uint256 requestIndex);
    // Emit when a sealed bid listing gets bidded, placed or closed
    event SealedBidBidded(address collection, uint256 idToken, uint256 requestIndex);
    event SealedBidPlaced(address collection, uint256 idToken, uint256 requestIndex);
    event SealedBidClosed(address collection, uint256 idToken, uint256 requestIndex);

    /**
     * @notice External functions
     */
}