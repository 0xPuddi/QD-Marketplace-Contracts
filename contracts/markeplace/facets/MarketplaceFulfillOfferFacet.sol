// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { LibMarketplaceFulfillRequestFacet } from "../libraries/LibMarketplaceFulfillRequestFacet.sol";

/**
 * @notice Marketplace fulfill offer facet
 * 
 * Contains:
 * {fulfillOffer}
 */
contract MarketplaceFulfillOfferFacet {
    // Revert if request is expired
    error RequestExpired(uint256 timeExpiry);
    // Revert if value deposit is too low
    error DepositTooLow(uint256 valueDeposit);

    // Emit if offer is fulfilled
    event OfferFulfilled(address offerer, address fulfiller, uint256 requestIndex);

    /**
     * @notice Fulfill offer
     */
    function fulfillOffer(
        address offerer,
        uint256 requestIndex
    ) external payable {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.OfferStruct memory offerStruct = mss.Offer[offerer][msg.sender][requestIndex];

        bool isERC721 = mss.listingTokensApproval721[offerStruct.addressToken];

        mss.Offer[offerer][msg.sender][requestIndex] = mss.Offer[offerer][msg.sender][mss.Offer[offerer][msg.sender].length - 1];
        mss.offersIndexes[offerStruct.addressToken][offerStruct.indexOffer] = mss.offersIndexes[offerStruct.addressToken][mss.offersIndexes[offerStruct.addressToken].length - 1];
        mss.Offer[offerer][msg.sender][requestIndex].indexOffer = uint32(offerStruct.indexOffer);
        mss.offersIndexes[offerStruct.addressToken][offerStruct.indexOffer].offerIndex = uint64(requestIndex);
        mss.Offer[offerer][msg.sender].pop();
        mss.offersIndexes[offerStruct.addressToken].pop();

        if (offerStruct.lifetime != 0 && block.timestamp > offerStruct.time + offerStruct.lifetime) revert RequestExpired(offerStruct.time + offerStruct.lifetime);

        uint256 grossPayment = uint256(offerStruct.pricePerToken) * uint256(offerStruct.quantity);

        if (offerStruct.tokenPayment == address(0) && msg.value < grossPayment) revert DepositTooLow(msg.value);
        
        uint256 royalties = LibMarketplaceFulfillRequestFacet.manageRequestsRoyalties(
            offerStruct.addressToken,
            offerStruct.idToken,
            offerStruct.tokenPayment,
            grossPayment
        );
        uint256 marketplaceFee = LibMarketplaceFulfillRequestFacet.manageRequestsMarketplaceFee(
            offerStruct.addressToken,
            offerStruct.idToken,
            offerStruct.tokenPayment,
            grossPayment,
            LibMarketplaceStorage.SellingListingTypes.StandardListing
        );

        uint256 payment = grossPayment - royalties - marketplaceFee;

        LibMarketplaceFulfillRequestFacet.manageRequestsTransfers(
            isERC721,
            offerStruct.addressToken,
            offerStruct.idToken,
            offerStruct.quantity,
            offerStruct.tokenPayment,
            payment,
            offerer
        );

        emit OfferFulfilled(offerer, msg.sender, requestIndex);
    }
}