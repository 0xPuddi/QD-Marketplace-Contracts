// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { IMarketplaceFulfillRequestFacet } from "../interfaces/IMarketplaceFulfillRequestFacet.sol";
import { LibMarketplaceFulfillRequestFacet } from "../libraries/LibMarketplaceFulfillRequestFacet.sol";
import { LibMarketplaceFulfillListingFacet } from "../libraries/LibMarketplaceFulfillListingFacet.sol";

import { LibReentrancyGuard } from "../../shared/libraries/LibReentrancyGuard.sol";

/**
 * @notice Marketplace fulfill request facet
 * 
 * Contains:
 * {fulfillStandardRequest}
 * {fulfillTimerRequest}
 * {fulfillDutchRequest}
 */
contract MarketplaceFulfillRequestFacet is LibReentrancyGuard, IMarketplaceFulfillRequestFacet {
    /**
     * @notice Fulfill standard request
     */
    function fulfillStandardRequest(
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint256 amount
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.StandardRequestStruct memory standardRequest = mss.standardRequests[token][idToken][requestIndex];

        bool isERC721 = mss.listingTokensApproval721[token];

        if (amount == standardRequest.quantity || isERC721) {
            mss.standardRequests[token][idToken][requestIndex] = mss.standardRequests[token][idToken][mss.standardRequests[token][idToken].length - 1];
            mss.standardRequestsIndexes[standardRequest.owner][standardRequest.indexRequest] = mss.standardRequestsIndexes[standardRequest.owner][mss.standardRequestsIndexes[standardRequest.owner].length - 1];
            mss.standardRequests[token][idToken][requestIndex].indexRequest = uint32(standardRequest.indexRequest);
            mss.standardRequestsIndexes[standardRequest.owner][standardRequest.indexRequest].indexRequest = uint48(requestIndex);
            mss.standardRequests[token][idToken].pop();
            mss.standardRequestsIndexes[standardRequest.owner].pop();

            amount = standardRequest.quantity;
        } else {
            mss.standardRequests[token][idToken][requestIndex].quantity -= uint64(amount);
        }

        uint256 grossPayment = uint256(standardRequest.pricePerToken) * uint256(amount);

        if (standardRequest.tokenPayment == address(0) && msg.value < grossPayment) revert DepositTooLow(msg.value);
        
        uint256 royalties = LibMarketplaceFulfillRequestFacet.manageRequestsRoyalties(
            token,
            idToken,
            standardRequest.tokenPayment,
            grossPayment
        );
        uint256 marketplaceFee = LibMarketplaceFulfillRequestFacet.manageRequestsMarketplaceFee(
            token,
            idToken,
            standardRequest.tokenPayment,
            grossPayment,
            LibMarketplaceStorage.SellingListingTypes.StandardListing
        );

        uint256 payment = grossPayment - royalties - marketplaceFee;

        LibMarketplaceFulfillRequestFacet.manageRequestsTransfers(
            isERC721,
            token,
            idToken,
            amount,
            standardRequest.tokenPayment,
            payment,
            standardRequest.owner
        );

        emit StandardRequestFulfilled(standardRequest.owner, msg.sender, requestIndex);
    }

    /**
     * @notice Fulfill timer request
     */
    function fulfillTimerRequest(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.TimerRequestStruct memory timerRequest = mss.timerRequests[token][idToken][requestIndex];

        bool isERC721 = mss.listingTokensApproval721[token];

        mss.timerRequests[token][idToken][requestIndex] = mss.timerRequests[token][idToken][mss.timerRequests[token][idToken].length - 1];
        mss.timerRequestsIndexes[timerRequest.owner][timerRequest.indexRequest] = mss.timerRequestsIndexes[timerRequest.owner][mss.timerRequestsIndexes[timerRequest.owner].length - 1];
        mss.timerRequests[token][idToken][requestIndex].indexRequest = uint32(timerRequest.indexRequest);
        mss.timerRequestsIndexes[timerRequest.owner][timerRequest.indexRequest].indexRequest = uint48(requestIndex);
        mss.timerRequests[token][idToken].pop();
        mss.timerRequestsIndexes[timerRequest.owner].pop();

        if (block.timestamp > timerRequest.time + timerRequest.lifetime) revert RequestExpired(timerRequest.time + timerRequest.lifetime);

        uint256 grossPayment = uint256(timerRequest.pricePerToken) * uint256(timerRequest.quantity);

        if (timerRequest.tokenPayment == address(0) && msg.value < grossPayment) revert DepositTooLow(msg.value);
        
        uint256 royalties = LibMarketplaceFulfillRequestFacet.manageRequestsRoyalties(
            token,
            idToken,
            timerRequest.tokenPayment,
            grossPayment
        );
        uint256 marketplaceFee = LibMarketplaceFulfillRequestFacet.manageRequestsMarketplaceFee(
            token,
            idToken,
            timerRequest.tokenPayment,
            grossPayment,
            LibMarketplaceStorage.SellingListingTypes.TimerListing
        );

        uint256 payment = grossPayment - royalties - marketplaceFee;

        LibMarketplaceFulfillRequestFacet.manageRequestsTransfers(
            isERC721,
            token,
            idToken,
            timerRequest.quantity,
            timerRequest.tokenPayment,
            payment,
            timerRequest.owner
        );

        emit TimerRequestFulfilled(timerRequest.owner, msg.sender, requestIndex);
    }

    /**
     * @notice Fulfill dutch request
     */
    function fulfillDutchRequest(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.DutchRequestStruct memory dutchRequest = mss.dutchRequests[token][idToken][requestIndex];

        bool isERC721 = mss.listingTokensApproval721[token];

        mss.dutchRequests[token][idToken][requestIndex] = mss.dutchRequests[token][idToken][mss.dutchRequests[token][idToken].length - 1];
        mss.dutchRequestsIndexes[dutchRequest.owner][dutchRequest.indexRequest] = mss.dutchRequestsIndexes[dutchRequest.owner][mss.dutchRequestsIndexes[dutchRequest.owner].length - 1];
        mss.dutchRequests[token][idToken][requestIndex].indexRequest = uint32(dutchRequest.indexRequest);
        mss.dutchRequestsIndexes[dutchRequest.owner][dutchRequest.indexRequest].indexRequest = uint48(requestIndex);
        mss.dutchRequests[token][idToken].pop();
        mss.dutchRequestsIndexes[dutchRequest.owner].pop();

        if (block.timestamp > dutchRequest.time + dutchRequest.lifetime) revert RequestExpired(dutchRequest.time + dutchRequest.lifetime);

        uint256 dutchPricePerToken = LibMarketplaceFulfillListingFacet.calculateDutchListingPrice(
            dutchRequest.quantity,
            dutchRequest.pricePerToken,
            dutchRequest.leastPricePerToken,
            dutchRequest.time
        );

        uint256 grossPayment = dutchPricePerToken * uint256(dutchRequest.quantity);

        if (dutchRequest.tokenPayment == address(0) && msg.value < grossPayment) revert DepositTooLow(msg.value);
        
        uint256 royalties = LibMarketplaceFulfillRequestFacet.manageRequestsRoyalties(
            token,
            idToken,
            dutchRequest.tokenPayment,
            grossPayment
        );
        uint256 marketplaceFee = LibMarketplaceFulfillRequestFacet.manageRequestsMarketplaceFee(
            token,
            idToken,
            dutchRequest.tokenPayment,
            grossPayment,
            LibMarketplaceStorage.SellingListingTypes.DutchListing
        );

        uint256 payment = grossPayment - royalties - marketplaceFee;

        LibMarketplaceFulfillRequestFacet.manageRequestsTransfers(
            isERC721,
            token,
            idToken,
            dutchRequest.quantity,
            dutchRequest.tokenPayment,
            payment,
            dutchRequest.owner
        );

        emit DutchRequestFulfilled(dutchRequest.owner, msg.sender, requestIndex);
    }
}