// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { IMarketplaceFulfillListingFacet } from "../interfaces/IMarketplaceFulfillListingFacet.sol";
import { IMarketplaceFulfillEnglishListingFacet } from "../interfaces/IMarketplaceFulfillEnglishListingFacet.sol";

import { LibDiamond } from "../../shared/libraries/LibDiamond.sol";
import { LibString } from "../../shared/libraries/LibString.sol";
import { IERC165 } from "../../shared/interfaces/IERC165.sol";
import { IERC2981 } from "../../shared/interfaces/IERC2981.sol";
import { IERC20 } from "../../shared/interfaces/IERC20.sol";
import { IERC721 } from "../../shared/interfaces/IERC721.sol";
import { IERC1155 } from "../../shared/interfaces/IERC1155.sol";

library LibMarketplaceFulfillListingFacet {
    /**
     * @notice Manage royalties function
     */
    function royaltiesManager(
        uint256 payment,
        address token,
        uint256 idToken,
        address from,
        address tokenPayment,
        bool biddingTokensApproval
    ) internal returns(uint256) {
        if (IERC165(token).supportsInterface(type(IERC2981).interfaceId)) {
            (address receiver, uint256 royaltyAmount) = IERC2981(token).royaltyInfo(idToken, payment);
            if (tokenPayment == address(0) && biddingTokensApproval) {
                (bool success, ) = receiver.call{value:royaltyAmount}("");
                require(success, "Transfer failed.");
            } else if (biddingTokensApproval) {
                IERC20(tokenPayment).transferFrom(from, receiver, royaltyAmount);
            } else {
                revert IMarketplaceFulfillListingFacet.MissingTokenTransfer(tokenPayment);
            }
            return royaltyAmount;
        } else {
            return 0;
        }
    }

    /**
     * @notice Manage marketplace fee function
     */
    struct MarketplaceFeeManagerStruct {
        uint256 payment;
        address token;
        uint256 idToken;
        address tokenPayment;
        address from;
        bool biddingTokensApproval;
        LibMarketplaceStorage.SellingListingTypes listingType;
        uint256 PERCENTAGE_PRECISION;
        uint256 marketplaceFee;
        address[] collectionFeeActors;
    }
    function marketplaceFeeManager(
        uint256 payment,
        address token,
        uint256 idToken,
        address tokenPayment,
        address from,
        bool biddingTokensApproval,
        LibMarketplaceStorage.SellingListingTypes listingType
    ) internal returns(uint256) {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        LibMarketplaceStorage.MarketplaceFeesStruct memory marketplaceFeesStruct = mss.collectionFeeStructure[token];

        MarketplaceFeeManagerStruct memory marketplaceFeeManagerStruct;
        marketplaceFeeManagerStruct.payment = payment;
        marketplaceFeeManagerStruct.idToken= idToken;
        marketplaceFeeManagerStruct.token = token;
        marketplaceFeeManagerStruct.tokenPayment = tokenPayment;
        marketplaceFeeManagerStruct.from = from;
        marketplaceFeeManagerStruct.biddingTokensApproval = biddingTokensApproval;
        marketplaceFeeManagerStruct.listingType = listingType;
        marketplaceFeeManagerStruct.PERCENTAGE_PRECISION = LibMarketplaceStorage.returnPercentagePrecision();

        if (marketplaceFeesStruct.tokenExemptFee) {
            return 0;
        } else {
            if (marketplaceFeesStruct.tokenExemptFeeDiscount) {
                marketplaceFeeManagerStruct.marketplaceFee = payment * marketplaceFeesStruct.marketplaceFee_PERCENTAGE / marketplaceFeeManagerStruct.PERCENTAGE_PRECISION;
                marketplaceFeeManagerStruct.collectionFeeActors = mss.collectionFeeActors[token];

                if (marketplaceFeeManagerStruct.tokenPayment == address(0) && marketplaceFeeManagerStruct.biddingTokensApproval) {
                    if (marketplaceFeeManagerStruct.collectionFeeActors.length == 0) {
                        (bool success, ) = LibDiamond.contractOwner().call{value:marketplaceFeeManagerStruct.marketplaceFee}("");
                        require(success, "Transfer failed.");
                    } else {
                        for (uint256 i = 0; i < marketplaceFeeManagerStruct.collectionFeeActors.length; ) {
                            (bool success, ) = marketplaceFeeManagerStruct.collectionFeeActors[i].call{value: (marketplaceFeeManagerStruct.marketplaceFee * mss.percentageFeeCollectionActors[token][marketplaceFeeManagerStruct.collectionFeeActors[i]] / marketplaceFeeManagerStruct.PERCENTAGE_PRECISION) }("");
                            require(success, "Transfer failed.");
                            unchecked {
                                ++i;
                            }
                        }
                    }
                } else if (marketplaceFeeManagerStruct.biddingTokensApproval) {
                    if (marketplaceFeeManagerStruct.collectionFeeActors.length == 0) {
                        IERC20(marketplaceFeeManagerStruct.tokenPayment).transferFrom(marketplaceFeeManagerStruct.from, LibDiamond.contractOwner(), marketplaceFeeManagerStruct.marketplaceFee);
                    } else {
                        for (uint256 i = 0; i < marketplaceFeeManagerStruct.collectionFeeActors.length; ) {
                            (bool success, ) = marketplaceFeeManagerStruct.collectionFeeActors[i].call{value: (marketplaceFeeManagerStruct.marketplaceFee * mss.percentageFeeCollectionActors[marketplaceFeeManagerStruct.token][marketplaceFeeManagerStruct.collectionFeeActors[i]] / marketplaceFeeManagerStruct.PERCENTAGE_PRECISION) }("");
                            require(success, "Transfer failed.");
                            IERC20(tokenPayment).transferFrom(marketplaceFeeManagerStruct.from, marketplaceFeeManagerStruct.collectionFeeActors[i], (marketplaceFeeManagerStruct.marketplaceFee * mss.percentageFeeCollectionActors[marketplaceFeeManagerStruct.token][marketplaceFeeManagerStruct.collectionFeeActors[i]] / marketplaceFeeManagerStruct.PERCENTAGE_PRECISION));
                            unchecked {
                                ++i;
                            }
                        }
                    }
                } else {
                    revert IMarketplaceFulfillListingFacet.MissingTokenTransfer(marketplaceFeeManagerStruct.tokenPayment);
                }

                return marketplaceFeeManagerStruct.marketplaceFee;
            } else {
                marketplaceFeeManagerStruct.marketplaceFee = calculateMarketplaceFee(marketplaceFeesStruct, marketplaceFeeManagerStruct.token, marketplaceFeeManagerStruct.idToken, marketplaceFeeManagerStruct.listingType, marketplaceFeeManagerStruct.payment, marketplaceFeeManagerStruct.PERCENTAGE_PRECISION);
                marketplaceFeeManagerStruct.collectionFeeActors = mss.collectionFeeActors[token];
                
                if (marketplaceFeeManagerStruct.tokenPayment == address(0) && marketplaceFeeManagerStruct.biddingTokensApproval) {
                    if (marketplaceFeeManagerStruct.collectionFeeActors.length == 0) {
                        (bool success, ) = LibDiamond.contractOwner().call{value:marketplaceFeeManagerStruct.marketplaceFee}("");
                        require(success, "Transfer failed.");
                    } else {
                        for (uint256 i = 0; i < marketplaceFeeManagerStruct.collectionFeeActors.length; ) {
                            (bool success, ) = marketplaceFeeManagerStruct.collectionFeeActors[i].call{value: (marketplaceFeeManagerStruct.marketplaceFee * mss.percentageFeeCollectionActors[marketplaceFeeManagerStruct.token][marketplaceFeeManagerStruct.collectionFeeActors[i]] / marketplaceFeeManagerStruct.PERCENTAGE_PRECISION) }("");
                            require(success, "Transfer failed.");
                            unchecked {
                                ++i;
                            }
                        }
                    }
                } else if (marketplaceFeeManagerStruct.biddingTokensApproval) {
                    if (marketplaceFeeManagerStruct.collectionFeeActors.length == 0) {
                        IERC20(tokenPayment).transferFrom(marketplaceFeeManagerStruct.from, LibDiamond.contractOwner(), marketplaceFeeManagerStruct.marketplaceFee);
                    } else {
                        for (uint256 i = 0; i < marketplaceFeeManagerStruct.collectionFeeActors.length; ) {
                            (bool success, ) = marketplaceFeeManagerStruct.collectionFeeActors[i].call{value: (marketplaceFeeManagerStruct.marketplaceFee * mss.percentageFeeCollectionActors[marketplaceFeeManagerStruct.token][marketplaceFeeManagerStruct.collectionFeeActors[i]] / marketplaceFeeManagerStruct.PERCENTAGE_PRECISION) }("");
                            require(success, "Transfer failed.");
                            IERC20(tokenPayment).transferFrom(marketplaceFeeManagerStruct.from, marketplaceFeeManagerStruct.collectionFeeActors[i], (marketplaceFeeManagerStruct.marketplaceFee * mss.percentageFeeCollectionActors[marketplaceFeeManagerStruct.token][marketplaceFeeManagerStruct.collectionFeeActors[i]] / marketplaceFeeManagerStruct.PERCENTAGE_PRECISION));
                            unchecked {
                                ++i;
                            }
                        }
                    }
                } else {
                    revert IMarketplaceFulfillListingFacet.MissingTokenTransfer(marketplaceFeeManagerStruct.tokenPayment);
                }

                mss.collectionTotalListingsVolume[token][listingType] += payment;
                mss.tokenOverallVolume[token][idToken] += payment;

                return marketplaceFeeManagerStruct.marketplaceFee;
            }
        }
    }

    /**
     * @notice Calculate merketplace fee
     */
    struct CalculateMarketplaceFeeStruct {
        LibMarketplaceStorage.MarketplaceFeesStruct marketplaceFeesStruct;
        address token;
        uint256 idToken;
        uint256 payment;
        uint256 _PERCENTAGE_PRECISION;
        uint256 _ONE_PERCENT;
        uint256 _collectionTotalListingsVolume;
        uint256 _tokenOverallVolume;
    }
    function calculateMarketplaceFee(
        LibMarketplaceStorage.MarketplaceFeesStruct memory marketplaceFeesStruct,
        address token,
        uint256 idToken,
        LibMarketplaceStorage.SellingListingTypes listingType,
        uint256 payment,
        uint256 _PERCENTAGE_PRECISION
    ) internal view returns(uint256) {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        CalculateMarketplaceFeeStruct memory calculateMarketplaceFeeStruct;
        calculateMarketplaceFeeStruct.marketplaceFeesStruct = marketplaceFeesStruct;
        calculateMarketplaceFeeStruct.token = token;
        calculateMarketplaceFeeStruct.idToken = idToken;
        calculateMarketplaceFeeStruct.payment = payment;
        calculateMarketplaceFeeStruct._PERCENTAGE_PRECISION = _PERCENTAGE_PRECISION;
        calculateMarketplaceFeeStruct._ONE_PERCENT = _PERCENTAGE_PRECISION / 100;

        calculateMarketplaceFeeStruct._collectionTotalListingsVolume = mss.collectionTotalListingsVolume[token][listingType];
        calculateMarketplaceFeeStruct._tokenOverallVolume = mss.tokenOverallVolume[token][idToken];

        uint256 totVolumeWeight = (
            calculateMarketplaceFeeStruct._collectionTotalListingsVolume * 
            marketplaceFeesStruct.collectionWeightFee_PERCENTAGE
            / calculateMarketplaceFeeStruct._PERCENTAGE_PRECISION
        ) + (
            calculateMarketplaceFeeStruct._tokenOverallVolume *
            marketplaceFeesStruct.tokenWeightFee_PERCENTAGE
            / calculateMarketplaceFeeStruct._PERCENTAGE_PRECISION
        );

        if (totVolumeWeight >= 75 * calculateMarketplaceFeeStruct._ONE_PERCENT) {
            return payment *
            (
                uint256(marketplaceFeesStruct.marketplaceFee_PERCENTAGE) *
                (25 * calculateMarketplaceFeeStruct._ONE_PERCENT)
                / calculateMarketplaceFeeStruct._PERCENTAGE_PRECISION
            )
            / calculateMarketplaceFeeStruct._PERCENTAGE_PRECISION;
        } else {
            return payment *
            (
                uint256(marketplaceFeesStruct.marketplaceFee_PERCENTAGE) *
                (
                    calculateMarketplaceFeeStruct._PERCENTAGE_PRECISION - totVolumeWeight
                ) / calculateMarketplaceFeeStruct._PERCENTAGE_PRECISION
            )
            / calculateMarketplaceFeeStruct._PERCENTAGE_PRECISION;
        }
    }

    /**
     * @notice Manage transfers
     */
    function manageTransfers(
        uint256 payment,
        uint256 idToken,
        uint256 quantity,
        address tokenPayment,
        address ownerListing,
        address fulfillerListing,
        bool alreadyDeposited,
        address token,
        bool biddingTokensApproval
    ) internal {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        if (tokenPayment == address(0)) {
            (bool success, ) = ownerListing.call{value:payment}("");
            require(success, "Transfer failed.");
        } else if (biddingTokensApproval) {
            if (alreadyDeposited) {
                IERC20(tokenPayment).transferFrom(address(this), ownerListing, payment);
            } else {
                IERC20(tokenPayment).transferFrom(fulfillerListing, ownerListing, payment);
            }
        } else {
            revert IMarketplaceFulfillListingFacet.MissingTokenTransfer(tokenPayment);
        }

        if (mss.listingTokensApproval1155[token]) {
            IERC1155(token).safeTransferFrom(address(this), fulfillerListing, idToken, quantity, "0x");
        } else if (mss.listingTokensApproval721[token]) {
            IERC721(token).safeTransferFrom(address(this), fulfillerListing, idToken);
        } else {
            revert IMarketplaceFulfillListingFacet.MissingTokenTransfer(token);
        }
    }

    /**
     * @notice Calculate dutch listing price
     * Pdl = Pinitial - ((Pinitial - Pfinal) * (Tcurrent - Tinitial) / (Tfinal - Tinitial))
     */
    function calculateDutchListingPrice(
        uint256 quantity,
        uint256 pricePerToken,
        uint256 leastPricePerToken,
        uint256 time
    ) internal view returns(uint256){
        return (
            quantity *
            (pricePerToken - (
                (pricePerToken - leastPricePerToken) *
                (block.timestamp - time) / time)
            )
        );
    }

    /**
     * @notice Check sealed bid hash
     */
    function checkSealedBidHash(
        bytes32 passwordHash,
        string memory passwordHashPlacer,
        uint256 pricePerToken
    ) internal pure returns(bool) {

        if (!LibString.contains(
            LibString.toSlice(passwordHashPlacer), LibString.toSlice('-')
            )) {
            return false;
        }

        if (keccak256(bytes(passwordHashPlacer)) == passwordHash &&
            LibString.equals(
            LibString.toSlice(LibString.returnFetchedString(passwordHashPlacer, '-')),
            LibString.toSlice(LibString.toStringNumber(pricePerToken))
            )) {
            return true;
        }

        return false;
    }

    /**
     * @notice Manage english bid transfers 116301
     */
    function manageEnglishBidDeposit(
        address addressHighestBidder,
        address tokenPayment,
        uint256 initialPricePerToken,
        uint256 minEnglishListingBidAmountIncrease,
        uint256 _PERCENTAGE_PRECISION,
        uint256 deposit,
        uint256 depositHighestBidder,
        uint80 pricePerTokenHighestBidder
    ) internal {
        if (addressHighestBidder == address(0)) {
            if (initialPricePerToken + (initialPricePerToken * minEnglishListingBidAmountIncrease / _PERCENTAGE_PRECISION) < deposit) {
                if (tokenPayment == address(0)) {
                    require(msg.value >= deposit, 'DEPOSIT_TOO_LOW');
                } else {
                    IERC20(tokenPayment).transferFrom(msg.sender, address(this), deposit);
                }
            } else {
                revert IMarketplaceFulfillEnglishListingFacet.EnglishBidTooLow(deposit);
            }
        } else {
            if (pricePerTokenHighestBidder + (pricePerTokenHighestBidder * minEnglishListingBidAmountIncrease / _PERCENTAGE_PRECISION) < deposit) {
                if (tokenPayment == address(0)) {
                    require(msg.value >= deposit, 'DEPOSIT_TOO_LOW');
                    (bool success, ) = addressHighestBidder.call{value: depositHighestBidder}("");
                    require(success, "Transfer failed.");
                } else {
                    IERC20(tokenPayment).transferFrom(msg.sender, address(this), deposit);
                    IERC20(tokenPayment).transferFrom(address(this), addressHighestBidder, depositHighestBidder);
                }
            } else {
                revert IMarketplaceFulfillEnglishListingFacet.EnglishBidTooLow(deposit);
            }
        }
    }
}