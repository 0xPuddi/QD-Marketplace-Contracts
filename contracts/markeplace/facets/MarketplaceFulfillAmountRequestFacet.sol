// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { LibMarketplaceFulfillRequestFacet } from "../libraries/LibMarketplaceFulfillRequestFacet.sol";

import { LibReentrancyGuard } from "../../shared/libraries/LibReentrancyGuard.sol";

/**
 * @notice Marketplace fulfill amount request facet
 * 
 * Contains:
 * {fulfillAmountRequest}
 */
contract MarketplaceFulfillAmountRequestFacet is LibReentrancyGuard {
    // Revert if request is expired
    error RequestExpired(uint256 timeExpiry);
    // Revert if amount request isn't called wit ERC1155
    error AmountRequestNotERC1155(address token);
    // Revert if value deposit is too low
    error DepositTooLow(uint256 valueDeposit);

    // Emit if amount request is fulfilled
    event AmountRequestFulfilled(address offerer, address fulfiller, uint256 requestIndex);

    /**
     * @notice Fulfill amount request
     */
    function fulfillAmountRequest(
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint256 amount
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.AmountRequestStruct memory amountRequest = mss.amountRequests[token][idToken][requestIndex];

        bool isERC1155 = mss.listingTokensApproval1155[token];
        if (!isERC1155) revert AmountRequestNotERC1155(token);

        if (amount == amountRequest.quantity) {
            mss.amountRequests[token][idToken][requestIndex] = mss.amountRequests[token][idToken][mss.amountRequests[token][idToken].length - 1];
            mss.amountRequestsIndexes[amountRequest.owner][amountRequest.indexRequest] = mss.amountRequestsIndexes[amountRequest.owner][mss.amountRequestsIndexes[amountRequest.owner].length - 1];
            mss.amountRequests[token][idToken][requestIndex].indexRequest = uint32(amountRequest.indexRequest);
            mss.amountRequestsIndexes[amountRequest.owner][amountRequest.indexRequest].indexRequest = uint48(requestIndex);
            mss.amountRequests[token][idToken].pop();
            mss.amountRequestsIndexes[amountRequest.owner].pop();
        } else {
            mss.amountRequests[token][idToken][requestIndex].quantity -= uint128(amount);
        }

        if (amountRequest.lifetime != 0 && block.timestamp > amountRequest.time + amountRequest.lifetime) revert RequestExpired(amountRequest.time + amountRequest.lifetime);
        if (mss.totAmount[token].totAmountSL1155 + mss.totAmount[token].totAmountSR1155 < amountRequest.quantity) revert RequestExpired(amountRequest.time + amountRequest.lifetime);

        uint256 grossPayment = uint256(amountRequest.pricePerToken) * amount;

        if (amountRequest.tokenPayment == address(0) && msg.value < grossPayment) revert DepositTooLow(msg.value);
        
        uint256 royalties = LibMarketplaceFulfillRequestFacet.manageRequestsRoyalties(
            token,
            idToken,
            amountRequest.tokenPayment,
            grossPayment
        );
        uint256 marketplaceFee = LibMarketplaceFulfillRequestFacet.manageRequestsMarketplaceFee(
            token,
            idToken,
            amountRequest.tokenPayment,
            grossPayment,
            LibMarketplaceStorage.SellingListingTypes.StandardListing
        );
        uint256 amountRequestDiscount = LibMarketplaceFulfillRequestFacet.manageAmountRequestsDiscount(
            grossPayment - royalties - marketplaceFee,
            uint256(amountRequest.pricePerToken) * uint256(amountRequest.quantity)
        );

        uint256 payment = grossPayment - royalties - marketplaceFee - amountRequestDiscount;

        LibMarketplaceFulfillRequestFacet.manageRequestsTransfers(
            !isERC1155,
            token,
            idToken,
            amount,
            amountRequest.tokenPayment,
            payment,
            amountRequest.owner
        );

        emit AmountRequestFulfilled(amountRequest.owner, msg.sender, requestIndex);
    }
}