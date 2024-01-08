// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { IMarketplaceCloseListingFacet } from "../interfaces/IMarketplaceCloseListingFacet.sol";
import { LibMarketplaceFulfillListingFacet } from "../libraries/LibMarketplaceFulfillListingFacet.sol";


import { LibReentrancyGuard } from "../../shared/libraries/LibReentrancyGuard.sol";
import { IERC1155 } from "../../shared/interfaces/IERC1155.sol";
import { IERC721 } from "../../shared/interfaces/IERC721.sol";
import { IERC20 } from "../../shared/interfaces/IERC20.sol";

/**
 * @notice Marketplace close listing facet
 * 
 * @dev Cancel and transfer every token on the listing. If the user want to reduce or increase
 * their listing position they can use {MarketplaceModifyListingFacet}.
 * 
 * Contains:
 * {closeStandardListing}
 * {closeTimerListing}
 * {closeDutchListing}
 * {closeEnglishListing}
 */
contract MarketplaceCloseListingFacet is LibReentrancyGuard, IMarketplaceCloseListingFacet {
    /**
     * @notice Close standard listing
     */
    function closeStandardListing(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        LibMarketplaceStorage.StandardListingStruct memory standardListing = mss.standardListings[token][idToken][requestIndex];

        if (msg.sender != standardListing.ownerListing) revert NotTheListingOwner(standardListing.ownerListing);

        mss.standardListings[token][idToken][requestIndex] = mss.standardListings[token][idToken][mss.standardListings[token][idToken].length - 1];
        mss.standardListingsIndexes[msg.sender][standardListing.indexListing] = mss.standardListingsIndexes[msg.sender][mss.standardListingsIndexes[msg.sender].length - 1];
        mss.standardListings[token][idToken][requestIndex].indexListing = uint32(standardListing.indexListing);
        mss.standardListingsIndexes[msg.sender][standardListing.indexListing].indexListing = uint64(requestIndex);
        mss.standardListings[token][idToken].pop();
        mss.standardListingsIndexes[msg.sender].pop();

        if (mss.listingTokensApproval1155[token]) {
            IERC1155(token).safeTransferFrom(address(this), msg.sender, idToken, standardListing.quantity, "0x");
            mss.totAmount[token].totAmountSL1155 -= standardListing.quantity;
        } else {
            IERC721(token).safeTransferFrom(address(this), msg.sender, idToken);
        }

        emit StandardListingClosed(token, idToken, requestIndex);
    }

    /**
     * @notice Close timer listing
     */
    function closeTimerListing(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        LibMarketplaceStorage.TimerListingStruct memory timerListing = mss.timerListings[token][idToken][requestIndex];

        if (msg.sender != timerListing.ownerListing) revert NotTheListingOwner(timerListing.ownerListing);

        mss.timerListings[token][idToken][requestIndex] = mss.timerListings[token][idToken][mss.timerListings[token][idToken].length - 1];
        mss.timerListingsIndexes[msg.sender][timerListing.indexListing] = mss.timerListingsIndexes[msg.sender][mss.timerListingsIndexes[msg.sender].length - 1];
        mss.timerListings[token][idToken][requestIndex].indexListing = uint32(timerListing.indexListing);
        mss.timerListingsIndexes[msg.sender][timerListing.indexListing].indexListing = uint64(requestIndex);
        mss.timerListings[token][idToken].pop();
        mss.timerListingsIndexes[msg.sender].pop();

        if (block.timestamp < timerListing.time + timerListing.lifetime) revert ListingNotExpired(timerListing.time + timerListing.lifetime);

        if (mss.listingTokensApproval1155[token]) {
            IERC1155(token).safeTransferFrom(address(this), msg.sender, idToken, timerListing.quantity, "0x");
        } else {
            IERC721(token).safeTransferFrom(address(this), msg.sender, idToken);
        }

        emit TimerListingClosed(token, idToken, requestIndex);
    }

    /**
     * @notice Close dutch listing
     */
    function closeDutchListing(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        LibMarketplaceStorage.DutchListingStruct memory dutchListing = mss.dutchListings[token][idToken][requestIndex];

        if (msg.sender != dutchListing.ownerListing) revert NotTheListingOwner(dutchListing.ownerListing);

        mss.dutchListings[token][idToken][requestIndex] = mss.dutchListings[token][idToken][mss.dutchListings[token][idToken].length - 1];
        mss.dutchListingsIndexes[msg.sender][dutchListing.indexListing] = mss.dutchListingsIndexes[msg.sender][mss.dutchListingsIndexes[msg.sender].length - 1];
        mss.dutchListings[token][idToken][requestIndex].indexListing = uint32(dutchListing.indexListing);
        mss.dutchListingsIndexes[msg.sender][dutchListing.indexListing].indexListing = uint64(requestIndex);
        mss.dutchListings[token][idToken].pop();
        mss.dutchListingsIndexes[msg.sender].pop();

        if (block.timestamp < dutchListing.time + dutchListing.lifetime) revert ListingNotExpired(dutchListing.time + dutchListing.lifetime);

        if (mss.listingTokensApproval1155[token]) {
            IERC1155(token).safeTransferFrom(address(this), msg.sender, idToken, dutchListing.quantity, "0x");
        } else {
            IERC721(token).safeTransferFrom(address(this), msg.sender, idToken);
        }

        emit DutchListingClosed(token, idToken, requestIndex);
    }

    /**
     * @notice Close english listing
     */
    function closeEnglishListing(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        LibMarketplaceStorage.EnglishListingStruct memory englishListing = mss.englishListings[token][idToken][requestIndex];

        if (msg.sender != englishListing.ownerListing) revert NotTheListingOwner(englishListing.ownerListing);

        mss.englishListings[token][idToken][requestIndex] = mss.englishListings[token][idToken][mss.englishListings[token][idToken].length - 1];
        mss.englishListingsIndexes[msg.sender][englishListing.indexListing] = mss.englishListingsIndexes[msg.sender][mss.englishListingsIndexes[msg.sender].length - 1];
        mss.englishListings[token][idToken][requestIndex].indexListing = uint32(englishListing.indexListing);
        mss.englishListingsIndexes[msg.sender][englishListing.indexListing].indexListing = uint64(requestIndex);
        mss.englishListings[token][idToken].pop();
        mss.englishListingsIndexes[msg.sender].pop();

        if (block.timestamp < englishListing.time + englishListing.lifetime) revert ListingNotExpired(englishListing.time + englishListing.lifetime);
        if (englishListing.bidsCounter > 0) revert ListingHasBidders(englishListing.bidsCounter);

        if (mss.listingTokensApproval1155[token]) {
            IERC1155(token).safeTransferFrom(address(this), msg.sender, idToken, englishListing.quantity, "0x");
        } else {
            IERC721(token).safeTransferFrom(address(this), msg.sender, idToken);
        }

        emit EnglishListingClosed(token, idToken, requestIndex);
    }
}