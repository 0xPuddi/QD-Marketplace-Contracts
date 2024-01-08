// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IMarketplaceRequestFacet } from "../interfaces/IMarketplaceRequestFacet.sol";
import { IERC20 } from "../../shared/interfaces/IERC20.sol";

library LibMarketplaceModifyRequestFacet {
    /**
     * @notice Manage deposit when users modify the position
     */
    function manageDepositPositionModified (
        address tokenPayment,
        uint256 newDepositAmount,
        uint256 oldDepositAmount
    ) internal returns(bool) {
        if (tokenPayment != address(0)) {
            if (newDepositAmount >= oldDepositAmount) {
                IERC20(tokenPayment).transferFrom(msg.sender, address(this), newDepositAmount - oldDepositAmount);
            } else {
                IERC20(tokenPayment).transferFrom(address(this), msg.sender, oldDepositAmount - newDepositAmount);
            }
        } else {
            if (newDepositAmount >= oldDepositAmount) {
                if (msg.value < newDepositAmount - oldDepositAmount) revert IMarketplaceRequestFacet.ValueDepositedInsufficient(msg.value);
            } else {
                (bool success, ) = msg.sender.call{value: oldDepositAmount - newDepositAmount}("");
                require(success, "Transfer failed.");
            }   
        }
        return true;
    }
}