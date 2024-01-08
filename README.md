# Quarry Draw NFTs Marketplace Contracts

The NFTs Marketplce of QuarryDraw is a very adaptable and comprehensive marketplace. You can trade ERC721 and ERC1155 with a multitude of exchange types such as Standard listing, Timer listing, Dutch lisitng, English listing, Sealed bid listing, Standard request, Timer request, Dutch request and Amount request. You can find out more informations and a very detailed description about each listing in the contract `./contracts/marketplace/facets/MarketplaceFacet.sol`.

This project uses a gas-optimized reference implementation for [EIP-2535 Diamonds](https://github.com/ethereum/EIPs/issues/2535). To learn more about this and other implementations go here: https://github.com/mudgen/diamond

This implementation uses Hardhat and Solidity 0.8.*

## Installation

1. Clone this repo:
```sh
git clone git@github.com:Puddi1/QD-Marketplace-Contracts.git
```

2. Install NPM packages:
```sh
cd QD-Marketplace-Contracts
npm i
```

## Compile

To compile the contracts in `./contract` run:

```sh
npx hardhat compile
```

Their artifacts will be placed in `./artifacts/contracts`

## Tests

To run test, which are stored in `./test` run:

```sh
npx hardhat test
```

## Deployment

Deployments scripts are handled in `./scripts`, to deploy:

```sh
npx hardhat run scripts/deploy.js
```
