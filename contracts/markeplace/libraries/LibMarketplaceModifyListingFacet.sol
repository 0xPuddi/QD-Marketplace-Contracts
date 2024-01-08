// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibMarketplaceStorage } from "../libraries/LibMarketplaceStorage.sol";

import { IERC721 } from "../../shared/interfaces/IERC721.sol";
import { IERC1155 } from "../../shared/interfaces/IERC1155.sol";

library LibMarketplaceModifyListingFacet {
    /**
     * @notice Manage listing deposit
     */
    function manageListingDeposit(address token, uint256 idToken, uint96 oldQuantity, uint96 newQuantity) internal {
        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();

        if (mss.listingTokensApproval1155[token] == true) {
            if (oldQuantity < newQuantity) {
                IERC1155(token).safeTransferFrom(msg.sender, address(this), idToken, newQuantity - oldQuantity, "0x");
                mss.totAmount[token].totAmountSL1155 += newQuantity - oldQuantity;
            } else {
                IERC1155(token).safeTransferFrom(address(this), msg.sender, idToken, oldQuantity - newQuantity, "0x");
                mss.totAmount[token].totAmountSL1155 += oldQuantity - newQuantity;
            }
        } else if (mss.listingTokensApproval721[token] == true) {
            if (oldQuantity < newQuantity) {
                IERC721(token).safeTransferFrom(msg.sender, address(this), idToken, "0x");
            } else {
                IERC721(token).safeTransferFrom(address(this), msg.sender, idToken, "0x");
            }
        }
    }
}