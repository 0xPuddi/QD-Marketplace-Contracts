// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IMarketplaceFulfillRequestFacet {
    /**
     * @notice Custom errors
     */
    // Revert if request is expired
    error RequestExpired(uint256 timeExpiry);
    // Revert if value deposit is too low
    error DepositTooLow(uint256 valueDeposit);

    /**
     * @notice Events
     */
    // Emit if standard request is fulfilled
    event StandardRequestFulfilled(address offerer, address fulfiller, uint256 requestIndex);
    // Emit if timer request is fulfilled
    event TimerRequestFulfilled(address offerer, address fulfiller, uint256 requestIndex);
    // Emit if dutch request is fulfilled
    event DutchRequestFulfilled(address offerer, address fulfiller, uint256 requestIndex);

    /**
     * @notice External functions
     */
}