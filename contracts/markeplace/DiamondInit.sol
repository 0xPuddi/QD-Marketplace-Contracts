// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { LibMarketplaceStorage } from "./libraries/LibMarketplaceStorage.sol";

import {LibDiamond} from "../shared/libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../shared/interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../shared/interfaces/IDiamondCut.sol";
import { IERC173 } from "../shared/interfaces/IERC173.sol";
import { IERC165 } from "../shared/interfaces/IERC165.sol";
import { IERC1155Receiver } from "../shared/interfaces/IERC1155Receiver.sol";
import { IERC721Receiver } from "../shared/interfaces/IERC721Receiver.sol";
import { IERC777Recipient } from "../shared/interfaces/IERC777Recipient.sol";
import { IERC777Sender } from "../shared/interfaces/IERC777Sender.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract DiamondInit {    

    // You can add parameters to this function in order to pass in 
    // data to set your own state variables
    // address validatorSharesAddress
    function init() external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC1155Receiver).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Receiver).interfaceId] = true;
        ds.supportedInterfaces[type(IERC777Recipient).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Receiver).interfaceId] = true;

        // add your own state variables 
        // EIP-2535 specifies that the `diamondCut` function takes two optional 
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface

        LibMarketplaceStorage.MarketplaceStorageStruct storage mss = LibMarketplaceStorage.getMarketplaceStoragePosition();
        // Utils
        mss.PERCENTAGE_PRECISION = 1e18;
        mss.ONE_PERCENT = 1e16;
        // Min english bid amount increse
        mss.minEnglishListingBidAmountIncrease = 1e18;
        // Add native as bidding token
        mss.biddingTokensApproval[address(0)] = true;
        // Add validator token
        // mss.tokenExemptFee[validatorSharesAddress] = true;
        // mss.listingTokensApproval1155[validatorSharesAddress] = true;
        // mss.listingTokensIndexes1155[validatorSharesAddress] = mss.listingTokens.length;
        // mss.listingTokens1155.push(validatorSharesAddress);
    }


}
