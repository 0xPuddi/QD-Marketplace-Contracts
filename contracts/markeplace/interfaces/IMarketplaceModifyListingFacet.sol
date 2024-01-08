// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplaceModifyListingFacet {
    /**
     * @notice Custom errors
     */
    // Revert if it's not the owner
    error NotTheOwner(address owner);
    // Revert if collection or token id differs
    error NotSameCollectionOrId(address collection, uint256 idToken);
    // Revert if lifetime is wrong
    error WrongLifetimeListing(uint96 lifetime);
    // Revert if least price per token is higher than price per token
    error LeastPricePerTokenHigherThanPricePerToken(uint96 pricePerToken, uint96 leastPricePerToken);
    // Revert if listing is not ended
    error ListingNotEnded(uint256 time);
    // Revert if listing has at least one bidder
    error ListingHasAtLeastOneBidder( address bidder);
    // Revert if token payment is not approved
    error TokenNotListed(address tokenPayment);
    // Revert if quantity is 0
    error QuantityInexistent(uint256 quantity);
    // Revert if cooldown sealed bid is not passed
    error OwnerUnderCoolingTime();

    /**
     * @notice Events
     */
    // Emit if standard listing is modified
    event StandardListingModified(address collection, uint256 idToken, uint256 indexRequest);
    // Emit if timer listing is modified
    event TimerListingModified(address collection, uint256 idToken, uint256 indexRequest);
    // Emit if dutch listing is modified
    event DutchListingModified(address collection, uint256 idToken, uint256 indexRequest);
    // Emit if english listing is modified
    event EnglishListingModified(address collection, uint256 idToken, uint256 indexRequest);
    // Emit if sealed bid listing is modified
    event SealedBidListingModified(address collection, uint256 idToken, uint256 indexRequest);

    /**
     * @notice External functions
     */
    // Modify standard listing
    function modifyStandardListing (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint64 quantity,
        uint96 pricePerToken,
        address tokenPayment
    ) external;
    // Modify timer listing
    function modifyTimerListing (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        address tokenPayment,
        uint96 lifetime,
        uint128 quantity,
        uint128 pricePerToken
    ) external;
    // Modify dutch listing
    function modifyDutchListing (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        address tokenPayment,
        uint96 lifetime,
        uint64 quantity,
        uint96 pricePerToken,
        uint96 leastPricePerToken
    ) external;
    // Modify english listing
    function modifyEnglishListing (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint64 quantity,
        uint248 initialPricePerToken,
        bool timeCap,
        address tokenPayment,
        uint40 lifetime,
        uint16 additionalBidTime
    ) external;
    // Modify sealed bid listing
    function modifySealedBidListing (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint96 floorPrice,
        address tokenPayment,
        uint16 amountCapBids,
        uint56 quantity,
        uint56 biddingTime,
        uint64 placingTime,
        uint64 closingTime
    ) external;
}