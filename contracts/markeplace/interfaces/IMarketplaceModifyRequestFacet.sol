// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplaceModifyRequestFacet {
    /**
     * @notice Custom errors
     */
    // Revert if it's not the owner
    error NotTheOwner(address owner);
    // Revert if request token is not the same
    error DifferentPaymentToken(address paymentToken);
    // Revert if request is not expired
    error RequestNotExpired(uint256 timeRemaining);
    // Revert if time is incorrect
    error IncorrectTime(uint96 time);
    // Revert if amount request isn't liquid enough
    error AmountRequestIsNotLiquidEnough(address token, uint256 quantityNeeded, uint128 quantity);
    // Revert if least price per token is higher than price per token
    error LeastPricePerTokenHigherThanPricePerToken(uint112 pricePerToken, uint112 leastPricePerToken);
    // Revert if deposit fails
    error DepositFailed(address tokenPayment, uint256 newDeposit, uint256 oldDeposit);

    /**
     * @notice Events
     */
    // Emit when a standard request is modified
    event StandardRequestModified(address indexed token, uint256 indexed idToken, uint256 indexRequest);
    // Emit when a timer request is created
    event TimerRequestModified(address indexed token, uint256 indexed idToken, uint256 indexRequest);
    // Emit when a dutch request is created
    event DutchRequestModified(address indexed token, uint256 indexed idToken, uint256 indexRequest);
    // Emit when an amount request is created
    event AmountRequestModified(address indexed token, uint256 indexed idToken, uint256 indexRequest);
    // Emit when an offer is created
    event OfferModified(address indexed from, address indexed to, uint256 indexRequest);

    /**
     * @notice External functions
     */
    // Modify standard request
    function modifyStandardRequest (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint64 quantity,
        address tokenPayment,
        uint96 pricePerToken
    ) external payable;
    // Modify timer request
    function modifyTimerRequest (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint80 quantity,
        address tokenPayment,
        uint176 pricePerToken,
        uint96 lifetime
    ) external payable;
    // Modify dutch request
    function modifyDutchRequest (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint96 quantity,
        address tokenPayment,
        uint32 lifetime,
        uint112 pricePerToken,
        uint112 leastPricePerToken
    ) external payable;
    // Modify amount request
    function modifyAmountRequest (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint128 quantity,
        address tokenPayment,
        uint96 lifetime,
        uint128 pricePerToken
    ) external payable;
    // Modify offer
    function modifyOffer (
        address userOffered,
        uint256 requestIndex,
        address tokenPayment,
        uint96 quantity,
        uint176 pricePerToken,
        uint40 lifetime
    ) external payable;
}