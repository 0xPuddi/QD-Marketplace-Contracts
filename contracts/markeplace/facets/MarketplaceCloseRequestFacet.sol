// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { IMarketplaceCloseRequestFacet } from "../interfaces/IMarketplaceCloseRequestFacet.sol";

import { LibReentrancyGuard } from "../../shared/libraries/LibReentrancyGuard.sol";
import { IERC20 } from "../../shared/interfaces/IERC20.sol";

/**
 * @notice Marketplace close request facet
 * 
 * Contains:
 * {closeStandardRequest}
 * {closeTimerRequest}
 * {closeAmountRequest}
 * {closeOffer}
 */
contract MarketplaceCloseRequestFacet is IMarketplaceCloseRequestFacet {
    /**
     * @notice close standard request
     */
    function closeStandardRequest(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.StandardRequestStruct memory standardRequest = mss.standardRequests[token][idToken][requestIndex];

        mss.standardRequests[token][idToken][requestIndex] = mss.standardRequests[token][idToken][mss.standardRequests[token][idToken].length - 1];
        mss.standardRequestsIndexes[standardRequest.owner][standardRequest.indexRequest] = mss.standardRequestsIndexes[standardRequest.owner][mss.standardRequestsIndexes[standardRequest.owner].length - 1];
        mss.standardRequests[token][idToken][requestIndex].indexRequest = uint32(standardRequest.indexRequest);
        mss.standardRequestsIndexes[standardRequest.owner][standardRequest.indexRequest].indexRequest = uint48(requestIndex);
        mss.standardRequests[token][idToken].pop();
        mss.standardRequestsIndexes[standardRequest.owner].pop();

        mss.totAmount[token].totAmountSR1155 -= uint256(standardRequest.quantity);

        uint256 payment = uint256(standardRequest.quantity) * uint256(standardRequest.pricePerToken);
        if (standardRequest.tokenPayment == address(0)) {
            (bool success, ) = msg.sender.call{value:payment}("");
            require(success, "Transfer failed.");
        } else {
            IERC20(standardRequest.tokenPayment).transferFrom(address(this), msg.sender, payment);
        }

        emit StandardRequestClosed(token, idToken, requestIndex);
    }

    /**
     * @notice close timer request
     */
    function closeTimerRequest(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.TimerRequestStruct memory timerRequest = mss.timerRequests[token][idToken][requestIndex];

        mss.timerRequests[token][idToken][requestIndex] = mss.timerRequests[token][idToken][mss.timerRequests[token][idToken].length - 1];
        mss.timerRequestsIndexes[timerRequest.owner][timerRequest.indexRequest] = mss.timerRequestsIndexes[timerRequest.owner][mss.timerRequestsIndexes[timerRequest.owner].length - 1];
        mss.timerRequests[token][idToken][requestIndex].indexRequest = uint32(timerRequest.indexRequest);
        mss.timerRequestsIndexes[timerRequest.owner][timerRequest.indexRequest].indexRequest = uint48(requestIndex);
        mss.timerRequests[token][idToken].pop();
        mss.timerRequestsIndexes[timerRequest.owner].pop();

        if (block.timestamp < timerRequest.time + timerRequest.lifetime) revert ListingNotExpired(timerRequest.time + timerRequest.lifetime);

        uint256 payment = uint256(timerRequest.quantity) * uint256(timerRequest.pricePerToken);
        if (timerRequest.tokenPayment == address(0)) {
            (bool success, ) = msg.sender.call{value:payment}("");
            require(success, "Transfer failed.");
        } else {
            IERC20(timerRequest.tokenPayment).transferFrom(address(this), msg.sender, payment);
        }

        emit TimerRequestClosed(token, idToken, requestIndex);
    }

    /**
     * @notice close standard request
     */
    function closeAmountRequest(
        address token,
        uint256 idToken,
        uint256 requestIndex
    ) external {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.AmountRequestStruct memory amountRequest = mss.amountRequests[token][idToken][requestIndex];

        mss.amountRequests[token][idToken][requestIndex] = mss.amountRequests[token][idToken][mss.amountRequests[token][idToken].length - 1];
        mss.amountRequestsIndexes[amountRequest.owner][amountRequest.indexRequest] = mss.amountRequestsIndexes[amountRequest.owner][mss.amountRequestsIndexes[amountRequest.owner].length - 1];
        mss.amountRequests[token][idToken][requestIndex].indexRequest = uint32(amountRequest.indexRequest);
        mss.amountRequestsIndexes[amountRequest.owner][amountRequest.indexRequest].indexRequest = uint48(requestIndex);
        mss.amountRequests[token][idToken].pop();
        mss.amountRequestsIndexes[amountRequest.owner].pop();

        if (amountRequest.quantity > mss.totAmount[token].totAmountSL1155 + mss.totAmount[token].totAmountSR1155) {
            if (amountRequest.lifetime != 0 && block.timestamp < amountRequest.time + amountRequest.lifetime) revert ListingNotExpired(amountRequest.time + amountRequest.lifetime);
        }

        uint256 payment = uint256(amountRequest.quantity) * uint256(amountRequest.pricePerToken);
        if (amountRequest.tokenPayment == address(0)) {
            (bool success, ) = msg.sender.call{value:payment}("");
            require(success, "Transfer failed.");
        } else {
            IERC20(amountRequest.tokenPayment).transferFrom(address(this), msg.sender, payment);
        }

        emit AmountRequestClosed(token, idToken, requestIndex);
    }

    /**
     * @notice close offer
     */
    function closeOffer(
        address offeredTo,
        uint256 requestIndex
    ) external {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.OfferStruct memory offerStruct = mss.Offer[msg.sender][offeredTo][requestIndex];

        mss.Offer[msg.sender][offeredTo][requestIndex] = mss.Offer[msg.sender][offeredTo][mss.Offer[msg.sender][offeredTo].length - 1];
        mss.offersIndexes[offerStruct.addressToken][offerStruct.indexOffer] = mss.offersIndexes[offerStruct.addressToken][mss.offersIndexes[offerStruct.addressToken].length - 1];
        mss.Offer[msg.sender][offeredTo][requestIndex].indexOffer = uint32(offerStruct.indexOffer);
        mss.offersIndexes[offerStruct.addressToken][offerStruct.indexOffer].offerIndex = uint64(requestIndex);
        mss.Offer[msg.sender][offeredTo].pop();
        mss.offersIndexes[offerStruct.addressToken].pop();

        if (offerStruct.lifetime != 0 && block.timestamp < offerStruct.time + offerStruct.lifetime) revert ListingNotExpired(offerStruct.time + offerStruct.lifetime);

        uint256 payment = uint256(offerStruct.quantity) * uint256(offerStruct.pricePerToken);
        if (offerStruct.tokenPayment == address(0)) {
            (bool success, ) = msg.sender.call{value:payment}("");
            require(success, "Transfer failed.");
        } else {
            IERC20(offerStruct.tokenPayment).transferFrom(address(this), msg.sender, payment);
        }

        emit OfferClosed(offeredTo, requestIndex);
    }
}