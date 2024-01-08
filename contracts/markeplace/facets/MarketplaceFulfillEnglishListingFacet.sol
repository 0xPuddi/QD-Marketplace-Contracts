// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { LibMarketplaceFulfillListingFacet } from "../libraries/LibMarketplaceFulfillListingFacet.sol";
import { IMarketplaceFulfillEnglishListingFacet } from "../interfaces/IMarketplaceFulfillEnglishListingFacet.sol";

import { LibReentrancyGuard } from "../../shared/libraries/LibReentrancyGuard.sol";
import { IERC20 } from "../../shared/interfaces/IERC20.sol";

/**
 * @notice
 * 
 * Contains:
 * {bidEnglishListing}
 * {fulfillEnglishListing}
 */
contract MarketplaceFulfillEnglishListingFacet is LibReentrancyGuard, IMarketplaceFulfillEnglishListingFacet {
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
     * @notice Fulfill english listing
     * {bidEnglishListing}
     * {fulfillEnglishListing}
     */
    struct BaseEnglishListingStruct {
        uint256 addBidsTime;
        uint256 actualTime;
    }
    function bidEnglishListing(
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint256 bidPerToken
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        BaseEnglishListingStruct memory baseEnglishListingStruct;

        LibMarketplaceStorage.EnglishListingStruct memory englishListing = mss.englishListings[token][idToken][requestIndex];

        baseEnglishListingStruct.addBidsTime = englishListing.bidsCounter * englishListing.additionalBidTime;
        baseEnglishListingStruct.actualTime = block.timestamp - baseEnglishListingStruct.addBidsTime;
        if (englishListing.timeCap && baseEnglishListingStruct.actualTime < englishListing.time) {
            baseEnglishListingStruct.actualTime = englishListing.time;
        }
        if (baseEnglishListingStruct.actualTime > englishListing.time + englishListing.lifetime) revert ListingExpired(englishListing.time + englishListing.lifetime + baseEnglishListingStruct.addBidsTime);

        uint256 deposit = bidPerToken * englishListing.quantity;
        uint256 minEnglishListingBidAmountIncrease = mss.minEnglishListingBidAmountIncrease;
        if (englishListing.addressHighestBidder == address(0)) {
            if (englishListing.initialPricePerToken + minEnglishListingBidAmountIncrease <= deposit) {
                if (englishListing.tokenPayment == address(0)) {
                    require(msg.value >= deposit, 'DEPOSIT_TOO_LOW');
                } else {
                    IERC20(englishListing.tokenPayment).transferFrom(msg.sender, address(this), deposit);
                }
            } else {
                revert EnglishBidTooLow(englishListing.initialPricePerToken + minEnglishListingBidAmountIncrease);
            }
        } else {
            if (englishListing.pricePerTokenHighestBidder + minEnglishListingBidAmountIncrease <= deposit) {
                if (englishListing.tokenPayment == address(0)) {
                    require(msg.value >= deposit, 'DEPOSIT_TOO_LOW');
                    (bool success, ) = englishListing.addressHighestBidder.call{value: englishListing.pricePerTokenHighestBidder * englishListing.quantity}("");
                    require(success, "Transfer failed.");
                } else {
                    IERC20(englishListing.tokenPayment).transferFrom(msg.sender, address(this), deposit);
                    IERC20(englishListing.tokenPayment).transferFrom(address(this), englishListing.addressHighestBidder, englishListing.pricePerTokenHighestBidder * englishListing.quantity);
                }
            } else {
                revert EnglishBidTooLow(englishListing.initialPricePerToken + minEnglishListingBidAmountIncrease);
            }
        }

        englishListing.pricePerTokenHighestBidder = uint80(deposit / englishListing.quantity);
        englishListing.addressHighestBidder = msg.sender;
        englishListing.bidsCounter += 1;

        mss.englishListings[token][idToken][requestIndex] = englishListing;

        emit EnglishBidPlaced(token, idToken, requestIndex);
    }
    function fulfillEnglishListing(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        BaseListingStruct memory baseListingStruct;
        BaseEnglishListingStruct memory baseEnglishListingStruct;

        LibMarketplaceStorage.EnglishListingStruct memory englishListing = mss.englishListings[token][idToken][requestIndex];
        
        mss.englishListings[token][idToken][requestIndex] = mss.englishListings[token][idToken][mss.englishListings[token][idToken].length - 1];
        mss.englishListingsIndexes[msg.sender][englishListing.indexListing] = mss.englishListingsIndexes[msg.sender][mss.englishListingsIndexes[msg.sender].length - 1];
        mss.englishListings[token][idToken][requestIndex].indexListing = uint32(englishListing.indexListing);
        mss.englishListingsIndexes[msg.sender][englishListing.indexListing].indexListing = uint64(requestIndex);
        mss.englishListings[token][idToken].pop();
        mss.englishListingsIndexes[msg.sender].pop();

        if (msg.sender != englishListing.ownerListing && msg.sender != englishListing.addressHighestBidder) revert NotTheOwner(englishListing.ownerListing);

        baseEnglishListingStruct.addBidsTime = englishListing.bidsCounter * englishListing.additionalBidTime;
        baseEnglishListingStruct.actualTime = block.timestamp - baseEnglishListingStruct.addBidsTime;
        if (englishListing.timeCap && baseEnglishListingStruct.actualTime < englishListing.time) {
            baseEnglishListingStruct.actualTime = englishListing.time;
        }
        if (baseEnglishListingStruct.actualTime < englishListing.time + englishListing.lifetime) revert ListingNotExpired(englishListing.time + englishListing.lifetime + baseEnglishListingStruct.addBidsTime);

        if (englishListing.addressHighestBidder == address(0)) {
            revert NoBidders();
        }

        baseListingStruct.grossPayment = uint256(englishListing.quantity) * uint256(englishListing.pricePerTokenHighestBidder);
        baseListingStruct.biddingTokensApproval = mss.biddingTokensApproval[englishListing.tokenPayment];

        baseListingStruct.royalties = LibMarketplaceFulfillListingFacet.royaltiesManager(
            baseListingStruct.grossPayment,
            token,
            idToken,
            address(this),
            englishListing.tokenPayment,
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
            englishListing.tokenPayment,
            address(this),
            baseListingStruct.biddingTokensApproval,
            LibMarketplaceStorage.SellingListingTypes.EnglishListing
        );

        baseListingStruct.payment = baseListingStruct.grossPayment - baseListingStruct.royalties - baseListingStruct.marketplaceFee;

        LibMarketplaceFulfillListingFacet.manageTransfers(
            baseListingStruct.payment,
            idToken,
            englishListing.quantity,
            englishListing.tokenPayment,
            englishListing.ownerListing,
            englishListing.addressHighestBidder,
            true,
            token,
            baseListingStruct.biddingTokensApproval
        );

        emit EnglishListingFulfilled(token, idToken, requestIndex);
    }
}