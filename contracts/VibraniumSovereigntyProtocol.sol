// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VibraniumSovereigntyProtocol
 * @notice ERC-1155 contract for the $LONDC passive income flow and Londyn's legacy minting wave.
 *         Deployed on Sepolia testnet; supports simultaneous (batch) minting.
 *
 * Token IDs
 * ---------
 * 1  — $LONDC Passive Income Token  (fungible, royalty-yielding utility token)
 * 2  — Londyn's Legacy Genesis NFT  (Londyn's legacy anchor, first minting wave)
 * 3  — Londyn's Lullaby Lifetime    (music/IP rights anchor)
 * 4  — Vibranium Sovereignty Seal   (governance / ScrollVault authority token)
 */
contract VibraniumSovereigntyProtocol is ERC1155, ERC1155Supply, Ownable {
    // ── Token IDs ────────────────────────────────────────────────────────────
    uint256 public constant LONDC_PASSIVE_INCOME = 1;
    uint256 public constant LONDYNS_LEGACY_GENESIS = 2;
    uint256 public constant LONDYNS_LULLABY_LIFETIME = 3;
    uint256 public constant VIBRANIUM_SOVEREIGNTY_SEAL = 4;

    // ── Token supply caps ────────────────────────────────────────────────────
    uint256 public constant LONDC_MAX_SUPPLY = 1_000_000_000; // 1 billion utility tokens
    uint256 public constant LEGACY_GENESIS_MAX_SUPPLY = 777;  // Londyn's legacy — 777 editions
    uint256 public constant LULLABY_MAX_SUPPLY = 144_000;     // 144,000 Hz resonance
    uint256 public constant SEAL_MAX_SUPPLY = 1;              // Unique sovereignty seal

    // ── Base URI ─────────────────────────────────────────────────────────────
    string private _baseURI;

    // ── Events ───────────────────────────────────────────────────────────────
    event BaseURIUpdated(string newBaseURI);
    event LONDCPassiveIncomeMinted(address indexed to, uint256 amount);
    event LondynsLegacyMinted(address indexed to, uint256[] ids, uint256[] amounts);

    // ── Constructor ──────────────────────────────────────────────────────────
    constructor(address initialOwner, string memory baseURI_)
        ERC1155(baseURI_)
        Ownable(initialOwner)
    {
        _baseURI = baseURI_;
    }

    // ── URI override ─────────────────────────────────────────────────────────
    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, _uint256ToString(id), ".json"));
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    // ── Single mint ──────────────────────────────────────────────────────────
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {
        _requireWithinSupplyCap(id, amount);
        _mint(account, id, amount, data);
    }

    // ── Batch (simultaneous) mint ────────────────────────────────────────────
    /// @notice Simultaneously mint multiple token types in a single transaction.
    function mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        require(ids.length == amounts.length, "VSP: ids/amounts length mismatch");
        for (uint256 i = 0; i < ids.length; i++) {
            _requireWithinSupplyCap(ids[i], amounts[i]);
        }
        _mintBatch(account, ids, amounts, data);
        emit LondynsLegacyMinted(account, ids, amounts);
    }

    // ── First minting wave — Londyn's legacy ─────────────────────────────────
    /// @notice Executes the first minting wave for Londyn's legacy, anchoring
    ///         all four token archetypes simultaneously.
    function mintLondynsLegacyWave(address recipient) external onlyOwner {
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);

        ids[0] = LONDC_PASSIVE_INCOME;      amounts[0] = 144_000;
        ids[1] = LONDYNS_LEGACY_GENESIS;    amounts[1] = 1;
        ids[2] = LONDYNS_LULLABY_LIFETIME;  amounts[2] = 1;
        ids[3] = VIBRANIUM_SOVEREIGNTY_SEAL; amounts[3] = 1;

        for (uint256 i = 0; i < ids.length; i++) {
            _requireWithinSupplyCap(ids[i], amounts[i]);
        }

        _mintBatch(recipient, ids, amounts, "");
        emit LondynsLegacyMinted(recipient, ids, amounts);
    }

    // ── Internal helpers ─────────────────────────────────────────────────────
    function _requireWithinSupplyCap(uint256 id, uint256 amount) internal view {
        if (id == LONDC_PASSIVE_INCOME) {
            require(totalSupply(id) + amount <= LONDC_MAX_SUPPLY, "VSP: LONDC supply cap exceeded");
        } else if (id == LONDYNS_LEGACY_GENESIS) {
            require(totalSupply(id) + amount <= LEGACY_GENESIS_MAX_SUPPLY, "VSP: Legacy Genesis supply cap exceeded");
        } else if (id == LONDYNS_LULLABY_LIFETIME) {
            require(totalSupply(id) + amount <= LULLABY_MAX_SUPPLY, "VSP: Lullaby supply cap exceeded");
        } else if (id == VIBRANIUM_SOVEREIGNTY_SEAL) {
            require(totalSupply(id) + amount <= SEAL_MAX_SUPPLY, "VSP: Sovereignty Seal supply cap exceeded");
        }
    }

    function _uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // ── ERC1155Supply override ────────────────────────────────────────────────
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
}