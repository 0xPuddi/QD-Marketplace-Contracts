// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplaceListingFacet {
    /**
     * @notice Custom errors
     */
    // Revert if token is not approved
    error TokenNotApproved(address token);
    // Revert if error occurs during token listing
    error TokenListed(address token, uint256 quantity);
    // Revert if use doesn't hold token or tokens aren't enough
    error NotEnoughTokens(uint256 tokenAmount);
    // Revert if user hasn't allowed the contract
    error NotAllowanceFromUser(address user);
    // Revert if time is incorrect
    error IncorrectTime(uint256 time);
    // Reverft if price per token is higher than least price per toen
    error PricePerTokenHigherThanLeastPricePerToken(uint256 pricePerToken, uint256 leastPricePerToken);
    // Revert if additonal bid time is too big
    error OverflowAdditionalBidTime(uint256 additionalBidTime);
    // Revert if there is no time for the auction
    error NoTimeToExecuteAuction(uint256 biddingTime, uint256 placingTime, uint256 closingTime);
    // Revert if cooldown sealed bid is not passed
    error OwnerUnderCoolingTime();

    /**
     * @notice Events
     */
    // Emit if standard listing is created
    event StandardListingCreated(address indexed token, uint256 indexed idToken, uint64 indexListing);
    // Emit if timer listing is created
    event TimerListingCreated(address indexed token, uint256 indexed idToken, uint64 indexListing);
    // Emit if dutch listing is created
    event DutchListingCreated(address indexed token, uint256 indexed idToken, uint64 indexListing);
    // Emit if english listing is created
    event EnglishListingCreated(address indexed token, uint256 indexed idToken, uint64 indexListing);
    // Emit if sealed bid listing is created
    event SealedBidListingCreated(address indexed token, uint256 indexed idToken, uint64 indexListing);

    /**
     * @notice External functions
     */
    // Create standard listing
    function createStandardListing (
        address token,
        uint256 idToken,
        uint32 amountToken,
        uint64 pricePerToken,
        address tokenPayment
        ) external;
    // Create timer listing
    function createTimerListing (
        address token,
        uint256 idToken,
        uint96 lifetime,
        uint128 amountToken,
        uint128 pricePerToken,
        address tokenPayment
        ) external;
    // Create dutch listing
    function createDutchListing (
        address token,
        uint256 idToken,
        uint96 lifetime,
        uint64 amountToken,
        uint96 pricePerToken,
        uint96 leastPricePerToken,
        address tokenPayment
        ) external;
    // Create english listing
    function createEnglishListing (
        address token,
        uint256 idToken,
        uint64 amountToken,
        uint248 initialPricePerToken, 
        bool timeCap,
        address tokenPayment,
        uint40 lifetime,
        uint16 additionalBidTime
        ) external;
    // Create sealed bid listing
    function createSealedBidListing (
        address token,
        uint256 idToken,
        uint96 floorPrice,
        address tokenPayment,
        uint16 amountCapBids,
        uint56 amountToken,
        uint56 biddingTime,
        uint64 placingTime,
        uint64 closingTime
        ) external;
}