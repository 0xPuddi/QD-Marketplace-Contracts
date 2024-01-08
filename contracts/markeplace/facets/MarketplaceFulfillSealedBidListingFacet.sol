// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { LibMarketplaceFulfillListingFacet } from "../libraries/LibMarketplaceFulfillListingFacet.sol";
import { IMarketplaceFulfillSealedBidListingFacet } from "../interfaces/IMarketplaceFulfillSealedBidListingFacet.sol";

import { LibReentrancyGuard } from "../../shared/libraries/LibReentrancyGuard.sol";
import { IERC20 } from "../../shared/interfaces/IERC20.sol";

/**
 * @notice Marketplace fulfill sealed bid listing facet
 * 
 * Contains:
 * {bidSealedBidListing}
 * {placeSealedBidListing}
 * {closeSealedBidListing}
 */
contract MarketplaceFulfillSealedBidListingFacet is LibReentrancyGuard, IMarketplaceFulfillSealedBidListingFacet {
    /**
     * @notice Fulfill sealed bid listing
     * {bidSealedBidListing}
     * {placeSealedBidListing}
     * {closeSealedBidListing}
     */
    function bidSealedBidListing(
        address token,
        uint256 idToken,
        uint256 requestIndex,
        bytes32 passwordHash
    ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.SealedBidListingStruct memory sealedBidListingStruct = mss.sealedBidListings[token][idToken][requestIndex];

        if (block.timestamp > sealedBidListingStruct.time + sealedBidListingStruct.biddingTime) revert NotSealedBidBidTime();

        mss.sealedBidUser[msg.sender][keccak256(abi.encodePacked(sealedBidListingStruct.ownerListing,sealedBidListingStruct.time))].passwordHash = passwordHash;

        emit SealedBidBidded(token, idToken, requestIndex);
    }
    function placeSealedBidListing(
        address token,
        uint256 idToken,
        uint256 requestIndex,
        string memory passwordHashPlacer,
        uint256 pricePerToken
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.SealedBidListingStruct memory sealedBidListingStruct = mss.sealedBidListings[token][idToken][requestIndex];

        bytes32 listingHash = keccak256(abi.encodePacked(sealedBidListingStruct.ownerListing,sealedBidListingStruct.time));

        if (
            block.timestamp > sealedBidListingStruct.time + sealedBidListingStruct.biddingTime + sealedBidListingStruct.placingTime ||
            block.timestamp < sealedBidListingStruct.time + sealedBidListingStruct.biddingTime
        ) revert NotSealedBidPlaceTime();

        if (!LibMarketplaceFulfillListingFacet.checkSealedBidHash(
            mss.sealedBidUser[msg.sender][listingHash].passwordHash,
            passwordHashPlacer,
            pricePerToken
        )) revert WrongSealedBidHash();

        if (sealedBidListingStruct.amountCapBids == sealedBidListingStruct.amountBids) revert BidsCapLimitReached();
        sealedBidListingStruct.amountBids += 1;
        
        if (sealedBidListingStruct.floorPricePerToken < pricePerToken) revert FloorPriceNotReached();

        uint256 deposit = pricePerToken * uint256(sealedBidListingStruct.quantity);
        if (sealedBidListingStruct.tokenPayment == address(0)) {
            require(msg.value >= deposit, "DEPOSIT_TOO_LOW");
        } else {
            IERC20(sealedBidListingStruct.tokenPayment).transferFrom(msg.sender, address(this), deposit);
        }

        mss.sealedBidUser[msg.sender][listingHash].pricePerToken = pricePerToken;
        mss.sealedBidUser[msg.sender][listingHash].quantity = sealedBidListingStruct.quantity;
        mss.sealedBidUser[msg.sender][listingHash].tokenPayment = sealedBidListingStruct.tokenPayment;
        mss.sealedBidListings[token][idToken][requestIndex] = sealedBidListingStruct;
        mss.sealedBidUserDepositKeys[msg.sender].push(listingHash);

        emit SealedBidBidded(token, idToken, requestIndex);
    }
    struct CloseSealedBidListingStruct {
        address token;
        uint256 idToken;
        uint256 pricePerTokenWinningPlayer;
        address thisAddress;
        uint256 grossPayment;
        uint256 royalties;
        uint256 marketplaceFee;
        uint256 payment;
        bool biddingTokensApproval;
        bool trueBool;
    }
    function closeSealedBidListing(
        address token,
        uint256 idToken,
        uint256 requestIndex,
        address winningPlayer
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        CloseSealedBidListingStruct memory closeSealedBidListingStruct;
        LibMarketplaceStorage.SealedBidListingStruct memory sealedBidListingStruct = mss.sealedBidListings[token][idToken][requestIndex];

        mss.sealedBidListings[token][idToken][requestIndex] = mss.sealedBidListings[token][idToken][mss.sealedBidListings[token][idToken].length - 1];
        mss.sealedBidListingsIndexes[msg.sender][sealedBidListingStruct.indexListing] = mss.sealedBidListingsIndexes[msg.sender][mss.sealedBidListingsIndexes[msg.sender].length - 1];
        mss.sealedBidListings[token][idToken][requestIndex].indexListing = uint24(sealedBidListingStruct.indexListing);
        mss.sealedBidListingsIndexes[msg.sender][sealedBidListingStruct.indexListing].indexListing = uint64(requestIndex);
        mss.sealedBidListings[token][idToken].pop();
        mss.sealedBidListingsIndexes[msg.sender].pop();

        closeSealedBidListingStruct.token = token;
        closeSealedBidListingStruct.idToken = idToken;
        closeSealedBidListingStruct.pricePerTokenWinningPlayer = mss.sealedBidUser[winningPlayer][keccak256(abi.encodePacked(sealedBidListingStruct.ownerListing,sealedBidListingStruct.time))].pricePerToken;
        closeSealedBidListingStruct.thisAddress = address(this);
        closeSealedBidListingStruct.trueBool = true;

        if (sealedBidListingStruct.ownerListing != msg.sender) revert NotTheOwner(msg.sender);
        if (closeSealedBidListingStruct.pricePerTokenWinningPlayer == 0) revert WinnerNotAParticipant(winningPlayer);
        if (sealedBidListingStruct.amountBids == 0) revert NoBidders(); // optional

        if (
            block.timestamp > sealedBidListingStruct.time + sealedBidListingStruct.biddingTime + sealedBidListingStruct.placingTime + sealedBidListingStruct.closingTime ||
            block.timestamp < sealedBidListingStruct.time + sealedBidListingStruct.biddingTime + sealedBidListingStruct.placingTime
        ) revert NotSealedBidCloseTime();

        closeSealedBidListingStruct.grossPayment = sealedBidListingStruct.quantity * closeSealedBidListingStruct.pricePerTokenWinningPlayer;
        closeSealedBidListingStruct.biddingTokensApproval = mss.biddingTokensApproval[sealedBidListingStruct.tokenPayment];

        closeSealedBidListingStruct.royalties = LibMarketplaceFulfillListingFacet.royaltiesManager(
            closeSealedBidListingStruct.grossPayment,
            closeSealedBidListingStruct.token,
            closeSealedBidListingStruct.idToken,
            closeSealedBidListingStruct.thisAddress,
            sealedBidListingStruct.tokenPayment,
            closeSealedBidListingStruct.biddingTokensApproval
        );

        /**
         * @notice last value is the listing type:
         * 0 == StandardListing,
         * 1 == TimerListing,
         * 2 == DutchListing,
         * 3 == EnglishListing,
         * 4 == SealedBidListing.
         */
        closeSealedBidListingStruct.marketplaceFee = LibMarketplaceFulfillListingFacet.marketplaceFeeManager(
            closeSealedBidListingStruct.grossPayment,
            closeSealedBidListingStruct.token,
            closeSealedBidListingStruct.idToken,
            sealedBidListingStruct.tokenPayment,
            closeSealedBidListingStruct.thisAddress,
            closeSealedBidListingStruct.biddingTokensApproval,
            LibMarketplaceStorage.SellingListingTypes.SealedBidListing
        );

        closeSealedBidListingStruct.payment = closeSealedBidListingStruct.grossPayment - closeSealedBidListingStruct.royalties - closeSealedBidListingStruct.marketplaceFee;

        LibMarketplaceFulfillListingFacet.manageTransfers(
            closeSealedBidListingStruct.payment,
            closeSealedBidListingStruct.idToken,
            sealedBidListingStruct.quantity,
            sealedBidListingStruct.tokenPayment,
            sealedBidListingStruct.ownerListing,
            winningPlayer,
            closeSealedBidListingStruct.trueBool,
            closeSealedBidListingStruct.token,
            closeSealedBidListingStruct.biddingTokensApproval
        );

        emit SealedBidClosed(closeSealedBidListingStruct.token, closeSealedBidListingStruct.idToken, requestIndex);
    }
}