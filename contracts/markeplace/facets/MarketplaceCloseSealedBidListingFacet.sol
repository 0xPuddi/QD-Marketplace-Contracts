// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { LibMarketplaceFulfillListingFacet } from "../libraries/LibMarketplaceFulfillListingFacet.sol";

import { LibReentrancyGuard } from "../../shared/libraries/LibReentrancyGuard.sol";
import { IERC1155 } from "../../shared/interfaces/IERC1155.sol";
import { IERC721 } from "../../shared/interfaces/IERC721.sol";
import { IERC20 } from "../../shared/interfaces/IERC20.sol";

/**
 * @notice Marketplace close sealed bid listing facet
 * 
 * @dev Cancel and transfer every token on the listing. If the user want to reduce or increase
 * their listing position they can use {MarketplaceModifyListingFacet}.
 * 
 * Contains:
 * {closeSealedBidListing}
 * {closeUnactiveSealedBidListing}
 * {closePositionSealedBidListing}
 * {closeAllPositionSealedBidListing}
 */
contract MarketplaceCloseSealedBidListingFacet is LibReentrancyGuard {
    // Revert if listing is not expired
    error ListingNotExpired(uint256 expiryTime);
    // Revert if listing has any bidders
    error ListingHasBidders(uint256 biddersNumber);
    // revert if is not the owner
    error NotTheListingOwner(address owner);
    // Revert if msg.sender is not a participant
    error WinnerNotAParticipant(address sender);

    // Emit when sealedBid listing is closed
    event SealedBidListingClosed(address token, uint256 idToken, uint256 requestIndex);
    // Emit when sealedBid listing is closed
    event SealedBidUnactiveListingClosed(address token, uint256 idToken, uint256 requestIndex);
    // Emit when a sealed bid is withdrawn
    event ClosePositionSealedBidListing(address token, uint256 idToken, uint256 requestIndex);
    // Emit when all sealed bid are withdrawn
    event CloseAllPositionSealedBidListing(address token, uint256 idToken, uint256 requestIndex);

    /**
     * @notice Close sealed bid listing
     * {closeSealedBidListing}
     * {closeUnactiveSealedBidListing}
     * {closePositionSealedBidListing}
     * {closeAllPositionSealedBidListing}
     */
    function closeSealedBidListing(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        LibMarketplaceStorage.SealedBidListingStruct memory sealedBidListing = mss.sealedBidListings[token][idToken][requestIndex];

        if (msg.sender != sealedBidListing.ownerListing) revert NotTheListingOwner(sealedBidListing.ownerListing);

        mss.sealedBidListings[token][idToken][requestIndex] = mss.sealedBidListings[token][idToken][mss.sealedBidListings[token][idToken].length - 1];
        mss.sealedBidListingsIndexes[msg.sender][sealedBidListing.indexListing] = mss.sealedBidListingsIndexes[msg.sender][mss.sealedBidListingsIndexes[msg.sender].length - 1];
        mss.sealedBidListings[token][idToken][requestIndex].indexListing = uint24(sealedBidListing.indexListing);
        mss.sealedBidListingsIndexes[msg.sender][sealedBidListing.indexListing].indexListing = uint64(requestIndex);
        mss.sealedBidListings[token][idToken].pop();
        mss.sealedBidListingsIndexes[msg.sender].pop();

        if (block.timestamp < sealedBidListing.time + sealedBidListing.biddingTime + sealedBidListing.placingTime + sealedBidListing.closingTime) revert ListingNotExpired(sealedBidListing.time + sealedBidListing.biddingTime + sealedBidListing.placingTime + sealedBidListing.closingTime);
        if (sealedBidListing.amountBids > 0) revert ListingHasBidders(sealedBidListing.amountBids);

        if (mss.listingTokensApproval1155[token]) {
            IERC1155(token).safeTransferFrom(address(this), msg.sender, idToken, sealedBidListing.quantity, "0x");
        } else {
            IERC721(token).safeTransferFrom(address(this), msg.sender, idToken);
        }

        emit SealedBidListingClosed(token, idToken, requestIndex);
    }
    function closeUnactiveSealedBidListing(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        LibMarketplaceStorage.SealedBidListingStruct memory sealedBidListing = mss.sealedBidListings[token][idToken][requestIndex];

        mss.sealedBidListings[token][idToken][requestIndex] = mss.sealedBidListings[token][idToken][mss.sealedBidListings[token][idToken].length - 1];
        mss.sealedBidListingsIndexes[sealedBidListing.ownerListing][sealedBidListing.indexListing] = mss.sealedBidListingsIndexes[sealedBidListing.ownerListing][mss.sealedBidListingsIndexes[sealedBidListing.ownerListing].length - 1];
        mss.sealedBidListings[token][idToken][requestIndex].indexListing = uint24(sealedBidListing.indexListing);
        mss.sealedBidListingsIndexes[sealedBidListing.ownerListing][sealedBidListing.indexListing].indexListing = uint64(requestIndex);
        mss.sealedBidListings[token][idToken].pop();
        mss.sealedBidListingsIndexes[sealedBidListing.ownerListing].pop();

        if (block.timestamp < sealedBidListing.time + sealedBidListing.biddingTime + sealedBidListing.placingTime + sealedBidListing.closingTime) revert ListingNotExpired(sealedBidListing.time + sealedBidListing.biddingTime + sealedBidListing.placingTime + sealedBidListing.closingTime);
        if (sealedBidListing.amountBids == 0) revert ListingHasBidders(sealedBidListing.amountBids);

        if (mss.listingTokensApproval1155[token]) {
            IERC1155(token).safeTransferFrom(address(this), msg.sender, idToken, sealedBidListing.quantity, "0x");
        } else {
            IERC721(token).safeTransferFrom(address(this), msg.sender, idToken);
        }

        uint256 pricePerTokenManager = mss.sealedBidUser[msg.sender][keccak256(abi.encodePacked(sealedBidListing.ownerListing,sealedBidListing.time))].pricePerToken;

        if (pricePerTokenManager == 0) revert WinnerNotAParticipant(msg.sender);

        uint256 grossPayment = sealedBidListing.quantity * pricePerTokenManager;

        uint256 royalties = LibMarketplaceFulfillListingFacet.royaltiesManager(
            grossPayment,
            token,
            idToken,
            address(this),
            sealedBidListing.tokenPayment,
            true
        );

        /**
         * @notice last value is the listing type:
         * 0 == StandardListing,
         * 1 == TimerListing,
         * 2 == DutchListing,
         * 3 == EnglishListing,
         * 4 == SealedBidListing.
         */
        uint256 marketplaceFee = LibMarketplaceFulfillListingFacet.marketplaceFeeManager(
            grossPayment,
            token,
            idToken,
            sealedBidListing.tokenPayment,
            address(this),
            true,
            LibMarketplaceStorage.SellingListingTypes.SealedBidListing
        );
        
        uint256 payment = grossPayment - royalties - marketplaceFee;

        if (sealedBidListing.tokenPayment == address(0)) {
            (bool success, ) = sealedBidListing.ownerListing.call{value:payment}("");
            require(success, "Transfer failed.");
        } else {
            IERC20(sealedBidListing.tokenPayment).transferFrom(address(this), sealedBidListing.ownerListing, payment);
        }

        emit SealedBidUnactiveListingClosed(token, idToken, requestIndex);
    }
    function closePositionSealedBidListing(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        bytes32 listingHash = mss.sealedBidUserDepositKeys[msg.sender][requestIndex];
        LibMarketplaceStorage.SealedBidUserStruct memory sealedBidUser = mss.sealedBidUser[msg.sender][listingHash];
        delete mss.sealedBidUserDepositKeys[msg.sender][requestIndex];
        delete mss.sealedBidUser[msg.sender][listingHash];

        uint256 payment = uint256(sealedBidUser.quantity) * sealedBidUser.pricePerToken;

        if (sealedBidUser.tokenPayment == address(0)) {
            (bool success, ) = msg.sender.call{value:payment}("");
            require(success, "Transfer failed.");
        } else {
            IERC20(sealedBidUser.tokenPayment).transferFrom(address(this), msg.sender, payment);
        }

        emit ClosePositionSealedBidListing(token, idToken, requestIndex);
    }
    function closeAllPositionSealedBidListing(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        bytes32[] memory _sealedBidUserDepositKeys = new bytes32[](mss.sealedBidUserDepositKeys[msg.sender].length);
        _sealedBidUserDepositKeys = mss.sealedBidUserDepositKeys[msg.sender];
        delete mss.sealedBidUserDepositKeys[msg.sender];

        for (uint256 i = 0; i < _sealedBidUserDepositKeys.length; ) {

            LibMarketplaceStorage.SealedBidUserStruct memory sealedBidUser = mss.sealedBidUser[msg.sender][_sealedBidUserDepositKeys[i]];
            delete mss.sealedBidUser[msg.sender][_sealedBidUserDepositKeys[i]];
            
            uint256 payment = uint256(sealedBidUser.quantity) * sealedBidUser.pricePerToken;
            
            if (sealedBidUser.tokenPayment == address(0)) {
                (bool success, ) = msg.sender.call{value:payment}("");
                require(success, "Transfer failed.");
                } else {
                    IERC20(sealedBidUser.tokenPayment).transferFrom(address(this), msg.sender, payment);
                }

            unchecked {
                ++i;
            }
        }

        emit SealedBidUnactiveListingClosed(token, idToken, requestIndex);
    }
}