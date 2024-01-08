// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { IMarketplaceListingFacet } from "../interfaces/IMarketplaceListingFacet.sol";

import { LibReentrancyGuard } from "../../shared/libraries/LibReentrancyGuard.sol";
import { IERC1155 } from "../../shared/interfaces/IERC1155.sol";
import { IERC721 } from "../../shared/interfaces/IERC721.sol";
import { IERC1155Receiver } from "../../shared/interfaces/IERC1155Receiver.sol";
import { IERC721Receiver } from "../../shared/interfaces/IERC721Receiver.sol";

/**
 * @notice Marketplace listings facet.
 * 
 * @dev New token listing creations need deposit escrow of tokens. Prevents many bad behaviours and reduces
 * functions checkings, thus resulting to pay less gas for the user.
 * If you want to override and re-list an item you can do it anytime with a standard listing, you will need
 * to wait for a timer, dutch english and sealed bid listing to expire without any bidder. You can close standard,
 * timer and dutch listing at any time, for english and sealed bid you will need them to expire with any
 * bidders before either close them or re-start them. To manage your listings you can do it at {ManageListingsFacet}
 * 
 * Contains:
 * {createStandardListing}
 * {createTimerListing}
 * {createDutchListing}
 * {createEnglishListing}
 * {createSealedBidListing}
 * {onERC721Received}
 * {onERC1155Received}
 * {onERC1155BatchReceived}
 */
