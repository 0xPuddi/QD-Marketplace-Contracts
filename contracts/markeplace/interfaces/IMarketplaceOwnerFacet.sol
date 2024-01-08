// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";

interface IMarketplaceOwnerFacet {
    /**
     * @notice Custom errors
     */
    // Revert if wrong token type
    error WrongTokenType(address tokenAddress);
    // Revert if token already listed
    error TokenAlreadyListed(address tokenAddress);
    // Revert is minDiscountAR is wrong
    error ErrorMinDiscountAR(uint256 discount);
    // Revert if custom fees and weight are wrong
    error CustomFeeAndWeights(uint256 marketplaceFee, uint256 collectionWeight, uint256 tokenWeight);
    // Revert if actors and percentages are wrong
    error ActorsAndPercentages(address token, address[] actors, uint256[] percentages);
    // Revert if token is not listed
    error TokenNotListed(address token);

    /**
     * @notice Events
     */
    // Emit if a new token is listed
    event ListingTokenAdded(address indexed tokenAddress, uint256 time);
    // Emit if an old token is removed
    event ListingTokenRemoved(address indexed tokenAddress, uint256 time);
    // Emit if a new token is listed
    event BiddingTokenAdded(address indexed tokenAddress, uint256 time);
    // Emit if an old token is removed
    event BiddingTokenRemoved(address indexed tokenAddress, uint256 time);
    // Emit if listings pause changed
    event ListingsPaused(bool pause, uint256 time);
    // Emit if bids pause changed
    event BidsPaused(bool pause, uint256 time);
    // Emit if requests pause changed
    event RequestsPaused(bool pause, uint256 time);
    // Emit if new percentage precision is setted
    event PercentagePrecision(uint256 indexed percentagePrecision, uint256 onePercent, uint256 time);
    // Emit if new max discount AR is setted
    event MinDiscountAR(uint256 indexed discount, uint256 time);
    // Emit if new fee and weights for collection are set
    event CollectionFeeAndWeights(address indexed collection, uint256 collectionFee, uint256 collectionWeight, uint256 tokensWeight, bool exemptFee, bool exemptFeeDiscount);
    // Emit if new actors and percentages are set for a collection
    event CollectionActorsAndPercentages(address indexed collection, address[] actors, uint256[] percentages);
    // Emit if a new minimum english eisting bid amount increase
    event settedMinEnglishListingBidAmountIncrease(uint256 indexed newMinEnglishListingBidAmountIncrease, uint256 oldMinEnglishListingBidAmountIncrease, uint256 time);

    /**
     * @notice External functions
     */
    // Add a new token for listings
    function addListingToken(address tokenAddress) external returns(bool);
    // Remove token for listings
    function removeListingToken(address tokenAddress) external returns(bool);
    // Add a new token for biddings
    function addBiddingToken(address tokenAddress) external returns(bool);
    // Remove token for biddings
    function removeBiddingToken(address tokenAddress) external returns(bool);
    // Force add a new token for listings and biddings
    function forceAddToken(address tokenAddress, LibMarketplaceStorage.TokenTypes tokenType) external returns(bool);
    // Force remove a new token for listings and biddings
    function forceRemoveToken(address tokenAddress, LibMarketplaceStorage.TokenTypes tokenType) external returns(bool);
    // Set pause for listings
    function setListingsPause(bool pause, LibMarketplaceStorage.SellingListingTypes _type) external returns(bool);
    // Set pause for biddings
    function setBidsPause(bool pause, LibMarketplaceStorage.SellingBidTypes _type) external returns(bool);
    // Set pause for requests
    function setRequestsPause(bool pause, LibMarketplaceStorage.BuyingRequestTypes _type) external returns(bool);
    // Set new percentage precision
    function setPercentagePrecision(uint256 percentagePrecision) external returns(bool);
    // Set new min discount {AR}
    function setMinDiscountAR(uint256 discount) external returns(bool);
    // Set custom marketplace fee and weights
    function setCustomMarketplaceFeeAndWeights(address token, uint256 marketplaceFee, uint256 collectionWeight, uint256 tokenWeight, bool exemptFee, bool exemptFeeDiscount) external returns(bool);
    // Set actors and percentages
    function setCollectionFeeActorsAndPercentages(address token, address[] memory actors, uint256[] memory feePercentages) external returns(bool);
    // Set a new minimum english eisting bid amount increase
    function setMinEnglishListingBidAmountIncrease(uint256 minEnglishListingBidAmountIncreaseInWei) external returns(bool);
}