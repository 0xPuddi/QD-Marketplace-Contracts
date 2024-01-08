/* global describe it before ethers */

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')

const { assert } = require('chai');
const { isCallTrace } = require('hardhat/internal/hardhat-network/stack-traces/message-trace.js');
const { ethers, network } = require('hardhat');

describe('DiamondTest', async function () {
  let diamondAddress
  let diamondCutFacet
  let diamondLoupeFacet
  let ownershipFacet
  let testERC1155
  let marketplaceOwnerFacet
  let marketplaceListingFacet
  let marketplaceListingFacetUser1
  let marketplaceRequestFacet
  let marketplaceRequestFacetUser1
  let marketplaceModifyRequestFacet
  let marketplaceModifyRequestFacetUser1
  let marketplaceModifyListingFacet
  let marketplaceModifyListingFacetUser1
  let marketplaceFulfillListingFacet
  let marketplaceFulfillListingFacetUser1
  let marketplaceFulfillSealedBidListingFacet
  let marketplaceFulfillSealedBidListingFacetUser1
  let marketplaceFulfillEnglishListingFacet
  let marketplaceFulfillEnglishListingFacetUser1
  let marketplaceFulfillRequestFacet
  let marketplaceFulfillRequestFacetUser1
  let marketplaceFulfillAmountRequestFacet
  let marketplaceFulfillAmountRequestFacetUser1
  let marketplaceFulfillOfferFacet
  let marketplaceFulfillOfferFacetUser2
  let marketplaceCloseListingFacet
  let marketplaceCloseListingFacetUser1
  let marketplaceCloseSealedBidListingFacet
  let marketplaceCloseSealedBidListingFacetUser1
  let marketplaceCloseRequestFacet
  let marketplaceCloseRequestFacetUser1
  let tx
  let receipt
  let result
  const addresses = []
  let users = []

  before(async function () {
    diamondAddress = await deployDiamond()
    diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress.diamond)
    diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress.diamond)
    ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress.diamond)

    testERC1155 = await ethers.getContractAt('testERC1155', diamondAddress.ERC1155);

    marketplaceListingFacet = await ethers.getContractAt('MarketplaceListingFacet', diamondAddress.diamond);
    marketplaceRequestFacet = await ethers.getContractAt('MarketplaceRequestFacet', diamondAddress.diamond);
    marketplaceModifyRequestFacet = await ethers.getContractAt('MarketplaceModifyRequestFacet', diamondAddress.diamond); marketplaceFulfillListingFacet
    marketplaceModifyListingFacet = await ethers.getContractAt('MarketplaceModifyListingFacet', diamondAddress.diamond);
    marketplaceFulfillListingFacet = await ethers.getContractAt('MarketplaceFulfillListingFacet', diamondAddress.diamond);
    marketplaceFulfillSealedBidListingFacet = await ethers.getContractAt('MarketplaceFulfillSealedBidListingFacet', diamondAddress.diamond);
    marketplaceFulfillEnglishListingFacet = await ethers.getContractAt('MarketplaceFulfillEnglishListingFacet', diamondAddress.diamond);
    marketplaceFulfillRequestFacet = await ethers.getContractAt('MarketplaceFulfillRequestFacet', diamondAddress.diamond);
    marketplaceFulfillOfferFacet = await ethers.getContractAt('MarketplaceFulfillOfferFacet', diamondAddress.diamond);
    marketplaceFulfillAmountRequestFacet = await ethers.getContractAt('MarketplaceFulfillAmountRequestFacet', diamondAddress.diamond);

    users = await ethers.getSigners();

    marketplaceOwnerFacet = (await ethers.getContractAt('MarketplaceOwnerFacet', diamondAddress.diamond)).connect(users[0]);
  });

  it('Complete Test', async () => {
    marketplaceListingFacetUser1 = marketplaceListingFacet.connect(users[1])
    marketplaceRequestFacetUser1 = marketplaceRequestFacet.connect(users[1])
    marketplaceModifyRequestFacetUser1 = marketplaceModifyRequestFacet.connect(users[1])
    marketplaceModifyListingFacetUser1 = marketplaceModifyListingFacet.connect(users[1])
    marketplaceFulfillListingFacetUser1 = marketplaceFulfillListingFacet.connect(users[1])
    marketplaceFulfillSealedBidListingFacetUser1 = marketplaceFulfillSealedBidListingFacet.connect(users[1])
    marketplaceFulfillEnglishListingFacetUser1 = marketplaceFulfillEnglishListingFacet.connect(users[1])
    marketplaceFulfillRequestFacetUser1 = marketplaceFulfillRequestFacet.connect(users[1])
    marketplaceFulfillOfferFacetUser2 = marketplaceFulfillOfferFacet.connect(users[2])
    marketplaceFulfillAmountRequestFacetUser1 = marketplaceFulfillAmountRequestFacet.connect(users[1])

    tx = await testERC1155._mintBatch(users[1].address, [0, 1, 2, 3, 4], [10, 10, 10, 10, 10], "0x");
    await tx.wait(1);

    tx = await testERC1155._mintBatch(users[2].address, [0, 1, 2, 3, 4], [10, 10, 10, 10, 10], "0x");
    await tx.wait(1);

    tx = await testERC1155._setApprovalForAll(users[1].address, diamondAddress.diamond, true);
    await tx.wait(1);

    tx = await testERC1155._setApprovalForAll(users[2].address, diamondAddress.diamond, true);
    await tx.wait(1);

    tx = await marketplaceOwnerFacet.addListingToken(diamondAddress.ERC1155)
    await tx.wait(1);

    tx = await marketplaceOwnerFacet.setCollectionFeeActorsAndPercentages(diamondAddress.ERC1155, [users[0].address, users[1].address, users[2].address], [ethers.utils.parseEther('0.2'), ethers.utils.parseEther('0.4'), ethers.utils.parseEther('0.4')])
    await tx.wait(1);

    tx = await marketplaceListingFacetUser1.createStandardListing(diamondAddress.ERC1155, 0, 1, ethers.utils.parseEther("1.0"), '0x0000000000000000000000000000000000000000')
    await tx.wait(1);

    tx = await marketplaceListingFacetUser1.createStandardListing(diamondAddress.ERC1155, 1, 1, ethers.utils.parseEther("1.0"), '0x0000000000000000000000000000000000000000')
    await tx.wait(1);

    tx = await marketplaceListingFacetUser1.createTimerListing(diamondAddress.ERC1155, 2, 1000, 1, ethers.utils.parseEther("1.0"), '0x0000000000000000000000000000000000000000')
    await tx.wait(1);

    tx = await marketplaceListingFacetUser1.createTimerListing(diamondAddress.ERC1155, 3, 1000, 1, ethers.utils.parseEther("1.0"), '0x0000000000000000000000000000000000000000')
    await tx.wait(1);

    tx = await marketplaceFulfillListingFacetUser1.fulfillTimerListing(diamondAddress.ERC1155, 2, 0, { value: ethers.utils.parseEther('1') })
    await tx.wait(1);

    tx = await marketplaceListingFacetUser1.createDutchListing(diamondAddress.ERC1155, 3, 1000, 1, ethers.utils.parseEther("1.0"), ethers.utils.parseEther("0.5"), '0x0000000000000000000000000000000000000000')
    await tx.wait(1);

    tx = await marketplaceListingFacetUser1.createDutchListing(diamondAddress.ERC1155, 3, 1000, 1, ethers.utils.parseEther("1.0"), ethers.utils.parseEther("0.5"), '0x0000000000000000000000000000000000000000')
    await tx.wait(1);

    tx = await marketplaceFulfillListingFacetUser1.fulfillDutchListing(diamondAddress.ERC1155, 3, 0, { value: ethers.utils.parseEther('1') })
    await tx.wait(1);

    tx = await marketplaceListingFacetUser1.createEnglishListing(diamondAddress.ERC1155, 4, 1, ethers.utils.parseEther("0.1"), true, '0x0000000000000000000000000000000000000000', 100, 100)
    await tx.wait(1);

    tx = await marketplaceListingFacetUser1.createEnglishListing(diamondAddress.ERC1155, 4, 1, ethers.utils.parseEther("0.1"), true, '0x0000000000000000000000000000000000000000', 100, 100)
    await tx.wait(1);

    tx = await marketplaceFulfillEnglishListingFacetUser1.bidEnglishListing(diamondAddress.ERC1155, 4, 0, ethers.utils.parseEther('1.1'), { value: ethers.utils.parseEther('1.1') })
    await tx.wait(1);
    await network.provider.send("evm_increaseTime", [1100]);
    await network.provider.send("evm_mine");
    tx = await marketplaceFulfillEnglishListingFacetUser1.fulfillEnglishListing(diamondAddress.ERC1155, 4, 0)
    await tx.wait(1);

    tx = await marketplaceListingFacetUser1.createSealedBidListing(diamondAddress.ERC1155, 1, ethers.utils.parseEther("1.0"), '0x0000000000000000000000000000000000000000', 100, 1, 1000, 1000, 1000)
    await tx.wait(1);

    await network.provider.send("evm_increaseTime", [310]);
    await network.provider.send("evm_mine");

    tx = await marketplaceListingFacetUser1.createSealedBidListing(diamondAddress.ERC1155, 1, ethers.utils.parseEther("1.0"), '0x0000000000000000000000000000000000000000', 100, 1, 1000, 1000, 1000)
    await tx.wait(1);

    tx = await marketplaceFulfillSealedBidListingFacetUser1.bidSealedBidListing(diamondAddress.ERC1155, 1, 1, '0x1f2ac2105abbc3628beb925889e39be62655cfc3be61e6d2ac865c67e2eeaf88')
    await tx.wait(1);
    await network.provider.send("evm_increaseTime", [1010]);
    await network.provider.send("evm_mine");
    tx = await marketplaceFulfillSealedBidListingFacetUser1.placeSealedBidListing(diamondAddress.ERC1155, 1, 1, '1000-password', 1000, { value: ethers.utils.parseEther('1') })
    await tx.wait(1);
    await network.provider.send("evm_increaseTime", [1010]);
    await network.provider.send("evm_mine");
    tx = await marketplaceFulfillSealedBidListingFacetUser1.closeSealedBidListing(diamondAddress.ERC1155, 1, 1, users[1].address)
    await tx.wait(1);

    tx = await marketplaceRequestFacetUser1.createStandardRequest(diamondAddress.ERC1155, 1, 1, '0x0000000000000000000000000000000000000000', 1000000000, { value: ethers.utils.parseEther("0.000000001") })
    await tx.wait(1);

    tx = await marketplaceModifyRequestFacetUser1.modifyStandardRequest(diamondAddress.ERC1155, 1, 0, 1, '0x0000000000000000000000000000000000000000', 2000000000, { value: ethers.utils.parseEther("0.000000001") })
    await tx.wait(1);

    tx = await marketplaceRequestFacetUser1.createTimerRequest(diamondAddress.ERC1155, 2, 1, '0x0000000000000000000000000000000000000000', 1000000000, 100, { value: ethers.utils.parseEther("0.000000001") })
    await tx.wait(1);

    await network.provider.send("evm_increaseTime", [110]);
    await network.provider.send("evm_mine");

    tx = await marketplaceModifyRequestFacetUser1.modifyTimerRequest(diamondAddress.ERC1155, 2, 0, 1, '0x0000000000000000000000000000000000000000', 2000000000, 100, { value: ethers.utils.parseEther("0.000000001") })
    await tx.wait(1);

    tx = await marketplaceFulfillRequestFacetUser1.fulfillTimerRequest(diamondAddress.ERC1155, 2, 0, { value: ethers.utils.parseEther('1') })
    await tx.wait(1);

    tx = await marketplaceRequestFacetUser1.createDutchRequest(diamondAddress.ERC1155, 1, 1, '0x0000000000000000000000000000000000000000', 100, 1000000000, 10, { value: ethers.utils.parseEther("0.000000001") })
    await tx.wait(1);

    await network.provider.send("evm_increaseTime", [110]);
    await network.provider.send("evm_mine");

    tx = await marketplaceModifyRequestFacetUser1.modifyDutchRequest(diamondAddress.ERC1155, 1, 0, 1, '0x0000000000000000000000000000000000000000', 100, 2000000000, 10000, { value: ethers.utils.parseEther("0.000000001") })
    await tx.wait(1);

    tx = await marketplaceFulfillRequestFacetUser1.fulfillDutchRequest(diamondAddress.ERC1155, 1, 0, { value: ethers.utils.parseEther('1') })
    await tx.wait(1);

    tx = await marketplaceRequestFacetUser1.createAmountRequest(diamondAddress.ERC1155, 1, 2, '0x0000000000000000000000000000000000000000', 0, 1000000, { value: ethers.utils.parseEther("0.000000001") })
    await tx.wait(1);

    tx = await marketplaceModifyRequestFacetUser1.modifyAmountRequest(diamondAddress.ERC1155, 1, 0, 2, '0x0000000000000000000000000000000000000000', 0, 20000000, { value: ethers.utils.parseEther("0.000000001") })
    await tx.wait(1);

    tx = await marketplaceRequestFacetUser1.createOffer(users[2].address, diamondAddress.ERC1155, '0x0000000000000000000000000000000000000000', 3, 1, 1000000000, 0, { value: ethers.utils.parseEther("0.000000001") })
    await tx.wait(1);

    tx = await marketplaceModifyRequestFacetUser1.modifyOffer(users[2].address, 0, '0x0000000000000000000000000000000000000000', 1, 2000000000, 0, { value: ethers.utils.parseEther("0.000000001") })
    await tx.wait(1);

    tx = await marketplaceModifyListingFacetUser1.modifyStandardListing(diamondAddress.ERC1155, 0, 0, 2, ethers.utils.parseEther('0.1'), '0x0000000000000000000000000000000000000000')
    await tx.wait(1);

    await network.provider.send("evm_increaseTime", [10000]);
    await network.provider.send("evm_mine");

    tx = await marketplaceModifyListingFacetUser1.modifyTimerListing(diamondAddress.ERC1155, 3, 0, '0x0000000000000000000000000000000000000000', 100, 2, ethers.utils.parseEther('0.1'))
    await tx.wait(1);

    tx = await marketplaceModifyListingFacetUser1.modifyDutchListing(diamondAddress.ERC1155, 3, 0, '0x0000000000000000000000000000000000000000', 100, 4, ethers.utils.parseEther('0.1'), ethers.utils.parseEther('0.01'))
    await tx.wait(1);

    tx = await marketplaceModifyListingFacetUser1.modifyEnglishListing(diamondAddress.ERC1155, 4, 0, 2, ethers.utils.parseEther('0.1'), true, '0x0000000000000000000000000000000000000000', 100, 1000)
    await tx.wait(1);

    tx = await marketplaceModifyListingFacetUser1.modifySealedBidListing(diamondAddress.ERC1155, 1, 0, ethers.utils.parseEther('0.1'), '0x0000000000000000000000000000000000000000', 100, 2, 100, 100, 100)
    await tx.wait(1);

    tx = await marketplaceFulfillListingFacetUser1.fulfillStandardListing(diamondAddress.ERC1155, 1, 0, 1, { value: ethers.utils.parseEther('1') })
    await tx.wait(1);

    tx = await marketplaceFulfillOfferFacetUser2.fulfillOffer(users[1].address, 0, { value: ethers.utils.parseEther('1') })
    await tx.wait(1);

    tx = await marketplaceFulfillRequestFacetUser1.fulfillStandardRequest(diamondAddress.ERC1155, 1, 0, 1, { value: ethers.utils.parseEther('1') })
    await tx.wait(1);

    tx = await marketplaceFulfillAmountRequestFacetUser1.fulfillAmountRequest(diamondAddress.ERC1155, 1, 0, 1, { value: ethers.utils.parseEther('1') })
    await tx.wait(1);
  })
});