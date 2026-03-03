const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("VibraniumSovereigntyProtocol", function () {
  let vsp;
  let owner;
  let recipient;

  const BASE_URI = "ipfs://bafybeihvibraniumsovereigntyprotocol/";

  // Token IDs
  const LONDC_PASSIVE_INCOME = 1n;
  const LONDYNS_LEGACY_GENESIS = 2n;
  const LONDYNS_LULLABY_LIFETIME = 3n;
  const VIBRANIUM_SOVEREIGNTY_SEAL = 4n;

  beforeEach(async function () {
    [owner, recipient] = await ethers.getSigners();
    const VSP = await ethers.getContractFactory("VibraniumSovereigntyProtocol");
    vsp = await VSP.deploy(owner.address, BASE_URI);
    await vsp.waitForDeployment();
  });

  // ── Deployment ─────────────────────────────────────────────────────────────
  describe("Deployment", function () {
    it("sets the owner correctly", async function () {
      expect(await vsp.owner()).to.equal(owner.address);
    });

    it("returns the correct URI for each token id", async function () {
      for (const id of [1n, 2n, 3n, 4n]) {
        expect(await vsp.uri(id)).to.equal(`${BASE_URI}${id}.json`);
      }
    });

    it("starts with zero supply for all token ids", async function () {
      for (const id of [1n, 2n, 3n, 4n]) {
        expect(await vsp["totalSupply(uint256)"](id)).to.equal(0n);
      }
    });
  });

  // ── Single mint ────────────────────────────────────────────────────────────
  describe("Single mint", function () {
    it("owner can mint a single token", async function () {
      await vsp.mint(recipient.address, LONDC_PASSIVE_INCOME, 1000n, "0x");
      expect(await vsp.balanceOf(recipient.address, LONDC_PASSIVE_INCOME)).to.equal(1000n);
    });

    it("non-owner cannot mint", async function () {
      await expect(
        vsp.connect(recipient).mint(recipient.address, LONDC_PASSIVE_INCOME, 1n, "0x")
      ).to.be.revertedWithCustomError(vsp, "OwnableUnauthorizedAccount");
    });

    it("enforces LONDC max supply cap", async function () {
      const maxSupply = await vsp.LONDC_MAX_SUPPLY();
      await expect(
        vsp.mint(recipient.address, LONDC_PASSIVE_INCOME, maxSupply + 1n, "0x")
      ).to.be.revertedWith("VSP: LONDC supply cap exceeded");
    });

    it("enforces Legacy Genesis max supply cap", async function () {
      const maxSupply = await vsp.LEGACY_GENESIS_MAX_SUPPLY();
      await expect(
        vsp.mint(recipient.address, LONDYNS_LEGACY_GENESIS, maxSupply + 1n, "0x")
      ).to.be.revertedWith("VSP: Legacy Genesis supply cap exceeded");
    });

    it("enforces Sovereignty Seal max supply cap", async function () {
      // First mint should succeed
      await vsp.mint(recipient.address, VIBRANIUM_SOVEREIGNTY_SEAL, 1n, "0x");
      // Second mint should exceed cap
      await expect(
        vsp.mint(recipient.address, VIBRANIUM_SOVEREIGNTY_SEAL, 1n, "0x")
      ).to.be.revertedWith("VSP: Sovereignty Seal supply cap exceeded");
    });
  });

  // ── Simultaneous (batch) mint ──────────────────────────────────────────────
  describe("Simultaneous (batch) minting", function () {
    it("mints multiple token types in a single transaction", async function () {
      const ids = [LONDC_PASSIVE_INCOME, LONDYNS_LEGACY_GENESIS, LONDYNS_LULLABY_LIFETIME];
      const amounts = [500n, 10n, 100n];

      await vsp.mintBatch(recipient.address, ids, amounts, "0x");

      for (let i = 0; i < ids.length; i++) {
        expect(await vsp.balanceOf(recipient.address, ids[i])).to.equal(amounts[i]);
      }
    });

    it("emits LondynsLegacyMinted event on batch mint", async function () {
      const ids = [LONDC_PASSIVE_INCOME, LONDYNS_LEGACY_GENESIS];
      const amounts = [100n, 1n];

      await expect(vsp.mintBatch(recipient.address, ids, amounts, "0x"))
        .to.emit(vsp, "LondynsLegacyMinted")
        .withArgs(recipient.address, ids, amounts);
    });

    it("reverts on ids/amounts length mismatch", async function () {
      await expect(
        vsp.mintBatch(recipient.address, [1n, 2n], [100n], "0x")
      ).to.be.revertedWith("VSP: ids/amounts length mismatch");
    });

    it("enforces supply caps within a batch", async function () {
      const maxSeal = await vsp.SEAL_MAX_SUPPLY();
      await expect(
        vsp.mintBatch(
          recipient.address,
          [VIBRANIUM_SOVEREIGNTY_SEAL],
          [maxSeal + 1n],
          "0x"
        )
      ).to.be.revertedWith("VSP: Sovereignty Seal supply cap exceeded");
    });

    it("non-owner cannot batch mint", async function () {
      await expect(
        vsp.connect(recipient).mintBatch(recipient.address, [1n], [1n], "0x")
      ).to.be.revertedWithCustomError(vsp, "OwnableUnauthorizedAccount");
    });
  });

  // ── Londyn's legacy first minting wave ────────────────────────────────────
  describe("mintLondynsLegacyWave (first minting wave)", function () {
    it("mints all four token archetypes simultaneously", async function () {
      await vsp.mintLondynsLegacyWave(recipient.address);

      expect(await vsp.balanceOf(recipient.address, LONDC_PASSIVE_INCOME)).to.equal(144_000n);
      expect(await vsp.balanceOf(recipient.address, LONDYNS_LEGACY_GENESIS)).to.equal(1n);
      expect(await vsp.balanceOf(recipient.address, LONDYNS_LULLABY_LIFETIME)).to.equal(1n);
      expect(await vsp.balanceOf(recipient.address, VIBRANIUM_SOVEREIGNTY_SEAL)).to.equal(1n);
    });

    it("emits LondynsLegacyMinted event with correct token data", async function () {
      const expectedIds = [
        LONDC_PASSIVE_INCOME,
        LONDYNS_LEGACY_GENESIS,
        LONDYNS_LULLABY_LIFETIME,
        VIBRANIUM_SOVEREIGNTY_SEAL,
      ];
      const expectedAmounts = [144_000n, 1n, 1n, 1n];

      await expect(vsp.mintLondynsLegacyWave(recipient.address))
        .to.emit(vsp, "LondynsLegacyMinted")
        .withArgs(recipient.address, expectedIds, expectedAmounts);
    });

    it("prevents double-execution of the seal (supply cap)", async function () {
      await vsp.mintLondynsLegacyWave(recipient.address);
      await expect(
        vsp.mintLondynsLegacyWave(recipient.address)
      ).to.be.revertedWith("VSP: Sovereignty Seal supply cap exceeded");
    });

    it("non-owner cannot trigger the first minting wave", async function () {
      await expect(
        vsp.connect(recipient).mintLondynsLegacyWave(recipient.address)
      ).to.be.revertedWithCustomError(vsp, "OwnableUnauthorizedAccount");
    });
  });

  // ── Base URI management ────────────────────────────────────────────────────
  describe("Base URI management", function () {
    it("owner can update the base URI", async function () {
      const newURI = "https://metadata.vibraniumsovereignty.io/tokens/";
      await expect(vsp.setBaseURI(newURI))
        .to.emit(vsp, "BaseURIUpdated")
        .withArgs(newURI);
      expect(await vsp.uri(1n)).to.equal(`${newURI}1.json`);
    });

    it("non-owner cannot update the base URI", async function () {
      await expect(
        vsp.connect(recipient).setBaseURI("https://evil.example.com/")
      ).to.be.revertedWithCustomError(vsp, "OwnableUnauthorizedAccount");
    });
  });
});
