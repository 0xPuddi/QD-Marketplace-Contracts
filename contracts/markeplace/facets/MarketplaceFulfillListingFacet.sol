// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { LibMarketplaceFulfillListingFacet } from "../libraries/LibMarketplaceFulfillListingFacet.sol";
import { IMarketplaceFulfillListingFacet } from "../interfaces/IMarketplaceFulfillListingFacet.sol";

import { LibReentrancyGuard } from "../../shared/libraries/LibReentrancyGuard.sol";
import { IERC20 } from "../../shared/interfaces/IERC20.sol";

/**
 * @notice Fulfill listing facet
 * 
 * Contains:
 * {fulfillStandardListing}
 * {fulfillTimerListing}
 * {fulfillDutchListing}
 * {bidEnglishListing}
 * {fulfillEnglishListing}
 */
contract MarketplaceFulfillListingFacet is LibReentrancyGuard, IMarketplaceFulfillListingFacet {
    /**
     * @notice Listing structs
     */
    struct BaseListingStruct {
        uint256 grossPayment;
        uint256 royalties;
        uint256 marketplaceFee;
        uint256 payment;
        bool biddingTokensApproval;
    }

    /**
     * @notice Fulfill standard listing
     */
    function fulfillStandardListing(
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint256 amount
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        BaseListingStruct memory baseListingStruct;

        LibMarketplaceStorage.StandardListingStruct memory standardListing = mss.standardListings[token][idToken][requestIndex];

        if (amount == standardListing.quantity || mss.listingTokensApproval721[token]) {
            mss.standardListings[token][idToken][requestIndex] = mss.standardListings[token][idToken][mss.standardListings[token][idToken].length - 1];
            mss.standardListingsIndexes[msg.sender][standardListing.indexListing] = mss.standardListingsIndexes[msg.sender][mss.standardListingsIndexes[msg.sender].length - 1];
            mss.standardListings[token][idToken][requestIndex].indexListing = uint32(standardListing.indexListing);
            mss.standardListingsIndexes[msg.sender][standardListing.indexListing].indexListing = uint64(requestIndex);
            mss.standardListings[token][idToken].pop();
            mss.standardListingsIndexes[msg.sender].pop();

            amount = standardListing.quantity;
            if (mss.listingTokensApproval1155[token]) {
                mss.totAmount[token].totAmountSL1155 -= amount;
            }
        } else {
            mss.standardListings[token][idToken][requestIndex].quantity -= uint64(amount);
            mss.totAmount[token].totAmountSL1155 -= amount;
        }
        

        baseListingStruct.grossPayment = amount * uint256(standardListing.pricePerToken);
        baseListingStruct.biddingTokensApproval = mss.biddingTokensApproval[standardListing.tokenPayment];

        if (standardListing.tokenPayment == address(0) && msg.value < baseListingStruct.grossPayment) revert DepositTooLow();

        baseListingStruct.royalties = LibMarketplaceFulfillListingFacet.royaltiesManager(
            baseListingStruct.grossPayment,
            token,
            idToken,
            msg.sender,
            standardListing.tokenPayment,
            baseListingStruct.biddingTokensApproval
        );

        /**
         * @notice last value is the listing type:
         * 0 == StandardListing,
         * 1 == TimerListing,
         * 2 == DutchListing,
         * 3 == EnglishListing,
         * 4 == SealedBidListing.
         */
        baseListingStruct.marketplaceFee = LibMarketplaceFulfillListingFacet.marketplaceFeeManager(
            baseListingStruct.grossPayment,
            token,
            idToken,
            standardListing.tokenPayment,
            msg.sender,
            baseListingStruct.biddingTokensApproval,
            LibMarketplaceStorage.SellingListingTypes.StandardListing
        );

        baseListingStruct.payment = baseListingStruct.grossPayment - baseListingStruct.royalties - baseListingStruct.marketplaceFee;

        LibMarketplaceFulfillListingFacet.manageTransfers(
            baseListingStruct.payment,
            idToken,
            amount,
            standardListing.tokenPayment,
            standardListing.ownerListing,
            msg.sender,
            false,
            token,
            baseListingStruct.biddingTokensApproval
        );

        emit StandardListingFulfilled(token, idToken, requestIndex);
    }

    /**
     * @notice Fulfill timer listing
     */
    function fulfillTimerListing(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        BaseListingStruct memory baseListingStruct;

        LibMarketplaceStorage.TimerListingStruct memory timerListing = mss.timerListings[token][idToken][requestIndex];

        mss.timerListings[token][idToken][requestIndex] = mss.timerListings[token][idToken][mss.timerListings[token][idToken].length - 1];
        mss.timerListingsIndexes[msg.sender][timerListing.indexListing] = mss.timerListingsIndexes[msg.sender][mss.timerListingsIndexes[msg.sender].length - 1];
        mss.timerListings[token][idToken][requestIndex].indexListing = uint32(timerListing.indexListing);
        mss.timerListingsIndexes[msg.sender][timerListing.indexListing].indexListing = uint64(requestIndex);
        mss.timerListings[token][idToken].pop();
        mss.timerListingsIndexes[msg.sender].pop();

        if (block.timestamp > timerListing.time + timerListing.lifetime) revert ListingExpired(timerListing.time + timerListing.lifetime);

        baseListingStruct.grossPayment = uint256(timerListing.quantity) * uint256(timerListing.pricePerToken);
        baseListingStruct.biddingTokensApproval = mss.biddingTokensApproval[timerListing.tokenPayment];

        if (timerListing.tokenPayment == address(0) && msg.value < baseListingStruct.grossPayment) revert DepositTooLow();

        baseListingStruct.royalties = LibMarketplaceFulfillListingFacet.royaltiesManager(
            baseListingStruct.grossPayment,
            token,
            idToken,
            msg.sender,
            timerListing.tokenPayment,
            baseListingStruct.biddingTokensApproval
        );

        /**
         * @notice last value is the listing type:
         * 0 == StandardListing,
         * 1 == TimerListing,
         * 2 == DutchListing,
         * 3 == EnglishListing,
         * 4 == SealedBidListing.
         */
        baseListingStruct.marketplaceFee = LibMarketplaceFulfillListingFacet.marketplaceFeeManager(
            baseListingStruct.grossPayment,
            token,
            idToken,
            timerListing.tokenPayment,
            msg.sender,
            baseListingStruct.biddingTokensApproval,
            LibMarketplaceStorage.SellingListingTypes.TimerListing
        );

        baseListingStruct.payment = baseListingStruct.grossPayment - baseListingStruct.royalties - baseListingStruct.marketplaceFee;

        LibMarketplaceFulfillListingFacet.manageTransfers(
            baseListingStruct.payment,
            idToken,
            timerListing.quantity,
            timerListing.tokenPayment,
            timerListing.ownerListing,
            msg.sender,
            false,
            token,
            baseListingStruct.biddingTokensApproval
        );

        emit TimerListingFulfilled(token, idToken, requestIndex);
    }

    /**
     * @notice Fulfill dutch listing
     */
    function fulfillDutchListing(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        BaseListingStruct memory baseListingStruct;

        LibMarketplaceStorage.DutchListingStruct memory dutchListing = mss.dutchListings[token][idToken][requestIndex];

        mss.dutchListings[token][idToken][requestIndex] = mss.dutchListings[token][idToken][mss.dutchListings[token][idToken].length - 1];
        mss.dutchListingsIndexes[msg.sender][dutchListing.indexListing] = mss.dutchListingsIndexes[msg.sender][mss.dutchListingsIndexes[msg.sender].length - 1];
        mss.dutchListings[token][idToken][requestIndex].indexListing = uint32(dutchListing.indexListing);
        mss.dutchListingsIndexes[msg.sender][dutchListing.indexListing].indexListing = uint64(requestIndex);
        mss.dutchListings[token][idToken].pop();
        mss.dutchListingsIndexes[msg.sender].pop();

        if (block.timestamp > dutchListing.time + dutchListing.lifetime) revert ListingExpired(dutchListing.time + dutchListing.lifetime);

        baseListingStruct.grossPayment = LibMarketplaceFulfillListingFacet.calculateDutchListingPrice(
            uint256(dutchListing.quantity),
            uint256(dutchListing.pricePerToken),
            uint256(dutchListing.leastPricePerToken),
            uint256(dutchListing.time)
        );
        baseListingStruct.biddingTokensApproval = mss.biddingTokensApproval[dutchListing.tokenPayment];

        if (dutchListing.tokenPayment == address(0) && msg.value < baseListingStruct.grossPayment) revert DepositTooLow();

        baseListingStruct.royalties = LibMarketplaceFulfillListingFacet.royaltiesManager(
            baseListingStruct.grossPayment,
            token,
            idToken,
            msg.sender,
            dutchListing.tokenPayment,
            baseListingStruct.biddingTokensApproval
        );

        /**
         * @notice last value is the listing type:
         * 0 == StandardListing,
         * 1 == TimerListing,
         * 2 == DutchListing,
         * 3 == EnglishListing,
         * 4 == SealedBidListing.
         */
        baseListingStruct.marketplaceFee = LibMarketplaceFulfillListingFacet.marketplaceFeeManager(
            baseListingStruct.grossPayment,
            token,
            idToken,
            dutchListing.tokenPayment,
            msg.sender,
            baseListingStruct.biddingTokensApproval,
            LibMarketplaceStorage.SellingListingTypes.DutchListing
        );

        baseListingStruct.payment = baseListingStruct.grossPayment - baseListingStruct.royalties - baseListingStruct.marketplaceFee;

        LibMarketplaceFulfillListingFacet.manageTransfers(
            baseListingStruct.payment,
            idToken,
            dutchListing.quantity,
            dutchListing.tokenPayment,
            dutchListing.ownerListing,
            msg.sender,
            false,
            token,
            baseListingStruct.biddingTokensApproval
        );

        emit DutchListingFulfilled(token, idToken, requestIndex);
    }
}