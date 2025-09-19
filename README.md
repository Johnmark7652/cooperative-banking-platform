# Cooperative Banking Platform

A decentralized cooperative banking system built on the Stacks blockchain, enabling community-driven financial services including savings, loans, transfers, and goal-based savings.

## 🏦 Overview

The Cooperative Banking Platform is a smart contract that provides traditional banking services in a decentralized, community-owned model. Members can join the cooperative, make deposits, apply for loans, transfer funds to other members, and set savings goals - all governed by transparent smart contract logic.

## ✨ Features

### Core Banking Services
- **Member Management**: Join the cooperative and maintain member profiles
- **Deposits & Withdrawals**: Secure fund management with minimum balance requirements
- **Peer-to-Peer Transfers**: Direct transfers between cooperative members
- **Loan System**: Apply for, approve, and manage loans with collateral requirements
- **Savings Goals**: Set and track progress toward financial objectives

### Advanced Features
- **Credit Scoring**: Dynamic credit scores based on member activity and history
- **Interest Calculations**: Automated interest and payment calculations
- **Transaction History**: Complete audit trail of all platform activity
- **Platform Reserves**: Fee collection and reserve management
- **Administrative Controls**: Owner-managed platform parameters

## 🚀 Getting Started

### Prerequisites
- Stacks wallet with STX tokens
- Clarinet CLI for local development
- Node.js for running tests

### Deployment

1. **Clone and Setup**
```bash
git clone <repository-url>
cd cooperative-banking-platform
clarinet check
```

2. **Deploy to Testnet**
```bash
clarinet deploy --network testnet
```

3. **Deploy to Mainnet**
```bash
clarinet deploy --network mainnet
```

## 📋 Contract Functions

### Member Management

#### `join-cooperative()`
Join the cooperative as a new member.
- **Returns**: `(response bool uint)`
- **Errors**: `ERR-ALREADY-MEMBER (108)`

#### `get-member-info(member: principal)`
Retrieve member information and statistics.
- **Returns**: Member data including balance, deposits, withdrawals, credit score

### Banking Operations

#### `deposit(amount: uint)`
Deposit STX tokens into your cooperative account.
- **Parameters**: 
  - `amount`: Amount to deposit (must be > 0)
- **Returns**: `(response uint uint)`
- **Errors**: `ERR-INVALID-AMOUNT (103)`, `ERR-MEMBER-NOT-FOUND (107)`

#### `withdraw(amount: uint)`
Withdraw STX tokens from your account.
- **Parameters**:
  - `amount`: Amount to withdraw
- **Requirements**: Must maintain minimum balance of 0.1 STX
- **Returns**: `(response uint uint)`
- **Errors**: `ERR-INSUFFICIENT-BALANCE (101)`, `ERR-MINIMUM-BALANCE-REQUIRED (106)`

#### `transfer(recipient: principal, amount: uint)`
Transfer funds to another cooperative member.
- **Parameters**:
  - `recipient`: Member to receive funds
  - `amount`: Amount to transfer
- **Returns**: `(response uint uint)`
- **Errors**: `ERR-MEMBER-NOT-FOUND (107)`, `ERR-INSUFFICIENT-BALANCE (101)`

### Loan System

#### `apply-for-loan(amount: uint, term-blocks: uint, collateral: uint)`
Apply for a loan from the cooperative.
- **Parameters**:
  - `amount`: Loan amount requested
  - `term-blocks`: Loan duration (max 365 blocks)
  - `collateral`: Collateral amount (min 50% of loan)
- **Requirements**: 
  - Credit score ≥ 400
  - Sufficient collateral
- **Returns**: `(response uint uint)` - Loan ID
- **Errors**: `ERR-INVALID-LOAN-TERM (109)`, `ERR-UNAUTHORIZED (100)`

#### `approve-loan(loan-id: uint)` [Owner Only]
Approve a pending loan application.
- **Parameters**:
  - `loan-id`: ID of loan to approve
- **Access**: Contract owner only
- **Returns**: `(response bool uint)`

#### `make-loan-payment(loan-id: uint, payment-amount: uint)`
Make a payment toward an active loan.
- **Parameters**:
  - `loan-id`: Loan identifier
  - `payment-amount`: Payment amount
