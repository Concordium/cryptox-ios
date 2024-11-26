# Changelog

## [Released 2.0.1] 2024-26-11

### Fixed
- An issue with recovering from file when app is opened
- An issue with displaying old feed
- Fixed Concordex connectivity issue.
- Improved recover from file journey.

## [Released 2.0.0]

### Removed
- Removed Shielding functionalty
- Removed old-legacy `Send Assets` flow 

### Added
- Add Mainnet, Stagenet and Testnet schemas
- Setting up and updating validator pool commission rates
- Support for WalletConnect CCD transfer requests
- Ability to see full details of a WalletConnect transaction to sign
- Validation of metadata checksum when adding CIS-2 tokens
- Display of balance/ownership when adding CIS-2 tokens
- Wallet Connect, add `sign message` functionality 
- Add new Unshield Assets flow
- Add CCD onramp flow
- Add News Tab
- Add Expport/Import Wallet Private key
- Add Push Notifications for incoming transactions both ccd and CIS2Token
- Support for Protocol 7 – reducing validation/delegation stake no longer locks the whole amount 

### Fixed
- An issue where signing a text message through WalletConnect did not work
- An issue where a dApp could request to get a transaction signed by a different account than the one chosen for the WalletConnect session
- An issue where the identity name was off-center when the edit name icon was visible
- "Invalid WalletConnect request" message repeatedly shown if received a request with unsupported transaction type
- Exported private key for file-based initial account being incompatible with concordium-client
- Possibility of spamming the app with WalletConnect requests from a malfunctioning dApp
- Fix changing restaking options
- Fix app crash during identities recover process
- Fixed Send Assets Flow
- Fixed Wallet Connect connection issue

### Changed
- Baker/baking renamed to Validator/validating
- Removed all `anon*` references 
- WalletConnect session proposals are now rejected if the namespace or methods are not supported, or if the wallet contains no accounts.
- WalletConnect transaction signing request now shows the receiver
(either smart contract or an account) and amount of CCD to send (not including CIS-2 tokens)
