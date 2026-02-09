# 0xAudit Crypto Wallet

## Public Address
`0xf6b21245A1462DfF04bf15D8AA1435aC964Faf34`

## Supported Networks (EVM-Compatible)
| Network | Chain ID | Explorer |
|---------|----------|----------|
| Ethereum Mainnet | 1 | etherscan.io |
| BSC | 56 | bscscan.com |
| Polygon | 137 | polygonscan.com |
| Arbitrum One | 42161 | arbiscan.io |
| Base | 8453 | basescan.org |
| Optimism | 10 | optimistic.etherscan.io |

## Security
- ⚠️ Private key stored ENCRYPTED in `.wallet-encrypted` (AES-256-CBC, PBKDF2)
- ⚠️ Mnemonic stored ENCRYPTED in `.mnemonic-encrypted`
- 🔑 Decryption key stored OUTSIDE workspace at `/tmp/.wallet-decryption-key`
- ❌ NEVER commit decryption key to git

## Created
- Date: 2026-02-09
- Generator: ethers.js v6
