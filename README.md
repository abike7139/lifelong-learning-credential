# Lifelong Learning Credential Contract System

A blockchain-based smart contract system built with Clarity for managing professional credentials, skill verification, and career development tracking.

## Overview

This project implements a comprehensive lifelong learning ecosystem on the Stacks blockchain, enabling:

- **Skill Verification & Competency Tracking**: Issue and verify professional credentials and competencies
- **Professional Development**: Track ongoing education, certifications, and career advancement
- **Career Pathway Planning**: Support career progression and advancement planning
- **Industry Alignment**: Analyze job market trends and skill demand
- **Learning Investment ROI**: Measure return on investment for educational activities

## Architecture

The system consists of three core smart contracts:

### 1. Credential Core (`credential-core.clar`)
Handles the issuance, verification, and management of digital credentials and professional certifications.

### 2. Competency Tracker (`competency-tracker.clar`)
Tracks individual competencies, professional development activities, and learning investment returns.

### 3. Career Path (`career-path.clar`)
Manages career planning, industry alignment, and job market analysis features.

## Key Features

- **Decentralized Credential Issuance**: Issue tamper-proof digital credentials
- **Skill Verification**: Verify authenticity of professional skills and certifications
- **Progress Tracking**: Monitor learning progress and professional development
- **ROI Measurement**: Calculate return on investment for educational activities
- **Industry Analysis**: Track job market trends and skill demand
- **Career Planning**: Support structured career advancement pathways

## Technology Stack

- **Blockchain**: Stacks Blockchain
- **Smart Contract Language**: Clarity
- **Development Framework**: Clarinet
- **Testing**: Vitest/Node.js
- **Version Control**: Git + GitHub

## Getting Started

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) CLI tool
- Node.js 16+ 
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/abike7139/lifelong-learning-credential.git
cd lifelong-learning-credential
```

2. Install dependencies:
```bash
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## Usage

### Deploying Contracts

Use Clarinet to deploy contracts to your preferred Stacks network:

```bash
# Deploy to devnet
clarinet deploy --devnet

# Deploy to testnet  
clarinet deploy --testnet
```

### Interacting with Contracts

The contracts provide public functions for:

- Issuing new credentials
- Verifying credential authenticity
- Tracking competency development
- Recording learning investments
- Planning career pathways
- Analyzing industry trends

## Development

### Project Structure

```
├── contracts/           # Clarity smart contracts
├── tests/              # Contract tests
├── settings/           # Network configurations
├── Clarinet.toml       # Clarinet configuration
├── package.json        # Node.js dependencies
└── README.md          # Project documentation
```

### Running Tests

```bash
# Run all tests
npm test

# Check contract syntax
clarinet check

# Generate test coverage
npm run test:coverage
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

- GitHub: [@abike7139](https://github.com/abike7139)
- Project Link: [https://github.com/abike7139/lifelong-learning-credential](https://github.com/abike7139/lifelong-learning-credential)

## Acknowledgments

- Built with [Clarity](https://clarity-lang.org/) smart contract language
- Developed using [Clarinet](https://docs.hiro.so/clarinet) development framework
- Deployed on [Stacks Blockchain](https://www.stacks.co/)
