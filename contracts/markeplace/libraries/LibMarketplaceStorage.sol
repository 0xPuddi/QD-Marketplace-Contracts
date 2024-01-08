// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC1155 } from "../../shared/interfaces/IERC1155.sol";
import { IFirstAvalancheValidatorDepositFacet } from "../interfaces/IFirstAvalancheValidatorDepositFacet.sol";

library LibMarketplaceStorage {
    // storage position
    bytes32 constant MARKETPLACE_STORAGE_POSITION = keccak256('marketplace.storage.position');

    /**
     * selling lisiting type:
     * 0 = standard listing {SL}
     * 1 = timer listing {TL}
     * 2 = dutch lisitng {DL}
     * 3 = english listing {EL}
     * 4 = sealed bid listing {SBL}
     */
    enum SellingListingTypes { StandardListing, TimerListing, DutchListing, EnglishListing, SealedBidListing }

    /**
     * @notice listing indexes structs
     */
    struct listingsIndexesStruct {
        // index listing
        uint64 indexListing;

        // collection address
        address collection;
        //token id
        uint32 tokenID;
    }

    /**
     * @notice Standard listing
     */
    struct StandardListingStruct {
        // address owner listing
        address ownerListing;
        // amount of tokens listed
        uint64 quantity;
        // listing index
        uint32 indexListing;
        // lisitng price
        uint96 pricePerToken;
        // token address payment
        address tokenPayment;
    }

    /**
     * @notice Timer listing
     */
    struct TimerListingStruct {
        // address owner listing
        address ownerListing;
        // time of the listing {TL, DL, EL, SBL}
        uint64 time;
        // listing index
        uint32 indexListing;
        // address token payment
        address tokenPayment;
        // lifetime of the listing {TL, DL, EL, SBL}
        uint96 lifetime;

        // amount of tokens listed
        uint128 quantity;
        // lisitng price
        uint128 pricePerToken;
    }

    /**
     * @notice Dutch listing
     */
    struct DutchListingStruct {
        // address owner listing
        address ownerListing;
        // time of the listing {TL, DL, EL, SBL}
        uint64 time;
        // listing index
        uint32 indexListing;
        // address token payment
        address tokenPayment;
        // lifetime of the listing {TL, DL, EL, SBL}
        uint96 lifetime;

        // amount of tokens listed
        uint64 quantity;
        // lisitng price
        uint96 pricePerToken;
        // least price a DL can arrive {DL}
        uint96 leastPricePerToken;
    }

    /**
     * @notice English listing
     */
    struct EnglishListingStruct {
        // address owner listing
        address ownerListing;
        // amount of tokens listed
        uint64 quantity;
        // listing index
        uint32 indexListing;

        // lisitng price
        uint248 initialPricePerToken;
        // bid time cap {EL}
        bool timeCap;

        // address token payment
        address tokenPayment;
        // time of the listing {TL, DL, EL, SBL}
        uint40 time;
        // lifetime of the listing {TL, DL, EL, SBL}
        uint40 lifetime;
        // additional time after bid {EL}
        uint16 additionalBidTime;

        // address highest {EL} bidder
        address addressHighestBidder;
        // price highest bid {EL}
        uint80 pricePerTokenHighestBidder;
        // bids counter {EL}
        uint16 bidsCounter;
    }

    /**
     * @notice Sealed bid listing
     */
    struct SealedBidUserStruct {
        // password hash
        bytes32 passwordHash;
        // bid price
        uint256 pricePerToken;
        // quantity tokens
        uint96 quantity;
        // token payment
        address tokenPayment;
    }
    struct SealedBidListingStruct {
        // address owner listing
        address ownerListing;
        // bid floor price {SBL}
        uint96 floorPricePerToken;
        // address token payment
        address tokenPayment;
        // max amount of bids {SBL}
        uint16 amountCapBids;
        // amount of tokens listed
        uint56 quantity;
        // listing index
        uint24 indexListing;

        // Bids placed
        uint16 amountBids;
        // time of the listing {TL, DL, EL, SBL}
        uint56 time;
        // bidding time of the listing {SBL}
        uint56 biddingTime;
        // placing time of the listing {SBL}
        uint64 placingTime;
        // closing time of the listing {SBL}
        uint64 closingTime;
    }

    /**
     * Bids types:
     * 0 = english bid {EB}
     * 1 = sealed bid bid {SBB}
     */
    enum SellingBidTypes { EnglishBid, SealedBidBid }

    /**
     * Requests types:
     * 0 = Standard request {SR}
     * 1 = Timer request {TR}
     * 2 = Dutch request {DR}
     * 3 = Amount request {AR}
     */
    enum BuyingRequestTypes { StandardRequest, TimerRequest, DutchRequest, AmountRequest, Offer }

    /**
     * @notice Requests indexes struct
     */
    struct requestIndexesStruct {
        // address collection
        address collection;
        // token id
        uint48 tokenID;
        // index request
        uint48 indexRequest;
    }

    /**
     * @notice standard request struct
     */
    struct StandardRequestStruct {
        // address owner
        address owner;
        // amount of tokens requested
        uint64 quantity;
        // request index
        uint32 indexRequest;
        // token payment address
        address tokenPayment;
        // price requested
        uint96 pricePerToken;
    }

    /**
     * @notice timer request struct
     */
    struct TimerRequestStruct {
        // address owner
        address owner;
        // time of the listing
        uint64 time;
        // request index
        uint32 indexRequest;
        // token payment address
        address tokenPayment;
        // lifetime of the listing {TR, DR, AR, Offer}
        uint96 lifetime;

        // amount of tokens requested
        uint80 quantity;
        // price requested
        uint176 pricePerToken;
    }

    /**
     * @notice dutch request struct
     */
    struct DutchRequestStruct {
        // address owner
        address owner;
        // time of the listing
        uint64 time;
        // request index
        uint32 indexRequest;
        // token payment address
        address tokenPayment;
        // amount of tokens requested
        uint96 quantity;

        // lifetime of the listing {TR, DR, AR, Offer}
        uint32 lifetime;
        // price requested
        uint112 pricePerToken;
        // least price a DL can arrive {DL}
        uint112 leastPricePerToken;
    }

    /**
     * @notice amount request struct
     */
    struct AmountRequestStruct {
        // address owner
        address owner;
        // time of the listing
        uint64 time;
        // request index
        uint32 indexRequest;
        // token payment address
        address tokenPayment;
        // lifetime of the listing {TR, DR, AR, Offer}
        uint96 lifetime;

        // amount of tokens requested
        uint128 quantity;
        // price requested
        uint128 pricePerToken;
    }

    /**
     * @notice Offer struct
     */
    struct OfferStruct {
        // token contract address
        address addressToken;
        // id of tokens request
        uint64 idToken;
        // offer index
        uint32 indexOffer;
        // token payment address
        address tokenPayment;
        // amount of tokens requested
        uint96 quantity;

        // price requested
        uint176 pricePerToken;
        // time of the listing
        uint40 time;
        // lifetime of the offer
        uint40 lifetime;
    }
    struct offersIndexesStruct {
        // address offer placer
        address offerPlacer;
        // id collectiion
        uint96 tokenID;
        // address offer receiver
        address offerReceiver;
        // index offer
        uint96 offerIndex;
    }

    // string manipulations struct
    struct slice {
        uint _len;
        uint _ptr;
    }

    /**
     * @notice token types:
     * 0 = ERC20
     * 1 = ERC721
     * 2 = ERC1155
     */
    enum TokenTypes { ERC20, ERC721, ERC1155 }

    /**
     * @notice Marketplace fees struct
     */
    struct MarketplaceFeesStruct {
        // collection exempt from marketplace trading fee
        bool tokenExemptFee;
        // collection exempt from marketplace trading fee discount mechanism
        bool tokenExemptFeeDiscount;
        // % Collection weight on fee percentage
        uint80 collectionWeightFee_PERCENTAGE;
        // % Token weight on fee percentage
        uint80 tokenWeightFee_PERCENTAGE;
        // % Marketplace trading fee, starting at 2%
        uint80 marketplaceFee_PERCENTAGE;
    }

    /**
     * @notice totAmount struct
     */
    struct TotAmountStruct {
        uint256 totAmountSL1155;
        uint256 totAmountSR1155;
    }

    // marketplace storage struct - address(0) fron native token use
    struct MarketplaceStorageStruct {
        /**
         * @notice Listings
         */
        // Mappings from collection to id to type of listing, mapping index from owner to index listing
        mapping(address => mapping(uint256 => StandardListingStruct[])) standardListings;
        mapping(address => listingsIndexesStruct[]) standardListingsIndexes;

        mapping(address => mapping(uint256 => TimerListingStruct[])) timerListings;
        mapping(address => listingsIndexesStruct[]) timerListingsIndexes;

        mapping(address => mapping(uint256 => DutchListingStruct[])) dutchListings;
        mapping(address => listingsIndexesStruct[]) dutchListingsIndexes;

        mapping(address => mapping(uint256 => EnglishListingStruct[])) englishListings;
        mapping(address => listingsIndexesStruct[]) englishListingsIndexes;

        mapping(address => mapping(uint256 => SealedBidListingStruct[])) sealedBidListings;
        // mapping from address owner bid to hash listing (keccak256(abi.encodePacked(ownerListing, time))) to sealed bid user struct
        mapping(address => mapping(bytes32 => SealedBidUserStruct)) sealedBidUser;
        // mapping from user address to sealed bid deposit keys
        mapping(address => bytes32[]) sealedBidUserDepositKeys;
        // add a cooling period of few blocks time to everyone to ensure security on sealedBidUser
        mapping(address => uint256) lastTimeSealedBidListing;
        mapping(address => listingsIndexesStruct[]) sealedBidListingsIndexes;

        /**
         * @notice Requests
         */
        // Mappings from collection to id collection to request structs, mapping index from owner to index requests
        mapping(address => mapping(uint256 => StandardRequestStruct[])) standardRequests;
        mapping(address => requestIndexesStruct[]) standardRequestsIndexes;

        mapping(address => mapping(uint256 => TimerRequestStruct[])) timerRequests;
        mapping(address => requestIndexesStruct[]) timerRequestsIndexes;

        mapping(address => mapping(uint256 => DutchRequestStruct[])) dutchRequests;
        mapping(address => requestIndexesStruct[]) dutchRequestsIndexes;

        /**
         * @notice ERC1155 amount request
         */
        mapping(address => mapping(uint256 => AmountRequestStruct[])) amountRequests;
        mapping(address => requestIndexesStruct[]) amountRequestsIndexes;

        /**
         * @notice Offers
         */
        // mapping from user to user offered to offer struct, mapping index from collection to offers struct
        mapping(address => mapping(address => OfferStruct[])) Offer;
        mapping(address => offersIndexesStruct[]) offersIndexes;

        /**
         * @notice Marketplace data
         */
        // highests number of standard listings and requests, mapping from collection to total amount struct
        mapping(address => TotAmountStruct) totAmount;
        // max discount for AR
        uint256 minDiscountAR1155;
        // Minimum increase amount EL biddings
        uint256 minEnglishListingBidAmountIncrease;

        // tokens approved listing
        mapping(address => bool) listingTokensApproval721;
        // Array of listing tokens
        address[] listingTokens721;
        // Related array index
        mapping(address => uint256) listingTokensIndexes721;

        // tokens approved listing
        mapping(address => bool) listingTokensApproval1155;
        // Array of listing tokens
        address[] listingTokens1155;
        // Related array index
        mapping(address => uint256) listingTokensIndexes1155;

        // tokens approved listing
        mapping(address => bool) biddingTokensApproval;
        // Array of listing tokens and related index
        address[] biddingTokens;
        // Related array index
        mapping(address => uint256) biddingTokensIndexes;

        // Collection fee structure, mapping from token address to marketplace fees struct
        mapping(address => MarketplaceFeesStruct) collectionFeeStructure;
        // total volume entire collection on a listing, mapping from collection address to listing type to total volume
        mapping(address => mapping(SellingListingTypes => uint256)) collectionTotalListingsVolume;
        // overall volume single token, mapping from token address to token id to total volume token id
        mapping(address => mapping(uint256 => uint256)) tokenOverallVolume;
        /**
         * Marketplace trading fee percentages split between QuarryDraw and featured actors.
         * Mapping from collection address to array of actors, if length == 0 redirect fees only to owner
         * Mapping from collection to address actor to percentage fees
         * @notice Array of total keys collections is given by listingTokens
         */
        mapping(address => address[]) collectionFeeActors;
        mapping(address => mapping(address => uint256)) percentageFeeCollectionActors;

        // listings paused mapping from types of listing to bool
        mapping(SellingListingTypes => bool) pauseListings;
        // requests paused from types of request to bool
        mapping(BuyingRequestTypes => bool) pauseRequests;
        // bids paused mapping from types of bids to bool
        mapping(SellingBidTypes => bool) pauseBids;

        /**
         * @notice Utils
         */
        uint256 PERCENTAGE_PRECISION; // 1e18
        uint256 ONE_PERCENT; // 1e16
    }

    /**
     * @notice Retrive MarketplaceStorageStruct position
     */
    function getMarketplaceStoragePosition() internal pure returns(MarketplaceStorageStruct storage mss) {
        bytes32 position = MARKETPLACE_STORAGE_POSITION;
        assembly {
            mss.slot := position
        }
    }

    /**
     * @notice Utils function and related errors
     */
    // Revert if token is not approved
    error TokenNotApproved(address token);
    // Check listing token approved 721
    function isListingTokenApproved721(address token) internal view {
        MarketplaceStorageStruct storage mss = getMarketplaceStoragePosition();
        if (!mss.listingTokensApproval721[token]) revert TokenNotApproved(token);
    }
    // Check listing token approved 1155
    function isListingTokenApproved1155(address token) internal view {
        MarketplaceStorageStruct storage mss = getMarketplaceStoragePosition();
        if (!mss.listingTokensApproval1155[token]) revert TokenNotApproved(token);
    }
    // Check bigging token approved 20 or native
    function isBiddingTokenApproved(address token) internal view {
        MarketplaceStorageStruct storage mss = getMarketplaceStoragePosition();
        if (!mss.biddingTokensApproval[token]) revert TokenNotApproved(token);
    }

    // Revert if pause is in place
    error ListingPaused(SellingListingTypes _type);
    error BidPaused(SellingBidTypes _type);
    error RequestPaused(BuyingRequestTypes _type);
    // Check listing paused
    function isListingPaused(SellingListingTypes _type) internal view {
        MarketplaceStorageStruct storage mss = getMarketplaceStoragePosition();
        if (mss.pauseListings[_type]) revert ListingPaused(_type);
    }
    // Check listing paused
    function isRequestPaused(BuyingRequestTypes _type) internal view {
        MarketplaceStorageStruct storage mss = getMarketplaceStoragePosition();
        if (mss.pauseRequests[_type]) revert RequestPaused(_type);
    }
    // Check listing paused
    function isBidPaused(SellingBidTypes _type) internal view {
        MarketplaceStorageStruct storage mss = getMarketplaceStoragePosition();
        if (mss.pauseBids[_type]) revert BidPaused(_type);
    }

    // Return average tot amount SL and SR per collection - better gas copy entire struct?
    function returnTotAverageSLAndSRAmountCollection(address collection) internal view returns(uint256) {
        MarketplaceStorageStruct storage mss = getMarketplaceStoragePosition();
        return (mss.totAmount[collection].totAmountSL1155 + mss.totAmount[collection].totAmountSR1155) / 2;
    }
    // Return percentage precision
    function returnPercentagePrecision() internal view returns(uint256 percentagePrecision) {
        MarketplaceStorageStruct storage mss = getMarketplaceStoragePosition();
        return mss.PERCENTAGE_PRECISION;
    }
    // Return one percent percentage precision
    function returnOnePercent() internal view returns(uint256 onePercent) {
        MarketplaceStorageStruct storage mss = getMarketplaceStoragePosition();
        return mss.ONE_PERCENT;
    }
}