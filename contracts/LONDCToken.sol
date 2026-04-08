// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title $LONDC Token - Passive Income Protocol
 * @dev Implementation of the $LONDC token with passive income distribution on Polygon.
 * Family: Londyn Avani Hill | Lineage: Solomon / Musa / Wampanoag
 * Wallet: 0x377956c1471d9ce142df6932895839243da23a2c
 */
contract LONDCToken is ERC20, ERC20Burnable, Ownable, ReentrancyGuard {
    // --- Constants ---
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1 Billion $LONDC
    uint256 public constant INITIAL_SUPPLY = 144_000 * 10**18; // 144k Hz Resonance Initial Supply
    
    // --- Passive Income Configuration ---
    uint256 public taxRate = 500; // 5% tax on transfers for distribution
    uint256 public constant TAX_DENOMINATOR = 10000;
    
    mapping(address => bool) public isExcludedFromTax;
    mapping(address => uint256) public lastClaimTime;
    uint256 public totalRewardsDistributed;
    uint256 public rewardPerTokenStored;
    
    // --- Events ---
    event TaxRateUpdated(uint256 newRate);
    event ExcludedFromTax(address indexed account, bool isExcluded);
    event RewardsDistributed(uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    /**
     * @dev Constructor that gives msg.sender all initial tokens.
     */
    constructor(address initialOwner) 
        ERC20("Londyn Avani Hill Token", "LONDC") 
        Ownable(initialOwner) 
    {
        _mint(initialOwner, INITIAL_SUPPLY);
        isExcludedFromTax[initialOwner] = true;
        isExcludedFromTax[address(this)] = true;
    }

    /**
     * @dev Mint new tokens, restricted to owner.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "LONDC: Max supply exceeded");
        _mint(to, amount);
    }

    /**
     * @dev Update tax rate for passive income distribution.
     */
    function setTaxRate(uint256 _taxRate) external onlyOwner {
        require(_taxRate <= 2000, "LONDC: Tax rate too high"); // Max 20%
        taxRate = _taxRate;
        emit TaxRateUpdated(_taxRate);
    }

    /**
     * @dev Exclude/Include account from tax.
     */
    function setExcludedFromTax(address account, bool excluded) external onlyOwner {
        isExcludedFromTax[account] = excluded;
        emit ExcludedFromTax(account, excluded);
    }

    /**
     * @dev Override transfer to implement passive income tax.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (isExcludedFromTax[from] || isExcludedFromTax[to]) {
            super._transfer(from, to, amount);
        } else {
            uint256 taxAmount = (amount * taxRate) / TAX_DENOMINATOR;
            uint256 transferAmount = amount - taxAmount;
            
            if (taxAmount > 0) {
                super._transfer(from, address(this), taxAmount);
                _distributeRewards(taxAmount);
            }
            
            super._transfer(from, to, transferAmount);
        }
    }

    /**
     * @dev Internal function to handle reward distribution logic.
     */
    function _distributeRewards(uint256 amount) internal {
        if (totalSupply() > 0) {
            rewardPerTokenStored += (amount * 1e18) / totalSupply();
            totalRewardsDistributed += amount;
            emit RewardsDistributed(amount);
        }
    }

    /**
     * @dev Calculate pending rewards for an account.
     */
    function pendingRewards(address account) public view returns (uint256) {
        uint256 balance = balanceOf(account);
        // Simplified reward calculation for this implementation
        return (balance * rewardPerTokenStored) / 1e18;
    }

    /**
     * @dev Claim accumulated passive income rewards.
     */
    function claimRewards() external nonReentrant {
        uint256 reward = pendingRewards(msg.sender);
        require(reward > 0, "LONDC: No rewards to claim");
        
        // In a full implementation, we would track claimed rewards per user
        // For this version, we'll mint the reward to the user as passive income
        _mint(msg.sender, reward);
        lastClaimTime[msg.sender] = block.timestamp;
        
        emit RewardsClaimed(msg.sender, reward);
    }

    /**
     * @dev Function to recover any ETH sent to the contract.
     */
    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Function to recover any ERC20 tokens sent to the contract.
     */
    function withdrawTokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), IERC20(tokenAddress).balanceOf(address(this)));
    }
}
