# 🛡️ Guardian Multi-Sig Vault

A professional-grade, high-security M-of-N Multi-Signature Wallet built in Solidity. This protocol allows a group of owners to manage shared funds, requiring a specific threshold of approvals before any transaction can be executed.

## 🚀 Key Features
- **M-of-N Approval Logic**: Flexible threshold management for transaction execution.
- **Gas Optimized**: Uses custom errors (0.8.26+) and `external` function visibility to reduce transaction costs.
- **Security-First Design**: Strict adherence to the **Checks-Effects-Interactions (CEI)** pattern to prevent reentrancy.
- **State Machine Flow**: Clear transaction lifecycle: `Submitted` -> `Confirmed` -> `Executed`.

## 🏗️ Technical Architecture

### Core Data Structures
- **Structs**: Transactions are stored as structs to maintain clarity and state.
- **Nested Mappings**: Uses `mapping(uint256 => mapping(address => bool))` to track individual owner confirmations with $O(1)$ efficiency.
- **Storage Management**: Utilizes an `address[]` for enumeration and a `mapping(address => bool)` for gas-efficient access control.



### Security Implementations
1. **Reentrancy Protection**: All state updates (marking as `executed`) occur before external ETH transfers.
2. **Input Validation**: Rigorous checks in the constructor to prevent "bricking" (e.g., threshold > owner count).
3. **Custom Errors**: Replaced string-based reverts with gas-efficient `error` types.

## 🛠️ Usage

### 1. Deployment
Deploy the contract by passing an array of owner addresses and the required number of confirmations.
```solidity
// Example: 3 owners, 2 required confirmations
constructor(["0x123...", "0x456...", "0x789..."], 2);
