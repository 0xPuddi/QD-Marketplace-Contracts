// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { IMarketplaceModifyRequestFacet } from "../interfaces/IMarketplaceModifyRequestFacet.sol";
import { LibMarketplaceModifyRequestFacet } from "../libraries/LibMarketplaceModifyRequestFacet.sol";

import { LibReentrancyGuard } from "../../shared/libraries/LibReentrancyGuard.sol";

/**
 * @dev Merketplace modify request
 * To override and modify an already created request use the related modify function. Standard
 * requests can be modified at any time, while timer and dutch requests only after expiring. Amount
 * and offer requests can be modified at any time if lifetime is 0, otherwise only after expiring.
 * 
 * Contains:
 * {modifyStandardRequest}
 * {modifyTimerRequest}
 * {modifyDutchRequest}
 * {modifyAmountRequest}
 * {modifyOffer}
 */
contract MarketplaceModifyRequestFacet is LibReentrancyGuard, IMarketplaceModifyRequestFacet {
    /**
     * @notice Modify standard request
     */
    function modifyStandardRequest (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint64 quantity,
        address tokenPayment,
        uint96 pricePerToken
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.StandardRequestStruct memory standardRequest = mss.standardRequests[token][idToken][requestIndex];

        if (msg.sender != standardRequest.owner) revert NotTheOwner(standardRequest.owner);
        if (tokenPayment != standardRequest.tokenPayment) revert DifferentPaymentToken(standardRequest.tokenPayment);

        uint256 oldDepositAmount = uint256(standardRequest.quantity) * uint256(standardRequest.pricePerToken);
        uint256 newDepositAmount = uint256(pricePerToken) * uint256(quantity);

        if (!LibMarketplaceModifyRequestFacet.manageDepositPositionModified(tokenPayment, newDepositAmount, oldDepositAmount)) revert DepositFailed(tokenPayment, newDepositAmount, oldDepositAmount);

        if (mss.listingTokensApproval1155[token]) {
            if (standardRequest.quantity < quantity) {
                mss.totAmount[token].totAmountSR1155 -= (quantity - standardRequest.quantity);
            } else {
                mss.totAmount[token].totAmountSR1155 -= (standardRequest.quantity - quantity);
            }
        }

        standardRequest.quantity = quantity;
        standardRequest.pricePerToken = pricePerToken;

        mss.standardRequests[token][idToken][requestIndex] = standardRequest;

        emit StandardRequestModified(token, idToken, requestIndex);
    }

    /**
     * @notice Modify timer request
     */
    function modifyTimerRequest (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint80 quantity,
        address tokenPayment,
        uint176 pricePerToken,
        uint96 lifetime
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.TimerRequestStruct memory timerRequest = mss.timerRequests[token][idToken][requestIndex];

        if (msg.sender != timerRequest.owner) revert NotTheOwner(timerRequest.owner);
        if (tokenPayment != timerRequest.tokenPayment) revert DifferentPaymentToken(timerRequest.tokenPayment);
        if (block.timestamp < timerRequest.time + timerRequest.lifetime) revert RequestNotExpired(timerRequest.time + timerRequest.lifetime - block.timestamp);

        uint256 oldDepositAmount = uint256(timerRequest.quantity) * (timerRequest.pricePerToken);
        uint256 newDepositAmount = uint256(pricePerToken) * uint256(quantity);

        if (!LibMarketplaceModifyRequestFacet.manageDepositPositionModified(tokenPayment, newDepositAmount, oldDepositAmount)) revert DepositFailed(tokenPayment, newDepositAmount, oldDepositAmount);

        timerRequest.time = uint64(block.timestamp);
        timerRequest.lifetime = lifetime;
        timerRequest.quantity = quantity;
        timerRequest.pricePerToken = pricePerToken;

        mss.timerRequests[token][idToken][requestIndex] = timerRequest;

        emit TimerRequestModified(token, idToken, requestIndex);
    }

    /**
     * @notice Modify dutch request
     */
    function modifyDutchRequest (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint96 quantity,
        address tokenPayment,
        uint32 lifetime,
        uint112 pricePerToken,
        uint112 leastPricePerToken
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.DutchRequestStruct memory dutchRequest = mss.dutchRequests[token][idToken][requestIndex];

        if (msg.sender != dutchRequest.owner) revert NotTheOwner(dutchRequest.owner);
        if (lifetime == 0) revert IncorrectTime(lifetime);
        if (pricePerToken < leastPricePerToken) revert LeastPricePerTokenHigherThanPricePerToken(pricePerToken, leastPricePerToken);
        if (tokenPayment != dutchRequest.tokenPayment) revert DifferentPaymentToken(dutchRequest.tokenPayment);
        if (block.timestamp < dutchRequest.time + dutchRequest.lifetime) revert RequestNotExpired(dutchRequest.time + dutchRequest.lifetime - block.timestamp);

        uint256 oldDepositAmount = uint256(dutchRequest.quantity) * (dutchRequest.pricePerToken);
        uint256 newDepositAmount = uint256(pricePerToken) * uint256(quantity);

        if (!LibMarketplaceModifyRequestFacet.manageDepositPositionModified(tokenPayment, newDepositAmount, oldDepositAmount)) revert DepositFailed(tokenPayment, newDepositAmount, oldDepositAmount);

        dutchRequest.time = uint64(block.timestamp);
        dutchRequest.quantity = quantity;
        dutchRequest.lifetime = lifetime;
        dutchRequest.pricePerToken = pricePerToken;
        dutchRequest.leastPricePerToken = leastPricePerToken;

        mss.dutchRequests[token][idToken][requestIndex] = dutchRequest;

        emit DutchRequestModified(token, idToken, requestIndex);
    }

    /**
     * @notice Modify amount request
     */
    function modifyAmountRequest (
        address token,
        uint256 idToken,
        uint256 requestIndex,
        uint128 quantity,
        address tokenPayment,
        uint96 lifetime,
        uint128 pricePerToken
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.AmountRequestStruct memory amountRequest = mss.amountRequests[token][idToken][requestIndex];

        if (msg.sender != amountRequest.owner) revert NotTheOwner(amountRequest.owner);
        if (tokenPayment != amountRequest.tokenPayment) revert DifferentPaymentToken(amountRequest.tokenPayment);
        uint256 averageSLAndSRAmountCollection = LibMarketplaceStorage.returnTotAverageSLAndSRAmountCollection(token);
        if (averageSLAndSRAmountCollection < quantity) {
            if (block.timestamp < amountRequest.time + amountRequest.lifetime && amountRequest.lifetime != 0) revert RequestNotExpired(amountRequest.time + amountRequest.lifetime - block.timestamp);
        }
        if (averageSLAndSRAmountCollection >= quantity) revert AmountRequestIsNotLiquidEnough(token, averageSLAndSRAmountCollection, quantity);

        uint256 oldDepositAmount = uint256(amountRequest.quantity) * (amountRequest.pricePerToken);
        uint256 newDepositAmount = uint256(pricePerToken) * uint256(quantity);

        if (!LibMarketplaceModifyRequestFacet.manageDepositPositionModified(tokenPayment, newDepositAmount, oldDepositAmount)) revert DepositFailed(tokenPayment, newDepositAmount, oldDepositAmount);

        amountRequest.time = uint64(block.timestamp);
        amountRequest.lifetime = lifetime;
        amountRequest.quantity = quantity;
        amountRequest.pricePerToken = pricePerToken;

        mss.amountRequests[token][idToken][requestIndex] = amountRequest;

        emit AmountRequestModified(token, idToken, requestIndex);
    }

    /**
     * @notice Modify offer
     */
    function modifyOffer (
        address userOffered,
        uint256 requestIndex,
        address tokenPayment,
        uint96 quantity,
        uint176 pricePerToken,
        uint40 lifetime
    ) external payable nonReentrant() {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        LibMarketplaceStorage.OfferStruct memory offer = mss.Offer[msg.sender][userOffered][requestIndex];

        if (tokenPayment != offer.tokenPayment) revert DifferentPaymentToken(offer.tokenPayment);
        if (block.timestamp < offer.time + offer.lifetime && offer.lifetime != 0) revert RequestNotExpired(offer.time + offer.lifetime - block.timestamp);

        uint256 oldDepositAmount = uint256(offer.quantity) * (offer.pricePerToken);
        uint256 newDepositAmount = uint256(pricePerToken) * uint256(quantity);

        if (!LibMarketplaceModifyRequestFacet.manageDepositPositionModified(tokenPayment, newDepositAmount, oldDepositAmount)) revert DepositFailed(tokenPayment, newDepositAmount, oldDepositAmount);

        offer.quantity = quantity;
        offer.pricePerToken = pricePerToken;
        offer.time = uint40(block.timestamp);
        offer.lifetime = lifetime;

        mss.Offer[msg.sender][userOffered][requestIndex] = offer;

        emit OfferModified(msg.sender, userOffered, requestIndex);
    }
}