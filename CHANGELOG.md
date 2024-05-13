# Changelog

## [Unreleased]
- CIS-2 tokens with corrupted or missing metadata can no longer be added
- Inability to search for CIS-2 token by ID on contracts with lots of tokens


## [1.2.0] - 2022-05-...

### Added
- Add Mainnet, Stagenet and Testnet schemas
- Setting up and updating validator pool commission rates
- Support for WalletConnect CCD transfer requests
- Ability to see full details of a WalletConnect transaction to sign
- Validation of metadata checksum when adding CIS-2 tokens
- Display of balance/ownership when adding CIS-2 tokens
- Wallet Connect, add `sign message` functionality 

### Removed
- Unused code and logic

### Fixed
- An issue where signing a text message through WalletConnect did not work
- An issue where a dApp could request to get a transaction signed by a different account than the one chosen for the WalletConnect session
- An issue where the identity name was off-center when the edit name icon was visible
- "Invalid WalletConnect request" message repeatedly shown if received a request with unsupported transaction type
- Exported private key for file-based initial account being incompatible with concordium-client
- Possibility of spamming the app with WalletConnect requests from a malfunctioning dApp
- Fix changing restaking options
- Fix app crash during identities recover process

### Changed
- Baker/baking renamed to Validator/validating
- WalletConnect session proposals are now rejected if the namespace or methods are not supported, or if the wallet contains no accounts.
- WalletConnect transaction signing request now shows the receiver
(either smart contract or an account) and amount of CCD to send (not including CIS-2 tokens)
