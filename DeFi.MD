
### 📄 `DeFi.md` – Full-Stack DeFi Protocol Assignment Document

---

# 💸 DeFi Protocol for Research & Tool Validation

This project implements a realistic **upgradeable DeFi protocol** for testing and validating our **smart contract upgrade detection tool**, as part of our security research publication.

---

## 🧩 Module Breakdown & Team Responsibilities

---

### 🅰️ Part A – **Smart Contract Development**

> 👤 Assigned to: **Ayushman & Ravi**

#### 📌 Responsibilities:

* Design and implement the following contracts:

  * `Vault.sol`: deposit/withdraw logic
  * `Strategy.sol`: mock yield logic
  * `Controller.sol`: routes funds to strategy
  * `Token.sol`: ERC20 for deposits
* Integrate OpenZeppelin's UUPSUpgradeable
* Ensure proper inheritance, storage layout, and logic separation
* Write constructorless upgradeable contracts with `initialize()` functions

#### 📁 Files:

* `contracts/Vault.sol`
* `contracts/Strategy.sol`
* `contracts/Controller.sol`
* `contracts/Token.sol`

---

### 🅱️ Part B – **Testing & Deployment**

> 👤 Assigned to: **Ravi & Ayushman**

#### 📌 Responsibilities:

* Set up Hardhat framework
* Configure upgrade plugins for UUPS and Proxy
* Write TypeScript unit tests for all contracts
* Deploy and upgrade contracts using scripts
* Test compatibility after upgrades (storage, logic)

#### 📁 Files:

* `test/vault.test.ts`
* `test/controller.test.ts`
* `scripts/deploy.js`
* `scripts/upgrade.js`
* `hardhat.config.ts`

---

### 🅲 Part C – **Frontend Development**

> 👤 Assigned to: **Neha & Ritika**

#### 📌 Responsibilities:

* Build a frontend using **Next.js**, **wagmi**, and **RainbowKit**
* Implement wallet connection (MetaMask)
* Create UI to:

  * Deposit and withdraw into vault
  * Show balances and earnings
  * Trigger `harvest()` (mock yield)
* Handle transaction status, loading states, and errors

#### 📁 Files:

* `frontend/pages/index.tsx`
* `frontend/components/WalletConnect.tsx`
* `frontend/components/VaultUI.tsx`
* `frontend/hooks/useVault.ts`

---

### 🅳 Part D – **Detection Tool Integration & Research Dataset**

> 👤 Assigned to: **Ravi & Ayushman**

#### 📌 Responsibilities:

* Deploy DeFi protocol to Anvil or Sepolia
* Run upgrade detection tool (`upgrade_detector.py`) against contracts
* Log output as structured JSON/CSV
* Validate tool performance vs real contract behavior
* Help in preparing dataset for paper

#### 📁 Files:

* `tool/run_detector.py`
* `datasets/output.csv`
* `datasets/analysis_notes.md`
* `README.md`

---

## 🔁 Workflow Guidelines

* Create feature branches by module (`feature/contracts`, `feature/frontend`, etc.)
* Use Pull Requests for all merges
* Run tests on every commit (`npm run test` in `/test`)
* Deploy to Anvil before Sepolia

---

## 🧪 Deliverables by Module

| Module | Output                                         |
| ------ | ---------------------------------------------- |
| A      | Upgradeable smart contracts                    |
| B      | Complete test coverage + deploy + upgrade test |
| C      | Web dApp for interacting with protocol         |
| D      | Detection tool results + research dataset      |

---

✅ Sync when you feel it's neccessary 
✅ Internal demo after each part completes

---