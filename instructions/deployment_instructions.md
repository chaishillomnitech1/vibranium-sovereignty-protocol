# Vibranium Sovereignty Protocol Deployment

## Description
ERC-1155 smart contract for the `$LONDC` passive income flow and Londyn's legacy.
Deployable to Sepolia testnet using Hardhat; supports simultaneous (batch) minting.

## Prerequisites
- Node.js ≥ 18  
- A funded Sepolia wallet (get testnet ETH from a Sepolia faucet)  
- A Sepolia RPC URL (e.g. from Alchemy or Infura)  
- Optional: Etherscan API key for contract verification

## Setup
```bash
git clone https://github.com/chaishillomnitech1/vibranium-sovereignty-protocol.git
cd vibranium-sovereignty-protocol
npm install
```

## Configure environment variables
Create a `.env` file (never commit this file):
```
DEPLOYER_PRIVATE_KEY=0xYOUR_PRIVATE_KEY
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
LONDC_METADATA_BASE_URI=ipfs://YOUR_CID/
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_KEY
```

## Compile
```bash
npm run compile
```

## Test (simultaneous minting validation)
```bash
npm test
```

## Deploy to Sepolia
```bash
npm run deploy:sepolia
```

The script will:
1. Deploy the `VibraniumSovereigntyProtocol` ERC-1155 contract.
2. Execute the **first minting wave** (`mintLondynsLegacyWave`) — simultaneously minting all four token archetypes to the deployer.
3. Write updated deployment details to `metadata/deployment_metadata.json`.

## Token IDs
| ID | Name | Max Supply |
|----|------|-----------|
| 1 | $LONDC Passive Income Token | 1,000,000,000 |
| 2 | Londyn's Legacy Genesis NFT | 777 |
| 3 | Londyn's Lullaby Lifetime | 144,000 |
| 4 | Vibranium Sovereignty Seal | 1 |

## Authors
- chaishillomnitech1

## License
MIT License.