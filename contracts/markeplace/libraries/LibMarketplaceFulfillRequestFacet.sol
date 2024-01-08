// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";
import { LibMarketplaceFulfillListingFacet } from "../libraries/LibMarketplaceFulfillListingFacet.sol";

import { LibDiamond } from "../../shared/libraries/LibDiamond.sol";
import { IERC20 } from "../../shared/interfaces/IERC20.sol";
import { IERC721 } from "../../shared/interfaces/IERC721.sol";
import { IERC1155 } from "../../shared/interfaces/IERC1155.sol";
import { IERC2981 } from "../../shared/interfaces/IERC2981.sol";
import { IERC165 } from "../../shared/interfaces/IERC165.sol";

/**
 * @notice Marketplace fulfill request facet library
 */
library LibMarketplaceFulfillRequestFacet {
    /**
     * @notice Manage requests transfers
     */
    function manageRequestsTransfers(
        bool isERC721,
        address addressToken,
        uint256 idToken,
        uint256 quantity,
        address tokenPayment,
        uint256 payment,
        address offerer
    ) internal {
        if (isERC721) {
            IERC721(addressToken).safeTransferFrom(msg.sender, offerer, idToken);
        } else {
            IERC1155(addressToken).safeTransferFrom(msg.sender, offerer, idToken, quantity, "0x");
        }

        if (tokenPayment == address(0)) {
            (bool success, ) = msg.sender.call{value:payment}("");
            require(success, "Transfer failed.");
        } else {
            IERC20(tokenPayment).transferFrom(address(this), msg.sender, payment);
        }
    }

    /**
     * @notice Manage requests royalties
     */
    function manageRequestsRoyalties(
        address addressToken,
        uint256 idToken,
        address tokenPayment,
        uint256 payment
    ) internal returns(uint256) {
        if (IERC165(addressToken).supportsInterface(type(IERC2981).interfaceId)) {
            (address receiver, uint256 royaltyAmount) = IERC2981(addressToken).royaltyInfo(idToken, payment);

            if (tokenPayment == address(0)) {
                (bool success, ) = receiver.call{value:royaltyAmount}("");
                require(success, "Transfer failed.");
            } else {
                IERC20(tokenPayment).transferFrom(address(this), receiver, royaltyAmount);
            }

            return royaltyAmount;
        } else {
            return 0;
        }
    }

    /**
     * @notice Manage request marketplace fees
     */
    struct ManageRequestsMarketplaceFeeStruct {
        address addressToken;
        uint256 idToken;
        address tokenPayment;
        uint256 payment;
        address offerer;
        LibMarketplaceStorage.SellingListingTypes listingType;
        uint256 PERCENTAGE_PRECISION;
        uint256 marketplaceFee;
        address[] collectionFeeActors;
    }
    function manageRequestsMarketplaceFee(
        address addressToken,
        uint256 idToken,
        address tokenPayment,
        uint256 payment,
        LibMarketplaceStorage.SellingListingTypes listingType
    ) internal returns(uint256) {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        LibMarketplaceStorage.MarketplaceFeesStruct memory marketplaceFeesStruct = mss.collectionFeeStructure[addressToken];

        ManageRequestsMarketplaceFeeStruct memory manageRequestsMarketplaceFeeStruct;
        manageRequestsMarketplaceFeeStruct.addressToken = addressToken;
        manageRequestsMarketplaceFeeStruct.idToken= idToken;
        manageRequestsMarketplaceFeeStruct.tokenPayment = tokenPayment;
        manageRequestsMarketplaceFeeStruct.payment = payment;
        manageRequestsMarketplaceFeeStruct.listingType = listingType;
        manageRequestsMarketplaceFeeStruct.PERCENTAGE_PRECISION = LibMarketplaceStorage.returnPercentagePrecision();

        if (marketplaceFeesStruct.tokenExemptFee) {
            return 0;
        } else {
            if (marketplaceFeesStruct.tokenExemptFeeDiscount) {
                manageRequestsMarketplaceFeeStruct.marketplaceFee = manageRequestsMarketplaceFeeStruct.payment * marketplaceFeesStruct.marketplaceFee_PERCENTAGE / manageRequestsMarketplaceFeeStruct.PERCENTAGE_PRECISION;
                manageRequestsMarketplaceFeeStruct.collectionFeeActors = mss.collectionFeeActors[manageRequestsMarketplaceFeeStruct.addressToken];

                if (manageRequestsMarketplaceFeeStruct.tokenPayment == address(0)) {
                    if (manageRequestsMarketplaceFeeStruct.collectionFeeActors.length == 0) {
                        (bool success, ) = LibDiamond.contractOwner().call{value:manageRequestsMarketplaceFeeStruct.marketplaceFee}("");
                        require(success, "Transfer failed.");
                    } else {
                        for (uint256 i = 0; i < manageRequestsMarketplaceFeeStruct.collectionFeeActors.length; ) {
                            (bool success, ) = manageRequestsMarketplaceFeeStruct.collectionFeeActors[i].call{value: (manageRequestsMarketplaceFeeStruct.marketplaceFee * mss.percentageFeeCollectionActors[manageRequestsMarketplaceFeeStruct.addressToken][manageRequestsMarketplaceFeeStruct.collectionFeeActors[i]] / manageRequestsMarketplaceFeeStruct.PERCENTAGE_PRECISION) }("");
                            require(success, "Transfer failed.");
                            unchecked {
                                ++i;
                            }
                        }
                    }
                } else {
                    if (manageRequestsMarketplaceFeeStruct.collectionFeeActors.length == 0) {
                        IERC20(manageRequestsMarketplaceFeeStruct.tokenPayment).transferFrom(address(this), LibDiamond.contractOwner(), manageRequestsMarketplaceFeeStruct.marketplaceFee);
                    } else {
                        for (uint256 i = 0; i < manageRequestsMarketplaceFeeStruct.collectionFeeActors.length; ) {
                            (bool success, ) = manageRequestsMarketplaceFeeStruct.collectionFeeActors[i].call{value: (manageRequestsMarketplaceFeeStruct.marketplaceFee * mss.percentageFeeCollectionActors[manageRequestsMarketplaceFeeStruct.addressToken][manageRequestsMarketplaceFeeStruct.collectionFeeActors[i]] / manageRequestsMarketplaceFeeStruct.PERCENTAGE_PRECISION) }("");
                            require(success, "Transfer failed.");
                            IERC20(tokenPayment).transferFrom(address(this), manageRequestsMarketplaceFeeStruct.collectionFeeActors[i], (manageRequestsMarketplaceFeeStruct.marketplaceFee * mss.percentageFeeCollectionActors[manageRequestsMarketplaceFeeStruct.addressToken][manageRequestsMarketplaceFeeStruct.collectionFeeActors[i]] / manageRequestsMarketplaceFeeStruct.PERCENTAGE_PRECISION));
                            unchecked {
                                ++i;
                            }
                        }
                    }
                }

                return manageRequestsMarketplaceFeeStruct.marketplaceFee;
            } else {
                manageRequestsMarketplaceFeeStruct.marketplaceFee = LibMarketplaceFulfillListingFacet.calculateMarketplaceFee(marketplaceFeesStruct, manageRequestsMarketplaceFeeStruct.addressToken, manageRequestsMarketplaceFeeStruct.idToken, manageRequestsMarketplaceFeeStruct.listingType, manageRequestsMarketplaceFeeStruct.payment, manageRequestsMarketplaceFeeStruct.PERCENTAGE_PRECISION);
                manageRequestsMarketplaceFeeStruct.collectionFeeActors = mss.collectionFeeActors[manageRequestsMarketplaceFeeStruct.addressToken];
                
                if (manageRequestsMarketplaceFeeStruct.tokenPayment == address(0)) {
                    if (manageRequestsMarketplaceFeeStruct.collectionFeeActors.length == 0) {
                        (bool success, ) = LibDiamond.contractOwner().call{value:manageRequestsMarketplaceFeeStruct.marketplaceFee}("");
                        require(success, "Transfer failed.");
                    } else {
                        for (uint256 i = 0; i < manageRequestsMarketplaceFeeStruct.collectionFeeActors.length; ) {
                            (bool success, ) = manageRequestsMarketplaceFeeStruct.collectionFeeActors[i].call{value: (manageRequestsMarketplaceFeeStruct.marketplaceFee * mss.percentageFeeCollectionActors[manageRequestsMarketplaceFeeStruct.addressToken][manageRequestsMarketplaceFeeStruct.collectionFeeActors[i]] / manageRequestsMarketplaceFeeStruct.PERCENTAGE_PRECISION) }("");
                            require(success, "Transfer failed.");
                            unchecked {
                                ++i;
                            }
                        }
                    }
                } else {
                    if (manageRequestsMarketplaceFeeStruct.collectionFeeActors.length == 0) {
                        IERC20(manageRequestsMarketplaceFeeStruct.tokenPayment).transferFrom(address(this), LibDiamond.contractOwner(), manageRequestsMarketplaceFeeStruct.marketplaceFee);
                    } else {
                        for (uint256 i = 0; i < manageRequestsMarketplaceFeeStruct.collectionFeeActors.length; ) {
                            (bool success, ) = manageRequestsMarketplaceFeeStruct.collectionFeeActors[i].call{value: (manageRequestsMarketplaceFeeStruct.marketplaceFee * mss.percentageFeeCollectionActors[manageRequestsMarketplaceFeeStruct.addressToken][manageRequestsMarketplaceFeeStruct.collectionFeeActors[i]] / manageRequestsMarketplaceFeeStruct.PERCENTAGE_PRECISION) }("");
                            require(success, "Transfer failed.");
                            IERC20(tokenPayment).transferFrom(address(this), manageRequestsMarketplaceFeeStruct.collectionFeeActors[i], (manageRequestsMarketplaceFeeStruct.marketplaceFee * mss.percentageFeeCollectionActors[manageRequestsMarketplaceFeeStruct.addressToken][manageRequestsMarketplaceFeeStruct.collectionFeeActors[i]] / manageRequestsMarketplaceFeeStruct.PERCENTAGE_PRECISION));
                            unchecked {
                                ++i;
                            }
                        }
                    }
                }

                mss.collectionTotalListingsVolume[manageRequestsMarketplaceFeeStruct.addressToken][manageRequestsMarketplaceFeeStruct.listingType] += manageRequestsMarketplaceFeeStruct.payment;
                mss.tokenOverallVolume[manageRequestsMarketplaceFeeStruct.addressToken][manageRequestsMarketplaceFeeStruct.idToken] += manageRequestsMarketplaceFeeStruct.payment;

                return manageRequestsMarketplaceFeeStruct.marketplaceFee;
            }
        }
    }

    /**
     * @notice Manage amount requests discount
     */
    function manageAmountRequestsDiscount(
        uint256 _amountCostInWei,
        uint256 _quantityCostInWei
    ) view internal returns(uint256) {

        uint256 discount;

        uint256 amountRate = _amountCostInWei * 1e18 / _quantityCostInWei;

        uint256 coefficient = 1e18 / amountRate + 9;

        uint256 calculateDiscount = 1e16 + (((((2**coefficient) * 1e16) / 6) / amountRate ) * 1e16);

        if (calculateDiscount < 2e16) {
            discount = 2e16;
        } else if (calculateDiscount > 1e18) {
            discount = 1e18;
        } else {
            discount = calculateDiscount;
        }

        uint256 discountAmount = _amountCostInWei - (_amountCostInWei * discount / LibMarketplaceStorage.returnPercentagePrecision());

        return discountAmount;
    }
}