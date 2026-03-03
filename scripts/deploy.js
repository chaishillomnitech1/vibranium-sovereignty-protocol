const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

/**
 * Deployment script for VibraniumSovereigntyProtocol on Sepolia testnet.
 *
 * Required environment variables:
 *   DEPLOYER_PRIVATE_KEY  — Private key of the deployer wallet
 *   SEPOLIA_RPC_URL       — Sepolia JSON-RPC endpoint
 *   LONDC_METADATA_BASE_URI — Base URI for token metadata (default: ipfs://[CID]/)
 *
 * After deployment the script:
 *   1. Executes the first Londyn's legacy minting wave (mintLondynsLegacyWave).
 *   2. Writes deployment details to metadata/deployment_metadata.json.
 */
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying VibraniumSovereigntyProtocol with account:", deployer.address);

  const baseURI =
    process.env.LONDC_METADATA_BASE_URI ||
    "ipfs://bafybeihvibraniumsovereigntyprotocol/";

  // ── Deploy contract ────────────────────────────────────────────────────────
  const VSP = await ethers.getContractFactory("VibraniumSovereigntyProtocol");
  const vsp = await VSP.deploy(deployer.address, baseURI);
  await vsp.waitForDeployment();

  const contractAddress = await vsp.getAddress();
  console.log("VibraniumSovereigntyProtocol deployed to:", contractAddress);

  // ── First minting wave — Londyn's legacy ──────────────────────────────────
  console.log("Executing Londyn's Legacy first minting wave…");
  const mintTx = await vsp.mintLondynsLegacyWave(deployer.address);
  const receipt = await mintTx.wait();
  console.log("Minting wave confirmed in tx:", receipt.hash);

  // ── Persist deployment metadata ────────────────────────────────────────────
  const network = await ethers.provider.getNetwork();
  const deploymentData = {
    protocolName: "Vibranium Sovereignty Protocol",
    version: "1.0.0",
    description: "ERC-1155 smart contract for $LONDC passive income flow and Londyn's legacy.",
    authors: ["chaishillomnitech1"],
    network: {
      name: network.name,
      chainId: network.chainId.toString(),
    },
    contractAddress,
    deployer: deployer.address,
    baseURI,
    deployedAt: new Date().toISOString(),
    firstMintingWave: {
      transactionHash: receipt.hash,
      tokens: [
        { id: 1, name: "$LONDC Passive Income Token", amount: 144000 },
        { id: 2, name: "Londyn's Legacy Genesis NFT", amount: 1 },
        { id: 3, name: "Londyn's Lullaby Lifetime", amount: 1 },
        { id: 4, name: "Vibranium Sovereignty Seal", amount: 1 },
      ],
    },
  };

  const metadataPath = path.join(__dirname, "../metadata/deployment_metadata.json");
  fs.writeFileSync(metadataPath, JSON.stringify(deploymentData, null, 2));
  console.log("Deployment metadata written to", metadataPath);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
