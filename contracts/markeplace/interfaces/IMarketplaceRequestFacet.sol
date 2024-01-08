// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplaceRequestFacet {
    /**
     * @notice Custom errors
     */
    // Revert if token is not approved
    error TokenNotApproved(address token);
    // Revert if value deposited is not enough
    error ValueDepositedInsufficient(uint256 deposit);
    // Revert if time is incorrect
    error IncorrectTime(uint96 time);
    // Revert if amount request isn't liquid enough
    error AmountRequestIsNotLiquidEnough(address token, uint256 quantityNeeded, uint128 quantity);
    // Revert if it's not the owner
    error NotTheOwner(address owner);
    // Revert if request token is not the same
    error DifferentPaymentToken(address paymentToken);
    // Revert if request is not expired
    error RequestNotExpired(uint256 timeRemaining);
    // Revert if least price per token is higher than price per token
    error LeastPricePerTokenHigherThanPricePerToken(uint112 pricePerToken, uint112 leastPricePerToken);
    // Revert if offer collection is different
    error DifferentCollection(address tokenCollection);
    // Revert if offer collection ID is different
    error DifferentCollectionID(uint96 collectionID);

    /**
     * @notice Events
     */
    // Emit when a standard request is created
    event StandardRequestCreated(address indexed token, uint256 indexed idToken, uint48 indexRequest);
    // Emit when a timer request is created
    event TimerRequestCreated(address indexed token, uint256 indexed idToken, uint48 indexRequest);
    // Emit when a dutch request is created
    event DutchRequestCreated(address indexed token, uint256 indexed idToken, uint48 indexRequest);
    // Emit when an amount request is created
    event AmountRequestCreated(address indexed token, uint256 indexed idToken, uint48 indexRequest);
    // Emit when an offer is created
    event OfferCreated(address indexed from, address indexed to, uint96 indexRequest);

    /**
     * @notice External functions
     */
    // Create a standard request
    function createStandardRequest (
        address token,
        uint256 idToken,
        uint64 quantity,
        address tokenPayment,
        uint96 pricePerToken
    ) external payable;
    // Create a timer request
    function createTimerRequest (
        address token,
        uint256 idToken,
        uint80 quantity,
        address tokenPayment,
        uint176 pricePerToken,
        uint96 lifetime
    ) external payable;
    // Create a dutch request
    function createDutchRequest (
        address token,
        uint256 idToken,
        uint96 quantity,
        address tokenPayment,
        uint32 lifetime,
        uint112 pricePerToken,
        uint112 leastPricePerToken
    ) external payable;
    // Create an amount request
    function createAmountRequest (
        address token,
        uint256 idToken,
        uint128 quantity,
        address tokenPayment,
        uint96 lifetime,
        uint128 pricePerToken
    ) external payable;
    // Make an offer
    function createOffer (
        address userOffered,
        address token,
        address tokenPayment,
        uint64 idToken,
        uint96 quantity,
        uint176 pricePerToken,
        uint40 lifetime
    ) external payable;
}