// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { IMarketplaceModifyListingFacet } from "../interfaces/IMarketplaceModifyListingFacet.sol";
import { LibMarketplaceModifyListingFacet } from "../libraries/LibMarketplaceModifyListingFacet.sol";

import { LibReentrancyGuard } from "../../shared/libraries/LibReentrancyGuard.sol";

/**
 * @dev Merketplace modify listings
 * To override and modify an already created listing use the related modify function. Standard
 * requests can be modified at any time, while timer and dutch requests only after expiring. English
 * and sealed bids requests can be modified at any time if bidders are 0.
 * 
 * Contains:
 * {modifyStandardListing}
 * {modifyTimerListing}
 * {modifyDutchListing}
 * {modifyEnglishListing}
 * {modifySealedBidListing}
 */
contract MarketplaceModifyListingFacet is LibReentrancyGuard, IMarketplaceModifyListingFacet {
    /**
     * @notice Modify a standard listing
     */
    function modifyStandardListing (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint64 quantity,
        uint96 pricePerToken,
        address tokenPayment
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.StandardListingStruct memory standardListing = mss.standardListings[token][idToken][requestIndex];

        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotListed(tokenPayment);
        if (msg.sender != standardListing.ownerListing) revert NotTheOwner(msg.sender);
        if (quantity == 0) revert QuantityInexistent(0);

        if (standardListing.quantity != quantity) {
            LibMarketplaceModifyListingFacet.manageListingDeposit(token, idToken, standardListing.quantity, quantity);
        }

        standardListing.quantity = quantity;
        standardListing.pricePerToken = pricePerToken;
        standardListing.tokenPayment = tokenPayment;

        mss.standardListings[token][idToken][requestIndex] = standardListing;

        emit StandardListingModified(token, idToken, requestIndex);
    }

    /**
     * @notice Modify a timer listing
     */
    function modifyTimerListing (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        address tokenPayment,
        uint96 lifetime,
        uint128 quantity,
        uint128 pricePerToken
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.TimerListingStruct memory timerListing = mss.timerListings[token][idToken][requestIndex];

        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotListed(tokenPayment);
        if (block.timestamp < timerListing.time + timerListing.lifetime) revert ListingNotEnded(block.timestamp);
        if (msg.sender != timerListing.ownerListing) revert NotTheOwner(msg.sender);
        if (quantity == 0) revert QuantityInexistent(0);
        if (lifetime == 0) revert WrongLifetimeListing(lifetime);

        if (timerListing.quantity != quantity) {
            LibMarketplaceModifyListingFacet.manageListingDeposit(token, idToken, uint96(timerListing.quantity), uint96(quantity));
        }

        timerListing.quantity = quantity;
        timerListing.pricePerToken = pricePerToken;
        timerListing.tokenPayment = tokenPayment;
        timerListing.time = uint64(block.timestamp);
        timerListing.lifetime = lifetime;

        mss.timerListings[token][idToken][requestIndex] = timerListing;

        emit TimerListingModified(token, idToken, requestIndex);
    }

    /**
     * @notice Modify a dutch listing
     */
    function modifyDutchListing (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        address tokenPayment,
        uint96 lifetime,
        uint64 quantity,
        uint96 pricePerToken,
        uint96 leastPricePerToken
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.DutchListingStruct memory dutchListing = mss.dutchListings[token][idToken][requestIndex];

        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotListed(tokenPayment);
        if (block.timestamp < dutchListing.time + dutchListing.lifetime) revert ListingNotEnded(block.timestamp);
        if (msg.sender != dutchListing.ownerListing) revert NotTheOwner(msg.sender);
        if (quantity == 0) revert QuantityInexistent(0);
        if (lifetime == 0) revert WrongLifetimeListing(lifetime);
        if (pricePerToken <= leastPricePerToken) revert LeastPricePerTokenHigherThanPricePerToken(pricePerToken, leastPricePerToken);

        if (dutchListing.quantity != quantity) {
            LibMarketplaceModifyListingFacet.manageListingDeposit(token, idToken, uint96(dutchListing.quantity), uint96(quantity));
        }

        dutchListing.quantity = quantity;
        dutchListing.pricePerToken = pricePerToken;
        dutchListing.leastPricePerToken = leastPricePerToken;
        dutchListing.tokenPayment = tokenPayment;
        dutchListing.time = uint64(block.timestamp);
        dutchListing.lifetime = lifetime;

        mss.dutchListings[token][idToken][requestIndex] = dutchListing;

        emit DutchListingModified(token, idToken, requestIndex);
    }

    /**
     * @notice Modify an english listing
     */
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
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.EnglishListingStruct memory englishListing = mss.englishListings[token][idToken][requestIndex];

        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotListed(tokenPayment);
        if (msg.sender != englishListing.ownerListing) revert NotTheOwner(msg.sender);
        if (quantity == 0) revert QuantityInexistent(0);
        if (block.timestamp < englishListing.time + englishListing.lifetime) revert ListingNotEnded(block.timestamp);
        if (lifetime == 0) revert WrongLifetimeListing(lifetime);
        if (englishListing.addressHighestBidder != address(0)) revert ListingHasAtLeastOneBidder(englishListing.addressHighestBidder);

        if (englishListing.quantity != quantity) {
            LibMarketplaceModifyListingFacet.manageListingDeposit(token, idToken, englishListing.quantity, quantity);
        }

        englishListing.quantity = quantity;
        englishListing.initialPricePerToken = initialPricePerToken;
        englishListing.timeCap = timeCap;
        englishListing.tokenPayment = tokenPayment;
        englishListing.additionalBidTime = additionalBidTime;
        englishListing.time = uint40(block.timestamp);
        englishListing.lifetime = lifetime;

        mss.englishListings[token][idToken][requestIndex] = englishListing;

        emit EnglishListingModified(token, idToken, requestIndex);
    }

    /**
     * @notice Modify a sealed bid listing
     */
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
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.SealedBidListingStruct memory sealedBidListing = mss.sealedBidListings[token][idToken][requestIndex];

        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotListed(tokenPayment);
        if (msg.sender != sealedBidListing.ownerListing) revert NotTheOwner(msg.sender);
        if (quantity == 0) revert QuantityInexistent(0);
        if (block.timestamp < sealedBidListing.time + sealedBidListing.biddingTime + sealedBidListing.placingTime + sealedBidListing.closingTime) revert ListingNotEnded(block.timestamp);
        if (biddingTime == 0 || placingTime == 0 || closingTime == 0) revert WrongLifetimeListing(biddingTime);
        if (sealedBidListing.amountBids != 0) revert ListingHasAtLeastOneBidder(token);

        if (sealedBidListing.quantity != quantity) {
            LibMarketplaceModifyListingFacet.manageListingDeposit(token, idToken, sealedBidListing.quantity, quantity);
        }

        if (mss.lastTimeSealedBidListing[msg.sender] + 300 > block.timestamp) revert OwnerUnderCoolingTime();
        mss.lastTimeSealedBidListing[msg.sender] = block.timestamp;

        sealedBidListing.quantity = quantity;
        sealedBidListing.floorPricePerToken = floorPrice;
        sealedBidListing.tokenPayment = tokenPayment;
        sealedBidListing.amountCapBids = amountCapBids;
        sealedBidListing.time = uint56(block.timestamp);
        sealedBidListing.biddingTime = biddingTime;
        sealedBidListing.placingTime = placingTime;
        sealedBidListing.closingTime = closingTime;

        mss.sealedBidListings[token][idToken][requestIndex] = sealedBidListing;

        emit SealedBidListingModified(token, idToken, requestIndex);
    }
}