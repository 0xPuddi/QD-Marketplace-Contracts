// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { IMarketplaceOwnerFacet } from "../interfaces/IMarketplaceOwnerFacet.sol";

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import { IERC165 } from "../../shared/interfaces/IERC165.sol";
import { IERC20 } from "../../shared/interfaces/IERC20.sol";
import { IERC721 } from "../../shared/interfaces/IERC721.sol";
import { IERC777 } from "../../shared/interfaces/IERC777.sol";
import { IERC1155 } from "../../shared/interfaces/IERC1155.sol";

/**
 * @notice Marketplace owner facet
 * 
 * @dev Contains:
 * {addListingToken}
 * {removeListingToken}
 * {addBiddingToken}
 * {removeBiddingToken}
 * {forceAddToken}
 * {forceRemoveToken}
 * {setListingsPause}
 * {setBidsPause}
 * {setRequestsPause}
 * {setOffersPause}
 */
contract MarketplaceOwnerFacet is IMarketplaceOwnerFacet {
    /**
     * @notice Add and remove listing token, either ERC721 or ERC1155
     */
    function addListingToken(address tokenAddress) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Correct type
        if (IERC165(tokenAddress).supportsInterface(type(IERC721).interfaceId)) {
            // Check presence
            if (mss.listingTokensApproval721[tokenAddress]) revert TokenAlreadyListed(tokenAddress);
            // Add it
            mss.listingTokensApproval721[tokenAddress] = true;
            mss.listingTokensIndexes721[tokenAddress] = mss.listingTokens721.length;
            mss.listingTokens721.push(tokenAddress);
            setDefaultFeeAndWeights(tokenAddress);
            emit ListingTokenAdded(tokenAddress, block.timestamp);
        } else if (IERC165(tokenAddress).supportsInterface(type(IERC1155).interfaceId)) {
            // Check presence
            if (mss.listingTokensApproval1155[tokenAddress]) revert TokenAlreadyListed(tokenAddress);
            // Add it
            mss.listingTokensApproval1155[tokenAddress] = true;
            mss.listingTokensIndexes1155[tokenAddress] = mss.listingTokens1155.length;
            mss.listingTokens1155.push(tokenAddress);
            setDefaultFeeAndWeights(tokenAddress);
            emit ListingTokenAdded(tokenAddress, block.timestamp);
        } else {
            revert WrongTokenType(tokenAddress);
        }

        return true;
    }
    function removeListingToken(address tokenAddress) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Check presence
        if (mss.listingTokensApproval721[tokenAddress]) {
            // Remove it
            delete mss.listingTokensApproval721[tokenAddress];
            mss.listingTokens721[mss.listingTokensIndexes721[tokenAddress]] = mss.listingTokens721[mss.listingTokens721.length - 1];
            mss.listingTokens721.pop();
            delete mss.listingTokensIndexes721[tokenAddress];
            delteFeeAndWeights(tokenAddress);
            emit ListingTokenRemoved(tokenAddress, block.timestamp);
        } else if (mss.listingTokensApproval1155[tokenAddress]) {
            // Remove it
            delete mss.listingTokensApproval1155[tokenAddress];
            mss.listingTokens1155[mss.listingTokensIndexes1155[tokenAddress]] = mss.listingTokens1155[mss.listingTokens1155.length - 1];
            mss.listingTokens1155.pop();
            delete mss.listingTokensIndexes1155[tokenAddress];
            delteFeeAndWeights(tokenAddress);
            emit ListingTokenRemoved(tokenAddress, block.timestamp);
        } else {
            revert TokenNotListed(tokenAddress);
        }

        return true;
    }

    /**
     * @notice Add and remove bidding token
     */
    function addBiddingToken(address tokenAddress) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Correct type
        if (!IERC165(tokenAddress).supportsInterface(type(IERC20).interfaceId)) revert WrongTokenType(tokenAddress);

        // Check presence
        if (mss.biddingTokensApproval[tokenAddress]) revert TokenAlreadyListed(tokenAddress);

        // Add it
        mss.biddingTokensApproval[tokenAddress] = true;
        mss.biddingTokensIndexes[tokenAddress] = mss.biddingTokens.length;
        mss.biddingTokens.push(tokenAddress);
        emit BiddingTokenAdded(tokenAddress, block.timestamp);

        return true;
    }
    function removeBiddingToken(address tokenAddress) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Check presence
        if (!mss.biddingTokensApproval[tokenAddress]) revert TokenNotListed(tokenAddress);

        // Remove it
        delete mss.biddingTokensApproval[tokenAddress];
        mss.biddingTokens[mss.biddingTokensIndexes[tokenAddress]] = mss.biddingTokens[mss.biddingTokens.length - 1];
        mss.biddingTokens.pop();
        delete mss.biddingTokensIndexes[tokenAddress];
        emit BiddingTokenRemoved(tokenAddress, block.timestamp);

        return true;
    }

    /**
     * @notice Force add and remove tokens without token interface nedded
     * @param tokenType:
     * 0 = ERC20
     * 1 = ERC721
     * 2 = ERC1155
     */
    function forceAddToken(address tokenAddress, LibMarketplaceStorage.TokenTypes tokenType) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Add token
        if (tokenType == LibMarketplaceStorage.TokenTypes.ERC721) {
            // Check presence
            if (mss.listingTokensApproval721[tokenAddress]) revert TokenAlreadyListed(tokenAddress);
            // Add it
            mss.listingTokensApproval721[tokenAddress] = true;
            mss.listingTokensIndexes721[tokenAddress] = mss.listingTokens721.length;
            mss.listingTokens721.push(tokenAddress);
            setDefaultFeeAndWeights(tokenAddress);
            emit ListingTokenAdded(tokenAddress, block.timestamp);
        } else if (tokenType == LibMarketplaceStorage.TokenTypes.ERC1155) {
            // Check presence
            if (mss.listingTokensApproval1155[tokenAddress]) revert TokenAlreadyListed(tokenAddress);
            // Add it
            mss.listingTokensApproval1155[tokenAddress] = true;
            mss.listingTokensIndexes1155[tokenAddress] = mss.listingTokens1155.length;
            mss.listingTokens1155.push(tokenAddress);
            setDefaultFeeAndWeights(tokenAddress);
            emit ListingTokenAdded(tokenAddress, block.timestamp);
        } else if (tokenType == LibMarketplaceStorage.TokenTypes.ERC20) {
            // Check presence
            if (mss.biddingTokensApproval[tokenAddress]) revert TokenAlreadyListed(tokenAddress);
            // Add it
            mss.biddingTokensApproval[tokenAddress] = true;
            mss.biddingTokensIndexes[tokenAddress] = mss.biddingTokens.length;
            mss.biddingTokens.push(tokenAddress);
            emit BiddingTokenAdded(tokenAddress, block.timestamp);
        } else {
            revert WrongTokenType(tokenAddress);
        }

        return true;
    }
    function forceRemoveToken(address tokenAddress, LibMarketplaceStorage.TokenTypes tokenType) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        // Remove token
        if (tokenType == LibMarketplaceStorage.TokenTypes.ERC721) {
            // Check presence
            if (!mss.listingTokensApproval721[tokenAddress]) revert TokenNotListed(tokenAddress);
            // Remove it
            delete mss.listingTokensApproval721[tokenAddress];
            mss.listingTokens721[mss.listingTokensIndexes721[tokenAddress]] = mss.listingTokens721[mss.listingTokens721.length - 1];
            mss.listingTokens721.pop();
            delete mss.listingTokensIndexes721[tokenAddress];
            delteFeeAndWeights(tokenAddress);
            emit ListingTokenRemoved(tokenAddress, block.timestamp);
        } else if (tokenType == LibMarketplaceStorage.TokenTypes.ERC1155) {
            // Check presence
            if (!mss.listingTokensApproval1155[tokenAddress]) revert TokenNotListed(tokenAddress);
            // Remove it
            delete mss.listingTokensApproval1155[tokenAddress];
            mss.listingTokens1155[mss.listingTokensIndexes1155[tokenAddress]] = mss.listingTokens1155[mss.listingTokens1155.length - 1];
            mss.listingTokens1155.pop();
            delete mss.listingTokensIndexes1155[tokenAddress];
            delteFeeAndWeights(tokenAddress);
            emit ListingTokenRemoved(tokenAddress, block.timestamp);
        } else if (tokenType == LibMarketplaceStorage.TokenTypes.ERC20) {
            // Check presence
            if (!mss.biddingTokensApproval[tokenAddress]) revert TokenNotListed(tokenAddress);
            // Remove it
            delete mss.biddingTokensApproval[tokenAddress];
            mss.biddingTokens[mss.biddingTokensIndexes[tokenAddress]] = mss.biddingTokens[mss.biddingTokens.length - 1];
            mss.biddingTokens.pop();
            delete mss.biddingTokensIndexes[tokenAddress];
            emit BiddingTokenRemoved(tokenAddress, block.timestamp);
        } else {
            revert WrongTokenType(tokenAddress);
        }

        return true;
    }

    /**
     * @notice Set pause listings
     * @param _type:
     * 0 = standard listing {SL}
     * 1 = timer listing {TL}
     * 2 = dutch lisitng {DL}
     * 3 = english listing {EL}
     * 4 = sealed bid listing {SBL}
     */
    function setListingsPause(bool pause, LibMarketplaceStorage.SellingListingTypes _type) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        mss.pauseListings[_type] = pause;

        emit ListingsPaused(pause, block.timestamp);

        return true;
    }

    /**
     * @notice Set pause bids
     * @param _type:
     * 0 = english bid {EB}
     * 1 = sealed bid bid {SBB}
     */
    function setBidsPause(bool pause, LibMarketplaceStorage.SellingBidTypes _type) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        mss.pauseBids[_type] = pause;

        emit BidsPaused(pause, block.timestamp);

        return true;
    }

    /**
     * @notice Set pause requests
     * @param _type:
     * 0 = Standard request {SR}
     * 1 = Timer request {TR}
     * 2 = Dutch request {DR}
     * 3 = Amount request {AR}
     */
    function setRequestsPause(bool pause, LibMarketplaceStorage.BuyingRequestTypes _type) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        mss.pauseRequests[_type] = pause;

        emit RequestsPaused(pause, block.timestamp);

        return true;
    }

    /**
     * @notice Set percentage precision
     */
    function setPercentagePrecision(uint256 percentagePrecision) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        uint256 OLD_PERCENTAGE_PRECISION = mss.PERCENTAGE_PRECISION;

        /**
         * Change percentages Marketplace accordingly, if it gets too expensive reconsider not changing percentage or
         * clearing tokens listed on the marketplace.
         * To change precision := newPrecision = oldPrecision * coefficient
         * In which coefficient = NEW_PERCENTAGE_PRECISION / OLD_PERCENTAGE_PRECISION
         */
        mss.minDiscountAR1155 *= percentagePrecision / OLD_PERCENTAGE_PRECISION;

        address[] memory _listingTokens721 = mss.listingTokens721;
        for (uint256 i = 0; i < _listingTokens721.length; ) {
            LibMarketplaceStorage.MarketplaceFeesStruct memory marketplaceFeesStruct = mss.collectionFeeStructure[_listingTokens721[i]];
            marketplaceFeesStruct.collectionWeightFee_PERCENTAGE = uint80(uint256(marketplaceFeesStruct.collectionWeightFee_PERCENTAGE) * percentagePrecision / OLD_PERCENTAGE_PRECISION);
            marketplaceFeesStruct.tokenWeightFee_PERCENTAGE = uint80(uint256(marketplaceFeesStruct.tokenWeightFee_PERCENTAGE) * percentagePrecision / OLD_PERCENTAGE_PRECISION);
            marketplaceFeesStruct.marketplaceFee_PERCENTAGE = uint80(uint256(marketplaceFeesStruct.marketplaceFee_PERCENTAGE) * percentagePrecision / OLD_PERCENTAGE_PRECISION);
            mss.collectionFeeStructure[_listingTokens721[i]] = marketplaceFeesStruct;
            unchecked {
                ++i;
            }
        }

        address[] memory _listingTokens1155 = mss.listingTokens1155;
        for (uint256 i = 0; i < _listingTokens1155.length; ) {
            LibMarketplaceStorage.MarketplaceFeesStruct memory marketplaceFeesStruct = mss.collectionFeeStructure[_listingTokens1155[i]];
            marketplaceFeesStruct.collectionWeightFee_PERCENTAGE = uint80(uint256(marketplaceFeesStruct.collectionWeightFee_PERCENTAGE) * percentagePrecision / OLD_PERCENTAGE_PRECISION);
            marketplaceFeesStruct.tokenWeightFee_PERCENTAGE = uint80(uint256(marketplaceFeesStruct.tokenWeightFee_PERCENTAGE) * percentagePrecision / OLD_PERCENTAGE_PRECISION);
            marketplaceFeesStruct.marketplaceFee_PERCENTAGE = uint80(uint256(marketplaceFeesStruct.marketplaceFee_PERCENTAGE) * percentagePrecision / OLD_PERCENTAGE_PRECISION);
            mss.collectionFeeStructure[_listingTokens1155[i]] = marketplaceFeesStruct;
            unchecked {
                ++i;
            }
        }

        mss.PERCENTAGE_PRECISION = percentagePrecision;
        mss.ONE_PERCENT = percentagePrecision / 100;

        emit PercentagePrecision(percentagePrecision, percentagePrecision / 100, block.timestamp);

        return true;
    }

    /**
     * @notice Set min discount AR - how do I check if discount is correct number scale?
     */
    function setMinDiscountAR(uint256 discount) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        if (discount > mss.PERCENTAGE_PRECISION) {
            revert ErrorMinDiscountAR(discount);
        }

        mss.minDiscountAR1155 = discount;

        emit MinDiscountAR(discount, block.timestamp);

        return true;
    }

    /**
     * @notice Set custom marketplace fee and weights - how do I check if marketplaceFee is correct number scale?
     */
    function setCustomMarketplaceFeeAndWeights(address token, uint256 marketplaceFee, uint256 collectionWeight, uint256 tokenWeight, bool exemptFee, bool exemptFeeDiscount) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        if(!mss.listingTokensApproval721[token] && !mss.listingTokensApproval1155[token]) revert TokenNotListed(token);

        uint256 PERCENTAGE_PRECISION = LibMarketplaceStorage.returnPercentagePrecision();

        // Check underflow, overflow and precision
        if (collectionWeight + tokenWeight != PERCENTAGE_PRECISION) revert CustomFeeAndWeights(marketplaceFee, collectionWeight, tokenWeight);
        if (marketplaceFee > PERCENTAGE_PRECISION) revert CustomFeeAndWeights(marketplaceFee, collectionWeight, tokenWeight);

        // Set
        mss.collectionFeeStructure[token] = LibMarketplaceStorage.MarketplaceFeesStruct({
            tokenExemptFee: exemptFee,
            tokenExemptFeeDiscount: exemptFeeDiscount,
            collectionWeightFee_PERCENTAGE: uint80(collectionWeight),
            tokenWeightFee_PERCENTAGE: uint80(tokenWeight),
            marketplaceFee_PERCENTAGE: uint80(marketplaceFee)
        });

        emit CollectionFeeAndWeights(token, marketplaceFee, collectionWeight, tokenWeight, exemptFee, exemptFeeDiscount);

        return true;
    }

    /**
     * @notice Set collection fee actors and relative percentages, order actors with their percentage: actor[0] = feePercentages[0]
     */
    function setCollectionFeeActorsAndPercentages(address token, address[] memory actors, uint256[] memory feePercentages) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        if(!mss.listingTokensApproval721[token] && !mss.listingTokensApproval1155[token]) revert TokenNotListed(token);

        uint256 PERCENTAGE_PRECISION = LibMarketplaceStorage.returnPercentagePrecision();

        uint256 length = feePercentages.length;
        uint256 totPercentage;

        // Check underflow, overflow and precision
        if (actors.length != length) revert ActorsAndPercentages(token, actors, feePercentages);
        for (uint256 i = 0; i < length; ) {
            totPercentage += feePercentages[i];
            if (i == (length - 1) && totPercentage != PERCENTAGE_PRECISION) revert ActorsAndPercentages(token, actors, feePercentages);
            unchecked {
                ++i;
            }
        }

        // Set
        mss.collectionFeeActors[token] = actors;
        for (uint256 i = 0; i < length; ) {
            mss.percentageFeeCollectionActors[token][actors[i]] = feePercentages[i];
            unchecked {
                ++i;
            }
        }

        emit CollectionActorsAndPercentages(token, actors, feePercentages);

        return true;
    }

    /**
     * @notice Set minimum english eisting bid amount increase
     */
    function setMinEnglishListingBidAmountIncrease(uint256 minEnglishListingBidAmountIncreaseInWei) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        require(minEnglishListingBidAmountIncreaseInWei > 0, 'CANT_BE_0_VALUE');

        uint256 oldMinEnglishListingBidAmountIncreaseInWei = mss.minEnglishListingBidAmountIncrease;
        mss.minEnglishListingBidAmountIncrease = minEnglishListingBidAmountIncreaseInWei;

        emit settedMinEnglishListingBidAmountIncrease(minEnglishListingBidAmountIncreaseInWei, oldMinEnglishListingBidAmountIncreaseInWei, block.timestamp);

        return true;
    }

    /**
     * @notice Set default marketplace fee and weights and delete fee and weights
     */
    function setDefaultFeeAndWeights(address token) private returns(bool) {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        uint256 ONE_PERCENT = LibMarketplaceStorage.returnOnePercent();
        mss.collectionFeeStructure[token] = LibMarketplaceStorage.MarketplaceFeesStruct({
            tokenExemptFee: false,
            tokenExemptFeeDiscount: false,
            collectionWeightFee_PERCENTAGE: uint80(ONE_PERCENT * 75),
            tokenWeightFee_PERCENTAGE: uint80(ONE_PERCENT * 25),
            marketplaceFee_PERCENTAGE: uint80(ONE_PERCENT * 2)
        });

        return true;
    }
    function delteFeeAndWeights(address token) private returns(bool) {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        delete mss.collectionFeeStructure[token];

        return true;
    }
}