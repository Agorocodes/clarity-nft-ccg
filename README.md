# Decentralized Collectible Card Game (CCG) Smart Contract

## Overview

This smart contract is designed for a Decentralized Collectible Card Game (CCG) where users can mint, burn, transfer, and update unique collectible cards (NFTs). Built on the Clarity blockchain, the contract allows the owner to manage card creation, while enabling users to interact with the cards through ownership and actions like burning or transferring. The cards are represented as Non-Fungible Tokens (NFTs) that have a unique URI and an owner.

## Features

- **Mint Cards**: The contract allows the minting of individual or batches of cards.
- **Burn Cards**: Owners can burn their cards, permanently removing them from circulation.
- **Transfer Cards**: Cards can be transferred between users, allowing players to trade or share cards.
- **Update Card URI**: The URI of a card can be updated, allowing for changes to the metadata of each card.
- **Batch Operations**: Multiple cards can be minted in a single operation, streamlining the card creation process.

## Constants

- `contract-owner`: The address of the contract owner (only the owner can mint cards).
- `max-batch-size`: Maximum number of cards that can be minted in a single batch (set to 100).

## Data Variables

- `card-nft`: The NFT representing the cards.
- `last-card-id`: Tracks the last card ID minted.
- `card-uri`: A mapping to store the URIs associated with each card.
- `burned-cards`: A mapping that tracks burned cards to prevent re-burns.
- `batch-metadata`: Stores metadata related to card batches.

## Error Codes

- `err-owner-only`: Error when a non-owner tries to mint a card.
- `err-card-not-owner`: Error when a non-owner tries to burn or transfer a card.
- `err-card-exists`: Error when trying to mint a card that already exists.
- `err-card-not-found`: Error when a card is not found.
- `err-invalid-card-uri`: Error when the URI provided is invalid.
- `err-already-burned`: Error when trying to burn an already burned card.
- `err-invalid-batch-size`: Error when an invalid batch size is specified.

## Functions

### Public Functions

- `mint-card(card-uri)`: Mint a single card with a unique URI. Only the contract owner can call this function.
- `batch-mint-cards(uris)`: Mint multiple cards in a batch. The batch size is limited by `max-batch-size`.
- `burn-card(card-id)`: Burn a card, permanently removing it from circulation. Only the card owner can burn their card.
- `transfer-card(card-id, sender, recipient)`: Transfer a card from one user to another.
- `update-card-uri(card-id, new-uri)`: Update the URI of a card. Only the card owner can update the URI.

### Read-Only Functions

- `get-card-uri(card-id)`: Retrieve the URI associated with a card.
- `get-owner(card-id)`: Retrieve the owner of a card.
- `get-last-card-id()`: Get the last minted card's ID.
- `is-burned(card-id)`: Check if a card has been burned.
- `get-batch-card-ids(start-id, count)`: Retrieve a batch of card IDs starting from a given ID.

## Setup

### Prerequisites

- Clarity smart contract environment (e.g., the Stacks blockchain) to deploy and interact with the contract.
- A basic understanding of NFTs and Clarity smart contracts.

### Contract Deployment

1. Deploy the smart contract to the blockchain environment.
2. Set the `contract-owner` to the deployer's address to ensure only they can mint cards.

## Example Usage

1. **Minting a Single Card:**
   ```clarity
   mint-card("uri-for-card-1")
   ```

2. **Batch Minting Cards:**
   ```clarity
   batch-mint-cards(["uri-1", "uri-2", "uri-3"])
   ```

3. **Burning a Card:**
   ```clarity
   burn-card(1)
   ```

4. **Transfer a Card:**
   ```clarity
   transfer-card(1, "sender-address", "recipient-address")
   ```

5. **Update Card URI:**
   ```clarity
   update-card-uri(1, "new-uri")
   ```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For more information, please contact the repository maintainer.