- **Returns**: `(response uint uint)`
- **Note**: 1% platform fee applies

### Savings Goals

#### `create-savings-goal(goal-id: uint, target-amount: uint, target-date: uint, description: string-ascii 100)`
Create a new savings goal.
- **Parameters**:
  - `goal-id`: Unique goal identifier
  - `target-amount`: Target savings amount
  - `target-date`: Target completion date (block height)
  - `description`: Goal description (max 100 chars)
- **Returns**: `(response uint uint)`

#### `add-to-savings-goal(goal-id: uint, amount: uint)`
Add funds to an existing savings goal.
- **Parameters**:
  - `goal-id`: Goal identifier  
  - `amount`: Amount to add
- **Returns**: `(response uint uint)`

## 📊 Platform Statistics

### `get-platform-stats()`
Get comprehensive platform statistics including:
- Total deposits across all members
- Total active loans
- Platform reserve funds
- Transaction counters

## ⚙️ Configuration

### Constants
- **Minimum Balance**: 0.1 STX (100,000 microSTX)
- **Maximum Loan Term**: 365 blocks (~1 year)
- **Interest Rate**: 5% annual
- **Platform Fee**: 1% on loan payments
- **Minimum Credit Score**: 400 (for loans)
- **Minimum Collateral**: 50% of loan amount

### Error Codes
| Code | Error | Description |
|------|-------|-------------|
| 100 | ERR-UNAUTHORIZED | Insufficient permissions |
| 101 | ERR-INSUFFICIENT-BALANCE | Not enough funds |
| 102 | ERR-ACCOUNT-NOT-FOUND | Account doesn't exist |
| 103 | ERR-INVALID-AMOUNT | Invalid amount specified |
| 104 | ERR-LOAN-NOT-FOUND | Loan doesn't exist |
| 105 | ERR-LOAN-ALREADY-APPROVED | Loan already processed |
| 106 | ERR-MINIMUM-BALANCE-REQUIRED | Below minimum balance |
| 107 | ERR-MEMBER-NOT-FOUND | Member doesn't exist |
| 108 | ERR-ALREADY-MEMBER | Already a cooperative member |
| 109 | ERR-INVALID-LOAN-TERM | Loan term exceeds maximum |
| 110 | ERR-LOAN-OVERDUE | Loan payment overdue |

## 🧪 Testing

Run the comprehensive test suite:

```bash
npm test
```

The test suite covers:
- Member management and validation
- All banking operations
- Loan lifecycle management
- Savings goals functionality
- Credit score calculations
- Error handling
- Administrative functions

## 🔐 Security Features

### Access Controls
- Member-only functions require cooperative membership
- Administrative functions restricted to contract owner
- Loan operations limited to borrowers and owner

### Financial Safeguards
- Minimum balance requirements prevent account depletion
- Collateral requirements reduce loan default risk
- Credit score system promotes responsible borrowing
- Platform fee collection ensures sustainability

### Data Integrity
- Complete transaction logging
- Immutable member records
- Automatic balance reconciliation
- Transparent interest calculations

## 🏗️ Architecture

### Data Structures
- **Members Map**: Member profiles and account data
- **Loans Map**: Loan applications and status
- **Transactions Map**: Complete transaction history
- **Savings Goals Map**: Member savings objectives

### Key Functions
- **Helper Functions**: Utility functions for calculations
- **Private Functions**: Internal contract logic
- **Public Functions**: External interface for users
- **Read-Only Functions**: Data access without state changes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For questions, issues, or contributions:
- Create an issue in the GitHub repository
- Join our community Discord
- Review the documentation in `/docs`

## 🚧 Roadmap

### Phase 1 (Current)
- ✅ Basic banking operations
- ✅ Loan system
- ✅ Savings goals
- ✅ Credit scoring

### Phase 2 (Planned)
- [ ] Interest-bearing savings accounts
- [ ] Multi-signature loan approvals
- [ ] Governance token integration
- [ ] Advanced analytics dashboard

### Phase 3 (Future)
- [ ] Cross-chain integrations
- [ ] DeFi protocol partnerships
- [ ] Mobile application
- [ ] Institutional features

---

**Built with ❤️ on Stacks blockchain**

*Empowering communities through decentralized cooperative banking*