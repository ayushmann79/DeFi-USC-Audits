# Minimal DeFi Lending Pool

This repository contains a minimal, non-upgradable Decentralized Finance (DeFi) Lending Pool smart contract system built using Solidity and developed with the Foundry toolchain.

It implements the core lending functionalities: deposit (minting aTokens), borrow (minting debt tokens), repay, and liquidation. The system utilizes OpenZeppelin contracts for standard features like ERC20, Ownable, and ReentrancyGuard.

---

## Project Structure

The codebase is organized following a standard Foundry project layout:

| Directory  | Description |
|------------|-------------|
| `src/` | Contains the main Solidity smart contracts. |
| `src/governance/` | Contracts for access control (e.g., AccessControl). |
| `src/tokens/` | Custom ERC20 implementations: AToken (depositor receipt) and DebtToken (variable debt). |
| `src/utils/` | Helper contracts like Oracle and InterestRateModel, and custom Errors. |
| `script/` | Deployment and setup scripts for different environments. |
| `test/` | Comprehensive tests written in Solidity (using forge-std/Test.sol). |
| `lib/` | Project dependencies (managed via Git submodules or forge install), including forge-std and openzeppelin-contracts. |

---

## Key Contracts

| Contract | Location | Description |
|-----------|-----------|-------------|
| **LendingPool** | `src/LendingPool.sol` | The core protocol contract. Manages deposits, borrows, liquidations, and tracks user accounts. |
| **AToken** | `src/tokens/AToken.sol` | Represents deposited assets. Minted 1:1 upon deposit, burned upon withdrawal. Acts as a vault for underlying tokens. |
| **DebtToken** | `src/tokens/DebtToken.sol` | Represents a borrower's variable debt. Minted upon borrowing, burned upon repayment. |
| **Oracle** | `src/utils/Oracle.sol` | Provides asset price feeds (in $10^8$ USD) necessary for solvency checks and liquidation calculations. |
| **AccessControl** | `src/governance/AccessControl.sol` | Extends Ownable to include a guardian role for emergency actions or two-step ownership. |

---

## Core Logic Notes

**Health Factor:**  
Calculated based on the user's Loan-to-Value (LTV) adjusted collateral vs. total debt (both valued in USD × 10⁸).  
A health factor below 1 (represented as 10¹⁸ in the smart contract) indicates a liquidatable position.

**Liquidation:**  
Liquidators repay a portion of a user's debt (debtAsset) and seize the user's collateral (collateralAsset) plus a defined liquidation bonus (in basis points).

**Reserves:**  
Each supported asset (e.g., DAI, USDC) is configured via a `Reserve` struct, which stores parameters like LTV, liquidation threshold, and references to its associated AToken, DebtToken, and InterestRateModel.

---

## Getting Started (Foundry)

### Prerequisites

Install Foundry by following the official installation guide:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Installation

Clone the repository and install dependencies:
```
    git clone https://github.com/ayushmann79/DeFi-USC-Audits.git 
    cd defi-lending
```

```
    forge install
```

Build the Project
```
    forge build
```

Running Tests
```
    forge test
```

Deployment

The script folder contains deployment logic for listing new reserves and setting up the protocol.

DeployLendingPoolScript.sol demonstrates how to deploy the core contracts and list initial assets (e.g., DAI and USDC mocks) with the following parameters:



Future Enhancements

This minimal version can be extended with additional features:

Interest Accrual: Implement logic within the LendingPool to utilize the InterestRateModel for updating user balances over time.

Variable/Stable Borrowing: Introduce stable debt tokens and allow multiple borrow types.

Flash Loans: Add a function for uncollateralized instant loans.

Upgradability: Introduce a Proxy pattern for upgradeable contracts.

Governance: Extend AccessControl for full DAO-based governance and administrative control.