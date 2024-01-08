// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibMarketplaceStorage} from "../libraries/LibMarketplaceStorage.sol";
import {IMarketplaceFacet} from "../interfaces/IMarketplaceFacet.sol";

/**
 * @notice Marketplace main contract to manage main user operations and retrive informations
 * about the whole marketplace.
 *
 * @dev The marketplace will respect creators royalties and it will operate as a
 * non-custodial marketplace for both makers and takes, note that if a taker wants to
 * execute a trade for both listings and requests that aren't immediately confirmed with
 * native AVAX he will be required to make a deposit. Informations are stored all on
 * chain to prevent any possibilities of replay attacks, which hybrids marketplaces can
 * suffer from.
 * Implementation will give the possibility to list for sale any kind of non and
 * semi fungible tokens, on the other end bidders will have the possibilities to
 * fulfill sales with a large variety of tokens.
 * Tokens can be implemented by community voting, collaboration agreements and token
 * assurance.
 *
 * @notice It will host different types of auctions for sellers, called listing:
 *
 * Standard listing {SL}
 * Managed by the owner by simply setting the price pertoken that is more comfortable
 * with. The owner can decide to have tokens listedas much as they want, with to
 * strings attached. List and delist of tokens is freeand unlimited.
 *
 * Equations:
 * P = Powner
 *
 *
 * Timer listing {TL}
 * Simple time dependent auction. The owner list tokens for a defined price per
 * token and time duration, the offer will be available only for that period of
 * time, once the time gets to an end the auction expires and if no buyers show
 * up the owner will have to close the auction and delist tokens. List and delist
 * of tokens is free and unlimited.
 *
 * Equations:
 * P = Powner
 * T = Tcurrent + Towner
 * Tcurrent < T expires
 *
 *
 * Dutch lisitng {DL}
 * Auction and price are dependent by time. The owner will decide the duration of
 * the auction, the initial price per token and the last price per token. At the
 * beginning the listing will start at the initial price and the cost, as time passes,
 * will slowly decrease until it will reach the last price per token setted by the
 * owner. If a buyer is found the auction finishes. On the oder end if the auction
 * time expires, and no buyers show up the owner will have to close the auction and
 * delist tokens. List and delist of tokens is free and unlimited.
 *
 * Equations:
 * Pinitial = Pinitial-owner
 * Pfinal = Pfinal-owner
 * Tinitial = Tcurrent
 * Tfinal = Tcurrent + Towner
 * Pdl = Pinitial - ((Pinitial - Pfinal) * (Tcurrent - Tinitial) / (Tfinal - Tinitial))
 * Pdl => require (Pfinal < Pinitial && Tfinal > Tinitial && Pinitial < 1e77) +
 *        if (Tcurrent - Tinitial > Tfinal - Tinitial) { P = Pfinal } >> if (Tcurrent > Tfinal) { P = Pfinal }
 *        => if Tcurrent > Tfinal auction is expired.
 *
 *
 * English listing {EL}
 * Auction dependent by time and bidders. The owner will set the duration of the auction,
 * the initial price per token, if the auction will have a timecap and its additional
 * time per bid. Once setted, the auction will start and people will be able to bid for
 * tokens. Only increasing bids will be considered. Every bid, based on the additional
 * time decided by the owner, will increase the duration of the auction. Based on the
 * timecap the entirety of the duration of the bid will or won't excide the listing
 * duration. Once time expires both the owner and, if there is, the buyer will have
 * the ability, to respectively, close and collect the auction. Listings that didn't meet
 * any bidder will give back tokens to the owner. Every bidder will have to deposit the
 * correct value amount to be able to purchase the desired tokens, once the auction ends
 * if your bid was the winning one, thus the last one, you will buy tokens using the
 * already deposited purchasing power, in the case your bid isn't the winning one you will
 * be able to collect your tokens as soon as the auction ends or your bid gets surpassed.
 * If you were to bid more than once the already deposited purchasing power will count and
 * you will be asked to deposit the difference between your previous bid and your current
 * one. List and delist of tokens is free and unlimited. Placing a bid requires a 0.25% fee.
 *
 * Equations:
 * Bc (Bids counter)
 * Pi = Powner
 * Ad = Towner (Auction duration)
 * At (Auction time)
 * Tinit = Tcurrent (block.timestamp)
 * Tcap = Bow (Bool owner)
 * Tinc (increase time) = Tincow (increase time owner)
 *
 * if At > Ti + Ad >> expired (stop function for new bidders) => check beforehand as if
 * don't an auction that is bidded between the expiration time and the expiration time + Tinc
 * will reactivate the auction.
 * totTinc = Tinc * Bc
 * At = Tcurrent (block.timestamp) - totTinc
 *   => if Tcap && At < Ti >> At = Ti
 *
 * Note:
 * Add a small deposit for bidders to slash if bad behaviours occour, while tring to participate
 * at the bid with a non-native token.
 *
 *
 * Sealed bid listing {SBL}
 * Auction dependent by time and number of sealed bids. The owner will set the duration of
 * the auction (composed by bidding time, placing time and closing time), the number of sealed
 * bid possible and a minimum price per token bids must have.
 * The owner will deposit the auction tokens at the creation of the sealed bid listing.
 * Bidding time: During this time period buyers will have the possibility to place multiple bids,
 * but every bid will override the previous one. Bids placed won't require any deposit. To
 * implement a real sealed bid we can't simply use a deposit or a private variable as everyone
 * with a little bid of knowledge will be able to collect every bids amount, thus to prevent any
 * bids to be disclosed we will ask every bidders to insert their desired price per token along
 * with a password, this way we will store in the contract the hash of the price you wish to win
 * the auction with and the password, giving complete privacy to your bid. Remember to not forget
 * your password as it will be essential to conclude the auction.
 * Placing time: The placing time will give everyone that bidded the possibility to disclose and
 * deposit their bid as everyone will have decide it beforehand and a change on this period won't
 * be possible. As this period start every partecipant will have to confirm their bet and deposit
 * the correct amount of purchasing power, note that bids during bidding time is limit free, and
 * an eventual max number of bids possible decided by the owner will be enforced during the placing
 * time, thus people that will place and confirm their bids late might exceed the limit, hence they
 * won't no longer participate in the auction and deposit a collateral.
 * Closing time: Period in which the owner will have the possibility to see all available bids and
 * decide which one fulfill, once the owner has decided and confirmed the winner tokens will be
 * exchanged the auction stopped and every losing participants will have the ability to retrive
 * the collateral they deposited. If the period expires the auction automatically closes and the owner
 * won't be able to declare an actual winner, thus giving everyone the ability to withdraw their bid.
 * If the auction has bidders and a winner isn't met by the owner, he will need to withdraw their tokens
 * and pay a 5% slashing fee for bad behaviours (if the 5% amounts at a quantity less than 1 token, the
 * fee will amount to 1, if it's a float the number will be rounded down), which in the case of validator
 * shares they will be burned. If the auction doesn't have any bidders the owner will be able to withdraw
 * without any slashing fee. Listing is free. Confirming a bid during placing period requires a 0.25% fee.
 *
 * Equations:
 * Pimin = Powner
 * T = Tcurrent
 * SBmax = MaxSealedBidsOwner
 * Bt = BiddingTimeOwner
 * Pt = PlacingTimeOwner
 * Ct = ClosingTimeOwner
 * Bperiod = T + Bt
 * Pperiod = Bperiod + Pt
 * Cperiod = Pperiod + Ct
 * Vhash = VoteHashOwner (keccak256)
 * if (vote has not -) { Invalid vote }
 * if (keccak256(vote) != Vhash) { Invalid vote }
 * if (amountInVoteUint != amountVote) { Invalid vote }
 * deposit amountInVoteUint
 *
 * Notes:
 * Check if the bids haven't been placed before, no double values.
 * No token deposit for both parties, problem seller => for bad behaviours add an initial deposit.
 *
 *
 * @notice For buyers the marketplace will give them these additional offers:
 *
 * Standard request {SR}
 * Managed by the buyer, a fixed price per token and token quantity at which seller can fulfill,
 * request doesn't have time constraints. List and delist of tokens is free and unlimited.
 *
 * Equations:
 * Rv = RequestValueOwner
 *
 *
 * Timer request {TR}
 * Buying request dependent on time. The buyer will be able to set a price per token, the amount of
 * token and an expiring time, sellers will be able to fulfill the request until the time expires.
 * Once that point is reached if the buyer doesn't find a seller he will be able to withdraw tokens.
 * List and delist of tokens is free and unlimited.
 *
 * Equations:
 * Rv = RequestValueOwner
 * T = Tcurrent + Towner
 * if Tcurrent > T >> expired
 *
 *
 * Dutch request {DR}
 * Very similar to a dutch listing: the buyer will be able to set an initial price per token, a
 * final price per token, the amount of tokens and an expiring time. The request will start at the
 * initial pricer per token setted and will linearly decreases until the final price per token is
 * reached at the expiring time. Sellers will be able to fulfill the request until time expires.
 * Once that point is reached if the buyer doesn't find a seller he will be able to withdraw tokens.
 * List and delist of tokens is free and unlimited.
 *
 * Equations:
 * Rvi = InitialRequestValueOwner
 * Rvf = FinalRequestValueOwner
 * Ti = Tcurrent
 * Tf = Tcurrent + Townen
 * Rdl = Rvi - ((Rvi - Rvf) * (Tcurrent - Ti) / (Tf - Ti))
 * Pdl => require (Rvf < Rvi && Tf > Ti && Rvi < 1e77) +
 *        if (Tcurrent - Ti > Tf - Ti) { P = Rvf } >> if (Tcurrent > Tf) { P = Rvf }
 *        => if Tcurrent > Tf auction is expired.
 *
 *
 * Amount request {AR}
 * The amount request is a buyer request that will scale the price based on the amount of liquidity a
 * buyier is willing to provide. This request will enhance liquidity for larger sellers and rewards
 * buyers as they will provide deep liqudity.
 * A buyer will be able to set a large amount of tokens as maximum request capacity for a discount
 * in exchange for the liquidity, which won't be able to succeed 2% of the total value of tokens.
 * This request will need to be at least 50% deeper than the average between the larger SL buyers and
 * sellers request, and the discount will scale based on the additional amount the request can fulfill.
 * To ensure an amount request is respected with high liquidity from makers, the discount will be decrease
 * with an exponential curve, meaning only highest fulfills gets a better price for their tokens, the discount
 * will start from a 50% to a 2% at maximum {AR} amount.
 * Partials fulfillments will be available, and if they will reduce the liquidity under the minimum amount
 * the position will be unavailable until the bidder will increase the position over the treshold.
 * List and delist of tokens is free and unlimited.
 *
 * Equations:
 * Aar = Amount {AR}
 * Treshold = (AmountHighestSL + AmountHighestSB) / 2
 * if Treshold > Aar >> invalid request
 * amount(discount) =  log(2,5discount) && discount(amount) = 2**amount / 5 perfect for range x (discount) := [1/5, 4] and y (amount) := [0, 4.33]
 * Ideal range: y (amount) [1, amountRequest] and x(y) (discount(amount)) that ranges [100%, 2%]
 *     => amountRate = _amountInWei * 1e18 / _totAmountInWeiPosition;
 *        coefficient = 1e18 / amountRate + 9;
 *        calculateDiscount = 1e16 + (((((2**coefficient) * 1e16) / 6) / amountRate ) * 1e16);
 * seller fulfill request => send amount to seller, discount to buyers and reduce position
 * if position already open and Threshold > Aar disable the ability to buy
 *
 *
 * @notice We will even add the possibility to place direct offers to specified tokens holded by specified addresses, with
 * both non and semi fungible tokens. non fungible tokens will only need the price of the offer and an expiring time
 * if the user wants to add it, on the other and for semi fungible tokens the user will need to add the old values,
 * like price per token and time, and a new value, which is the quantity of tokens.
 *
 * @dev Every type of token will have it's function to both place a selling list or a bidding request, this will save
 * complexity and gas cost of an all in one function.
 * Functions have been ideated to support any kind of tokens, this way contracts are scalable and can be used by other
 * marketplaces that can bring revenues for QuarryDraw as a whole to then reward even more users, that's why for the marketplace
 * we pivoted to a features-free idea for validators holder. If the idea isn't rewarded enough we will introduce unique
 * validator features to still add value to the ecosystem.
 *
 * @dev Marketplace trading fees will be applied to every collections besides validator shares and collaboration that
 * requires no trading fee. Collections trading volume will be stored as a variable to keep track to the amount of total
 * volume, which will play an important role with trading fees. As a collection manages to increase their trading volume the
 * marketplace trading fee will be reduced accordingly, thus incentivizing collections to have a very active trading on our
 * marketplace and different listing types. Volume is collected by listing type. Offers are considered as {SL}.
 * The collection volume will work along the overall volume of a specified token, which will also play an active role to reduce
 * the marketplace trading fee. Volume is collect on every listing type. Offers are considered on total volume.
 * The default weight over the fee of both collection volume and token volume will be respectively 75% and 25%. Weights are
 * customizable between collections.
 * Offers and AmountRequests will be counted as StandardListings, while other request will count as their respective listing type.
 *
 * Equations:
 *
 *
 */
contract MarketplaceFacet is IMarketplaceFacet {
/**
 *
 * @notice View functions Marketplace *
 *
 */
}
