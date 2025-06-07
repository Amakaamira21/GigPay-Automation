# Freelance Work and Payment Automation Smart Contract

A decentralized freelance platform built on the Stacks blockchain that automates payments, manages milestones, and provides escrow functionality for freelance work contracts.

## 🚀 Features

- **Automated Escrow**: Funds are held in smart contract escrow until milestones are completed
- **Milestone-Based Payments**: Break projects into milestones with automatic payment triggers
- **Rating System**: Built-in reputation system for clients and freelancers
- **Dispute Resolution**: Contract owner can resolve disputes between parties
- **Platform Fees**: Configurable platform fee system (default 2.5%)
- **Contract Management**: Create, cancel, and complete contracts with full transparency

## 📋 Contract Functions

### Core Functions

#### `create-contract`
Creates a new freelance contract with escrowed funds.

**Parameters:**
- `freelancer`: Principal address of the freelancer
- `title`: Contract title (max 100 characters)
- `description`: Contract description (max 500 characters)
- `total-amount`: Total contract amount in microSTX
- `deadline`: Contract deadline as block height

#### `add-milestone`
Adds a milestone to an existing contract (client only).

**Parameters:**
- `contract-id`: ID of the contract
- `milestone-id`: Unique milestone identifier
- `description`: Milestone description (max 200 characters)
- `amount`: Milestone payment amount in microSTX
- `due-date`: Milestone deadline as block height

#### `submit-milestone`
Freelancer submits completed milestone work.

**Parameters:**
- `contract-id`: ID of the contract
- `milestone-id`: ID of the milestone being submitted

#### `approve-milestone`
Client approves milestone and triggers automatic payment.

**Parameters:**
- `contract-id`: ID of the contract
- `milestone-id`: ID of the milestone to approve

### Contract Management

#### `complete-contract`
Marks contract as complete and returns unused funds to client.

#### `cancel-contract`
Cancels active contract and refunds all escrowed funds to client.

#### `submit-rating`
Submit rating and review after contract completion (1-5 stars).

### Read-Only Functions

- `get-contract`: Retrieve contract details
- `get-milestone`: Retrieve milestone information
- `get-contract-funds`: Check escrowed funds
- `get-rating`: Retrieve ratings and reviews
- `calculate-platform-fee`: Calculate platform fee for given amount

### Admin Functions

#### `set-platform-fee`
Contract owner can adjust platform fee (max 10%).

#### `resolve-dispute`
Contract owner resolves disputes by awarding funds to either party.

## 🏗️ Project Structure

```
freelance-contract/
├── contracts/
│   └── freelance-contract.clar     # Main smart contract
├── tests/
│   └── freelance-contract.test.ts  # Comprehensive test suite
├── README.md                       # This file
└── package.json                    # Dependencies and scripts
```

## 🛠️ Setup and Development

### Prerequisites

- [Node.js](https://nodejs.org/) (v14 or higher)
- [Clarinet](https://github.com/hirosystems/clarinet) for Stacks development
- [Stacks CLI](https://docs.stacks.co/build-apps/references/stacks-cli) for deployment

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd freelance-contract
```

2. Install dependencies:
```bash
npm install
```

3. Install Clarinet:
```bash
# macOS
brew install clarinet

# Windows/Linux - Download from GitHub releases
```

### Development

1. Initialize Clarinet project (if not already done):
```bash
clarinet new freelance-contract
```

2. Check contract syntax:
```bash
clarinet check
```

3. Run tests:
```bash
# Clarinet tests
clarinet test

# Vitest unit tests
npm test
```

4. Open Clarinet console for interactive testing:
```bash
clarinet console
```

## 🧪 Testing

The project includes comprehensive tests written in both Clarinet and Vitest:

### Clarinet Tests
Traditional Clarinet test files for integration testing with the Stacks blockchain simulation.

### Vitest Unit Tests
Isolated unit tests focusing on individual contract functions:

```bash
npm test              # Run all tests
npm run test:watch    # Run tests in watch mode
npm run test:coverage # Generate coverage report
```

**Test Coverage:**
- ✅ Contract creation and validation
- ✅ Milestone management workflow
- ✅ Payment automation and escrow
- ✅ Rating and review system
- ✅ Error handling and edge cases
- ✅ Administrative functions
- ✅ Complete integration scenarios

## 🚀 Deployment

### Testnet Deployment

1. Configure your Stacks wallet:
```bash
stx make_keychain -t
```

2. Deploy to testnet:
```bash
clarinet deployments apply -p testnet
```

### Mainnet Deployment

1. Update `Clarinet.toml` for mainnet configuration
2. Deploy to mainnet:
```bash
clarinet deployments apply -p mainnet
```

## 📊 Contract Economics

### Platform Fees
- **Default Fee**: 2.5% of milestone payments
- **Maximum Fee**: 10% (enforced by contract)
- **Fee Calculation**: Deducted from freelancer payment on milestone approval

### Gas Costs (Estimated)
- Contract Creation: ~0.005 STX
- Milestone Addition: ~0.002 STX
- Milestone Approval: ~0.003 STX
- Contract Completion: ~0.002 STX

## 🔒 Security Features

### Access Controls
- Only clients can create milestones and approve payments
- Only freelancers can submit milestone work
- Only contract owner can resolve disputes and adjust fees

### Fund Safety
- All funds held in contract escrow
- Automatic refunds on contract cancellation
- Platform fees only deducted on successful milestone completion

### Error Handling
Comprehensive error codes for all failure scenarios:
- `ERR_NOT_AUTHORIZED` (u100)
- `ERR_CONTRACT_NOT_FOUND` (u101)
- `ERR_INVALID_STATUS` (u102)
- `ERR_INSUFFICIENT_FUNDS` (u103)
- `ERR_MILESTONE_NOT_FOUND` (u104)
- `ERR_ALREADY_COMPLETED` (u105)
- `ERR_NOT_CLIENT` (u106)
- `ERR_NOT_FREELANCER` (u107)

## 🎯 Usage Examples

### Creating a Contract
```clarity
(contract-call? .freelance-contract create-contract
  'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5  ; freelancer
  "Website Development"                             ; title
  "Build responsive e-commerce website"            ; description
  u50000000                                        ; 50 STX
  u1000)                                           ; deadline
```

### Adding a Milestone
```clarity
(contract-call? .freelance-contract add-milestone
  u1                                    ; contract-id
  u1                                    ; milestone-id
  "Frontend Development"                ; description
  u25000000                            ; 25 STX
  u500)                                ; due-date
```

### Approving Payment
```clarity
(contract-call? .freelance-contract approve-milestone
  u1                                    ; contract-id
  u1)                                   ; milestone-id
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Make your changes and add tests
4. Run the test suite: `npm test`
5. Commit your changes: `git commit -am 'Add new feature'`
6. Push to the branch: `git push origin feature/new-feature`
7. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [Stacks Documentation](https://docs.stacks.co/)
- **Issues**: Create an issue in this repository
- **Community**: Join the [Stacks Discord](https://discord.gg/stacks)

## 🛣️ Roadmap

- [ ] Multi-token support (SIP-010 tokens)
- [ ] Reputation scoring system
- [ ] Automated dispute resolution via oracles
- [ ] Integration with IPFS for file storage
- [ ] Mobile app interface
- [ ] Advanced milestone dependencies
- [ ] Recurring contract templates

## ⚠️ Disclaimer

This smart contract is provided as-is for educational and development purposes. Always conduct thorough testing and security audits before deploying to mainnet with real funds.

---

**Built with ❤️ on Stacks blockchain**