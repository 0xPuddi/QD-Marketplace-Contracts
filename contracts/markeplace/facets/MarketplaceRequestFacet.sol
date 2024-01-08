// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { IMarketplaceRequestFacet } from "../interfaces/IMarketplaceRequestFacet.sol";

import { LibReentrancyGuard } from "../../shared/libraries/LibReentrancyGuard.sol";
import { IERC20 } from "../../shared/interfaces/IERC20.sol";
import { IERC777Recipient } from "../../shared/interfaces/IERC777Recipient.sol";
import { IERC777Sender } from "../../shared/interfaces/IERC777Sender.sol";

/**
 * @notice Marketplace request facet.
 * 
 * @dev By creating a request you will add a new request to the current one. To discourage bad
 * behaviours and requests attack, the request will have to be made along a deposit of the amount
 * desired to be used for the trade.
 * To modify requests see {MarketplaceModifyrequestFacet}
 * 
 * // create automate restore amount position that automate the modifications
 * 
 * Contains:
 * {createStandardRequest}
 * {createTimerRequest}
 * {createDutchRequest}
 * {createAmountRequest}
 * {createOffer}
 */
contract MarketplaceRequestFacet is LibReentrancyGuard, IMarketplaceRequestFacet {
    /**
     * @notice Create standard request
     */
    function createStandardRequest (
        address token,
        uint256 idToken,
        uint64 quantity,
        address tokenPayment,
        uint96 pricePerToken
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Check approved by the contract
        bool listingTokensApproval1155 = mss.listingTokensApproval1155[token];
        if (!mss.listingTokensApproval721[token] && !listingTokensApproval1155) revert TokenNotApproved(token);
        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotApproved(token);

        if (listingTokensApproval1155) {
            mss.totAmount[token].totAmountSR1155 += quantity;
        }

        // Get token for payment
        if (tokenPayment != address(0)) {
            IERC20(tokenPayment).transferFrom(msg.sender, address(this), uint256(pricePerToken) * uint256(quantity));
        } else {
            if (msg.value < uint256(pricePerToken) * uint256(quantity)) revert ValueDepositedInsufficient(msg.value);
        }

        // Create index position and listing token
        uint48 indexRequestIndexes = uint48(mss.standardRequests[token][idToken].length);
        uint32 indexRequest = uint32(mss.standardRequestsIndexes[msg.sender].length);
        mss.standardRequestsIndexes[msg.sender].push(LibMarketplaceStorage.requestIndexesStruct({
            collection: token,
            tokenID: uint48(idToken),
            indexRequest: indexRequestIndexes
        }));
        mss.standardRequests[token][idToken].push(LibMarketplaceStorage.StandardRequestStruct({
            owner: msg.sender,
            quantity: quantity,
            indexRequest: indexRequest,
            tokenPayment: tokenPayment,
            pricePerToken: pricePerToken
        }));

        // Emit listing to keep track
        emit StandardRequestCreated(token, idToken, indexRequestIndexes);
    }

    /**
     * @notice Create timer request
     */
    function createTimerRequest (
        address token,
        uint256 idToken,
        uint80 quantity,
        address tokenPayment,
        uint176 pricePerToken,
        uint96 lifetime
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Check approved by the contract
        if (!mss.listingTokensApproval721[token] && !mss.listingTokensApproval1155[token]) revert TokenNotApproved(token);
        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotApproved(token);
        if (lifetime == 0) revert IncorrectTime(lifetime);

        // Get token for payment
        if (tokenPayment != address(0)) {
            IERC20(tokenPayment).transferFrom(msg.sender, address(this), uint256(pricePerToken) * uint256(quantity));
        } else {
            if (msg.value < uint256(pricePerToken) * uint256(quantity)) revert ValueDepositedInsufficient(msg.value);
        }

        // Create index position and listing token
        uint48 indexRequestIndexes = uint48(mss.timerRequests[token][idToken].length);
        uint32 indexRequest = uint32(mss.timerRequestsIndexes[msg.sender].length);
        mss.timerRequestsIndexes[msg.sender].push(LibMarketplaceStorage.requestIndexesStruct({
            collection: token,
            tokenID: uint48(idToken),
            indexRequest: indexRequestIndexes
        }));
        mss.timerRequests[token][idToken].push(LibMarketplaceStorage.TimerRequestStruct({
            owner: msg.sender,
            time: uint64(block.timestamp),
            indexRequest: indexRequest,
            tokenPayment: tokenPayment,
            lifetime: lifetime,
            quantity: quantity,
            pricePerToken: pricePerToken
        }));

        // Emit listing to keep track
        emit TimerRequestCreated(token, idToken, indexRequestIndexes);
    }

    /**
     * @notice Create dutch request
     */
    function createDutchRequest (
        address token,
        uint256 idToken,
        uint96 quantity,
        address tokenPayment,
        uint32 lifetime,
        uint112 pricePerToken,
        uint112 leastPricePerToken
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Check approved by the contract
        if (!mss.listingTokensApproval721[token] && !mss.listingTokensApproval1155[token]) revert TokenNotApproved(token);
        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotApproved(token);
        if (lifetime == 0) revert IncorrectTime(uint32(lifetime));
        if (pricePerToken < leastPricePerToken) revert LeastPricePerTokenHigherThanPricePerToken(pricePerToken, leastPricePerToken);

        // Get token for payment
        if (tokenPayment != address(0)) {
            IERC20(tokenPayment).transferFrom(msg.sender, address(this), uint256(pricePerToken) * uint256(quantity));
        } else {
            if (msg.value < uint256(pricePerToken) * uint256(quantity)) revert ValueDepositedInsufficient(msg.value);
        }

        // Create index position and listing token
        uint48 indexRequestIndexes = uint48(mss.dutchRequests[token][idToken].length);
        uint32 indexRequest = uint32(mss.dutchRequestsIndexes[msg.sender].length);
        mss.dutchRequestsIndexes[msg.sender].push(LibMarketplaceStorage.requestIndexesStruct({
            collection: token,
            tokenID: uint48(idToken),
            indexRequest: indexRequestIndexes
        }));
        mss.dutchRequests[token][idToken].push(LibMarketplaceStorage.DutchRequestStruct({
            owner: msg.sender,
            time: uint64(block.timestamp),
            indexRequest: indexRequest,
            tokenPayment: tokenPayment,
            quantity: quantity,
            lifetime: lifetime,
            pricePerToken: pricePerToken,
            leastPricePerToken: leastPricePerToken
        }));

        // Emit listing to keep track
        emit DutchRequestCreated(token, idToken, indexRequestIndexes);
    }

    /**
     * @notice Create amount request
     */
    function createAmountRequest (
        address token,
        uint256 idToken,
        uint128 quantity,
        address tokenPayment,
        uint96 lifetime,
        uint128 pricePerToken
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Check approved by the contract
        if (!mss.listingTokensApproval1155[token]) revert TokenNotApproved(token);
        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotApproved(token);
        uint256 averageSLAndSRAmountCollection = LibMarketplaceStorage.returnTotAverageSLAndSRAmountCollection(token);
        if (averageSLAndSRAmountCollection >= quantity) revert AmountRequestIsNotLiquidEnough(token, averageSLAndSRAmountCollection, quantity);

        // Get token for payment
        if (tokenPayment != address(0)) {
            IERC20(tokenPayment).transferFrom(msg.sender, address(this), uint256(pricePerToken) * uint256(quantity));
        } else {
            if (msg.value < uint256(pricePerToken) * uint256(quantity)) revert ValueDepositedInsufficient(msg.value);
        }

        // Create index position and listing token
        uint48 indexRequestIndexes = uint48(mss.amountRequests[token][idToken].length);
        uint32 indexRequest = uint32(mss.amountRequestsIndexes[msg.sender].length);
        mss.amountRequestsIndexes[msg.sender].push(LibMarketplaceStorage.requestIndexesStruct({
            collection: token,
            tokenID: uint48(idToken),
            indexRequest: indexRequestIndexes
        }));
        mss.amountRequests[token][idToken].push(LibMarketplaceStorage.AmountRequestStruct({
            owner: msg.sender,
            time: uint64(block.timestamp),
            indexRequest: indexRequest,
            tokenPayment: tokenPayment,
            lifetime: lifetime,
            quantity: quantity,
            pricePerToken: pricePerToken
        }));

        // Emit listing to keep track
        emit AmountRequestCreated(token, idToken, indexRequestIndexes);
    }

    /**
     * @notice Create offer
     */
    function createOffer (
        address userOffered,
        address token,
        address tokenPayment,
        uint64 idToken,
        uint96 quantity,
        uint176 pricePerToken,
        uint40 lifetime
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Check approved by the contract
        if (!mss.listingTokensApproval721[token] && !mss.listingTokensApproval1155[token]) revert TokenNotApproved(token);
        if (!mss.biddingTokensApproval[tokenPayment]) revert TokenNotApproved(token);

        // Get token for payment
        if (tokenPayment != address(0)) {
            IERC20(tokenPayment).transferFrom(msg.sender, address(this), uint256(pricePerToken) * uint256(quantity));
        } else {
            if (msg.value < uint256(pricePerToken) * uint256(quantity)) revert ValueDepositedInsufficient(msg.value);
        }

        // Create index position and listing token
        uint96 offerIndexes = uint96(mss.Offer[msg.sender][userOffered].length);
        uint32 offer = uint32(mss.offersIndexes[token].length);
        mss.offersIndexes[token].push(LibMarketplaceStorage.offersIndexesStruct({
            offerPlacer: msg.sender,
            tokenID: idToken,
            offerReceiver: userOffered,
            offerIndex: offerIndexes
        }));
        mss.Offer[msg.sender][userOffered].push(LibMarketplaceStorage.OfferStruct({
            addressToken: token,
            idToken: idToken,
            indexOffer: offer,
            tokenPayment: tokenPayment,
            quantity: quantity,
            pricePerToken: pricePerToken,
            time: uint40(block.timestamp),
            lifetime: lifetime
        }));

        // Emit listing to keep track
        emit OfferCreated(msg.sender, userOffered, offerIndexes);
    }
}