contract MarketplaceListingFacet is LibReentrancyGuard, IMarketplaceListingFacet, IERC1155Receiver, IERC721Receiver {
    /**
     * @notice Create standard listing
     */
    function createStandardListing (
        address token,
        uint256 idToken,
        uint32 amountToken,
        uint64 pricePerToken,
        address tokenPayment
        ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Check approved by the contract and get custody NFT user
        if (mss.listingTokensApproval721[token]) {
            IERC721(token).safeTransferFrom(msg.sender, address(this), idToken, "0x");
        } else if (mss.listingTokensApproval1155[token]) {
            IERC1155(token).safeTransferFrom(msg.sender, address(this), idToken, uint256(amountToken), "0x");
            mss.totAmount[token].totAmountSL1155 += uint256(amountToken);
        } else {
            revert TokenNotApproved(token);
        }
        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotApproved(token);

        // Create index position and listing token
        uint64 indexListingIndex = uint64(mss.standardListings[token][idToken].length);
        uint32 indexListing = uint32(mss.standardListingsIndexes[msg.sender].length);
        mss.standardListingsIndexes[msg.sender].push(LibMarketplaceStorage.listingsIndexesStruct({
            indexListing: indexListingIndex,
            collection: token,
            tokenID: uint32(idToken)
        }));
        mss.standardListings[token][idToken].push(LibMarketplaceStorage.StandardListingStruct({
            ownerListing: msg.sender,
            quantity: amountToken,
            indexListing: indexListing,
            pricePerToken: pricePerToken,
            tokenPayment: tokenPayment
        }));

        // Emit listing to keep track
        emit StandardListingCreated(token, idToken, indexListing);
    }

    /**
     * @notice Create timer listing
     */
    function createTimerListing (
        address token, uint256 idToken, uint96 lifetime, uint128 amountToken, uint128 pricePerToken, address tokenPayment
        ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Check approved by the contract and get custody NFT user
        if (mss.listingTokensApproval721[token]) {
            IERC721(token).safeTransferFrom(msg.sender, address(this), idToken, "0x");
        } else if (mss.listingTokensApproval1155[token]) {
            IERC1155(token).safeTransferFrom(msg.sender, address(this), idToken, uint256(amountToken), "0x");
        } else {
            revert TokenNotApproved(token);
        }
        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotApproved(token);
        if (lifetime == 0) revert IncorrectTime(lifetime);

        // Create index position and listing token
        uint64 indexListingIndex = uint64(mss.timerListings[token][idToken].length);
        uint32 indexListing = uint32(mss.timerListingsIndexes[msg.sender].length);
        mss.timerListingsIndexes[msg.sender].push(LibMarketplaceStorage.listingsIndexesStruct({
            indexListing: indexListingIndex,
            collection: token,
            tokenID: uint32(idToken)
        }));
        mss.timerListings[token][idToken].push(LibMarketplaceStorage.TimerListingStruct({
            ownerListing: msg.sender,
            time: uint64(block.timestamp),
            indexListing: indexListing,
            tokenPayment: tokenPayment,
            lifetime: lifetime,
            quantity: amountToken,
            pricePerToken: pricePerToken
        }));

        // Emit listing to keep track
        emit TimerListingCreated(token, idToken, indexListing);
    }

    /**
     * @notice Create dutch listing
     */
    function createDutchListing (
        address token,
        uint256 idToken,
        uint96 lifetime,
        uint64 amountToken,
        uint96 pricePerToken,
        uint96 leastPricePerToken,
        address tokenPayment
        ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Check approved by the contract and get custody NFT user
        if (mss.listingTokensApproval721[token]) {
            IERC721(token).safeTransferFrom(msg.sender, address(this), idToken, "0x");
        } else if (mss.listingTokensApproval1155[token]) {
            IERC1155(token).safeTransferFrom(msg.sender, address(this), idToken, uint256(amountToken), "0x");
        } else {
            revert TokenNotApproved(token);
        }
        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotApproved(token);
        if (lifetime == 0) revert IncorrectTime(lifetime);
        if (pricePerToken <= leastPricePerToken) revert PricePerTokenHigherThanLeastPricePerToken(pricePerToken, leastPricePerToken);

        // Create index position and listing token
        uint64 indexListingIndex = uint64(mss.dutchListings[token][idToken].length);
        uint32 indexListing = uint32(mss.dutchListingsIndexes[msg.sender].length);
        mss.dutchListingsIndexes[msg.sender].push(LibMarketplaceStorage.listingsIndexesStruct({
            indexListing: indexListingIndex,
            collection: token,
            tokenID: uint32(idToken)
        }));
        mss.dutchListings[token][idToken].push(LibMarketplaceStorage.DutchListingStruct({
            ownerListing: msg.sender,
            time: uint64(block.timestamp),
            indexListing: indexListing,
            tokenPayment: tokenPayment,
            lifetime: lifetime,
            quantity: amountToken,
            pricePerToken: pricePerToken,
            leastPricePerToken: leastPricePerToken
        }));

        // Emit listing to keep track
        emit DutchListingCreated(token, idToken, indexListing);
    }

    /**
     * @notice Create english listing
     */
    function createEnglishListing (
        address token,
        uint256 idToken,
        uint64 amountToken,
        uint248 initialPricePerToken, 
        bool timeCap,
        address tokenPayment,
        uint40 lifetime,
        uint16 additionalBidTime
        ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Check approved by the contract and get custody NFT user
        if (mss.listingTokensApproval721[token]) {
            IERC721(token).safeTransferFrom(msg.sender, address(this), idToken, "0x");
        } else if (mss.listingTokensApproval1155[token]) {
            IERC1155(token).safeTransferFrom(msg.sender, address(this), idToken, uint256(amountToken), "0x");
        } else {
            revert TokenNotApproved(token);
        }
        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotApproved(token);
        if (lifetime == 0) revert IncorrectTime(lifetime);
        if (additionalBidTime > 3600) revert OverflowAdditionalBidTime(additionalBidTime);

        // Create index position and listing token
        uint64 indexListingIndex = uint64(mss.englishListings[token][idToken].length);
        uint32 indexListing = uint32(mss.englishListingsIndexes[msg.sender].length);
        mss.englishListingsIndexes[msg.sender].push(LibMarketplaceStorage.listingsIndexesStruct({
            indexListing: indexListingIndex,
            collection: token,
            tokenID: uint32(idToken)
        }));
        mss.englishListings[token][idToken].push(LibMarketplaceStorage.EnglishListingStruct({
            ownerListing: msg.sender,
            quantity: amountToken,
            indexListing: indexListing,
            initialPricePerToken: initialPricePerToken,
            timeCap: timeCap,
            tokenPayment: tokenPayment,
            time: uint40(block.timestamp),
            lifetime: lifetime,
            additionalBidTime: additionalBidTime,
            addressHighestBidder: address(0),
            pricePerTokenHighestBidder: 0,
            bidsCounter: 0
        }));

        // Emit listing to keep track
        emit EnglishListingCreated(token, idToken, indexListing);
    }

    /**
     * @notice Create sealed bid listing
     */
    struct SealedBidListingStruct {
        uint64 indexListingIndex;
        uint24 indexListing;
        uint256 index;
    }
    function createSealedBidListing (
        address token,
        uint256 idToken,
        uint96 floorPrice,
        address tokenPayment,
        uint16 amountCapBids,
        uint56 amountToken,
        uint56 biddingTime,
        uint64 placingTime,
        uint64 closingTime
        ) external nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        SealedBidListingStruct memory sealedBidListingStruct;

        // Check approved by the contract and get custody NFT user
        if (mss.listingTokensApproval721[token]) {
            IERC721(token).safeTransferFrom(msg.sender, address(this), idToken, "0x");
        } else if (mss.listingTokensApproval1155[token]) {
            IERC1155(token).safeTransferFrom(msg.sender, address(this), idToken, uint256(amountToken), "0x");
        } else {
            revert TokenNotApproved(token);
        }
        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotApproved(token);

        if (mss.lastTimeSealedBidListing[msg.sender] + 300 > block.timestamp) revert OwnerUnderCoolingTime();
        mss.lastTimeSealedBidListing[msg.sender] = block.timestamp;

        // Create index position and listing token
        sealedBidListingStruct.indexListingIndex = uint64(mss.sealedBidListings[token][idToken].length);
        sealedBidListingStruct.indexListing = uint24(mss.sealedBidListingsIndexes[msg.sender].length);
        mss.sealedBidListingsIndexes[msg.sender].push(LibMarketplaceStorage.listingsIndexesStruct({
            indexListing: sealedBidListingStruct.indexListingIndex,
            collection: token,
            tokenID: uint32(idToken)
        }));
        mss.sealedBidListings[token][idToken].push(LibMarketplaceStorage.SealedBidListingStruct({
            ownerListing: msg.sender,
            floorPricePerToken: floorPrice,
            tokenPayment: tokenPayment,
            amountCapBids: amountCapBids,
            amountBids: 0,
            quantity: amountToken,
            indexListing: sealedBidListingStruct.indexListing,
            time: uint56(block.timestamp),
            biddingTime: biddingTime,
            placingTime: placingTime,
            closingTime: closingTime
        }));

        // Emit listing to keep track
        emit SealedBidListingCreated(token, idToken, sealedBidListingStruct.indexListing);
    }

    /**
     * @notice Receiver functions, ERC721 and ERC1155
     */
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * operator The address which initiated the transfer (i.e. msg.sender)
     * from The address which previously owned the token
     * id The ID of the token being transferred
     * value The amount of tokens being transferred
     * data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*id*/,
        uint256 /*value*/,
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }
    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * operator The address which initiated the batch transfer (i.e. msg.sender)
     * from The address which previously owned the token
     * ids An array containing ids of each token being transferred (order and length must match values array)
     * values An array containing amounts of each token being transferred (order and length must match ids array)
     * data Additional data with no specified format
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address /*operator*/,
        address /*from*/,
        uint256[] calldata /*ids*/,
        uint256[] calldata /*values*/,
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}