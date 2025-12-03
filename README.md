# solidity-sol71-Kyrylo
# [Module 6](https://app.metana.io/lessons/%f0%9f%93%91-assignments-m6-5/)

Build a time-locked wallet that holds ETH for a beneficiary until a future time. Anyone can create a lock for a non-zero beneficiary with an amount and an unlock timestamp at least a minimum delay from now. Support many locks per beneficiary with unique ids.

Expose simple views to discover and inspect locks. Emit events for creation and payout. Reject direct ETH that bypasses lock creation.
## 💰 Claiming Funds
A beneficiary can claim a matured lock. Let them optionally choose a payout recipient at claim time. Enforce checks-effects-interactions. Update storage so a second payout can’t occur.

Transfer with a low-level call and verify success. Emit a payout event.

## ♻️ Reclaiming Funds
Add a reclaim path. If a lock stays unclaimed after a grace period past the unlock time, the original depositor may reclaim the funds. Apply the same protections.

Update state before transfer. Verify the call result.

## 📦 Batch Claim
Support batch claim. Let a beneficiary claim several matured locks in one transaction. Update state for each selected lock before any external transfer. Revert cleanly if any selected lock is ineligible.

Keep the batch gas-bounded by:

- Setting a fixed maximum number of IDs per call (e.g., 32).
- Doing constant work per ID only, no storage scans
- Update state for all IDs before making one transfer
- Revert if the cap is exceeded or any ID is invalid or ineligible.

## 🏦 Protocol Fee
Accrue a small protocol fee on each successful payout to an internal balance. Do not forward the fee inline. Provide a separate admin-only fee withdrawal path.

## 🛡️ Security & Controls
Protect that path the same way as other value-moving functions. Include pause controls that block creation, claims, reclaims, batch claims, and fee withdrawals while paused.

Use custom errors. Do not rely on tx.origin. Use OpenZeppelin where it helps, such as ReentrancyGuard and Pausable.

## 🧪 Testing & Verification

Your tests must prove that all value-moving paths are not reentrant: single claim, batch claim, reclaim, and fee withdrawal.

Run Foundry fuzz tests to check security.

<table >
    <colgroup>
        <col style="text-align:left;">
        <col style="text-align:left;">
    </colgroup>
    <tr> <th>ID</th><th>Behavior</th></tr>
    <tr> <th style="text-align:left;">TLW-1 </th><th style="text-align:left;">Checks: validate non-zero beneficiary, amount > 0, unlock time ≥ min delay, not paused. Effects: create new lock struct, assign unique ID, index by beneficiary. Interactions: none.</th></tr>
    <tr> <th style="text-align:left;">TLW-2 </th><th style="text-align:left;">Reject any plain ETH transfers by reverting in receive() and fallback().</th></tr>
    <tr> <th style="text-align:left;">TLW-3 </th><th style="text-align:left;">Return stored lock data for given ID if it exists.</th></tr>
    <tr> <th style="text-align:left;">TLW-4 </th><th style="text-align:left;">Return stored list of lock IDs for a beneficiary without scanning all storage.</th></tr>
    <tr> <th style="text-align:left;">TLW-5 </th><th style="text-align:left;">Checks: only beneficiary, lock exists, matured, not claimed/reclaimed, not paused. Effects: mark claimed, calculate and accrue fee. Interactions: low-level call to beneficiary, verify success.</th></tr>
    <tr> <th style="text-align:left;">TLW-6 </th><th style="text-align:left;">Same as TLW-5 but sends payout to specified non-zero recipient instead of beneficiary.</th></tr>
    <tr> <th style="text-align:left;">TLW-7 </th><th style="text-align:left;">Checks: only depositor, lock exists, matured + grace, not claimed/reclaimed, not paused. Effects: mark reclaimed. Interactions: low-level call to depositor for full amount, verify success.</th></tr>
    <tr> <th style="text-align:left;">TLW-8 </th><th style="text-align:left;">Checks: array length ≤ MAX_BATCH, each lock valid, matured, belongs to caller, not claimed/reclaimed, not paused. Effects: mark all claimed, sum payouts and fees, accrue fee. Interactions: one low-level call to recipient for total payout, verify success.</th></tr>
    <tr> <th style="text-align:left;">TLW-9 </th><th style="text-align:left;">On successful single/batch payout, accrue protocol fee in internal balance; do not forward inline.</th></tr>
    <tr> <th style="text-align:left;">TLW-10 </th><th style="text-align:left;">Checks: admin only, valid to and amount ≤ accrued fees, not paused. Effects: deduct from protocol fees. Interactions: low-level call to recipient, verify success.</th></tr>
    <tr> <th style="text-align:left;">TLW-11 </th><th style="text-align:left;">Admin can pause/unpause; paused state blocks create, claim, reclaim, batch claim, and fee withdrawal.</th></tr>
<tr> <th style="text-align:left;">TLW-12 </th><th style="text-align:left;">Apply nonReentrant to all ETH-moving functions and follow checks-effects-interactions; batch updates state for all IDs before any transfer.</th></tr>
</table>


## Challenges
### [Ethernaut](https://ethernaut.openzeppelin.com)

- [Ethernaut 0 → Hello Ethernaut](https://ethernaut.openzeppelin.com/level/0)
- [Ethernaut 1 → Fallback](https://ethernaut.openzeppelin.com/level/1)
- [Ethernaut 3 → Coin Flip](https://ethernaut.openzeppelin.com/level/3)
- [Ethernaut 5 → Token](https://ethernaut.openzeppelin.com/level/5)
- [Ethernaut 11 → Elevator](https://ethernaut.openzeppelin.com/level/11)
- [Ethernaut 13 → Gatekeeper One](https://ethernaut.openzeppelin.com/level/13)
- [Ethernaut 20 → Denial](https://ethernaut.openzeppelin.com/level/20)
- [Ethernaut 21 → Shop](https://ethernaut.openzeppelin.com/level/21)
## Secureum
- [MagicETH](https://github.com/secureum/AMAZEX-DSS-PARIS/tree/main/src/1_MagicETH)
- [ModernETH](https://github.com/secureum/AMAZEX-DSS-PARIS/tree/main/src/1_MagicETH)
*****************************************************************************************************
```
# Folowing dependencies are needed for project to be deployed locally. 
# Run the comand below in terminal:

forge install OpenZeppelin/openzeppelin-contracts@v5.4.0 --no-git
forge install foundry-rs/forge-std --no-git
```
*****************************************************************************************************
```
# Following variables need to be defined in .env file locally to run script/part-A/VestingTokenAndVault.s.sol
# I provided examples values from Anvil but you are welcome to change them.


## ANVIL Local network
PK_FOR_ANVIL=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
PAUSER=0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
PAUSEER_PK=0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
BASE_URI=ipfs://some-ipfs-hash/

## Module 4: Part A
TOKEN_ADMIN=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
TOKEN_ADMIN_PK=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
VAULT_ADMIN=0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f
VAULT_ADMIN_PK=0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
BENEFICIARY=0x14dC79964da2C08b23698B3D3cc7Ca32193d9955
BENEFICIARY_PK=0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
BLOCK_TIME=1762461462

## Module 4: Part B
CID=some0ipfs0hash
ITEM_ADMIN=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
ITEM_ADMIN_PK=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
ITEM_MINTER=0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f
ITEM_MINTER_PK=0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
ITEM_GETTER=0x14dC79964da2C08b23698B3D3cc7Ca32193d9955
ITEM_GETTER_PK=0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356

## Module 4: Part C
CRATE_ADMIN=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
CRATE_ADMIN_PK=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
CRATE_GETTER=0x14dC79964da2C08b23698B3D3cc7Ca32193d9955
CRATE_GETTER_PK=0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
```
*****************************************************************************************************

```
# The following commands have to be executed to deploy locally contracts for al three parts.

anvil
set -a; source .env; set +a
forge clean && forge build


##########################################################################
########### Part A – ERC-20 VestingToken and VestingVault 🏦 #############
##########################################################################

#Local
# deployment script handles chain contract deployment and initial role granting:
forge script script/part-A/VestingTokenAndVault.s.sol:VestingTokenAndVaultScript \
    --rpc-url anvil --private-key $PK_FOR_ANVIL --broadcast -vvvv
#Testing
forge test --match-path test/part-A/VestingVault.t.sol -vvvvv

# You can also deploy the contract using the command line:
forge create src/part-A/VestingToken.sol:VestingToken \
    --rpc-url anvil \
    --private-key $PK_FOR_ANVIL \
    --broadcast \
    --constructor-args "VestingToken0" "VT0" $TOKEN_ADMIN
# After you know the address of the deployed VestingToken contract, save it as $TOKEN
# you can then deploy the VestingVault contract
forge create src/part-A/VestingVault.sol:VestingVault \
    --rpc-url anvil \
    --private-key $PK_FOR_ANVIL \
    --broadcast \
    --constructor-args $TOKEN $VAULT_ADMIN
# Once you know the address of deployed VestingVault contract save it as $VAULT
# call grantRole function to grant the MINTER_ROLE to the VestingVault contract
cast send $TOKEN \
"grantRole(bytes32,address)" \
$(cast keccak "MINTER_ROLE") \
$VAULT \
--rpc-url anvil --private-key $TOKEN_ADMIN_PK


##########################################################################
########### Part B – ERC-721 MetaverseItem NFT collection 🎮 #############
##########################################################################

## PINATA API Key Information ##
# Pinata API URL: https://api.pinata.cloud/
# Pinata API Key: 333333333333333
# Pinata API Secret: bigsecretpinatakey1234567890
# Pinate JWT (secret access token): bigsecretjwt1234567890

forge script script/part-B/MetaverseItem.s.sol:MetaverseItemScript \
  --rpc-url anvil --private-key $PK_FOR_ANVIL --broadcast -vvvv

forge test --match-path test/part-B/MetaverseItem.t.sol -vvvvv

##########################################################################
################## Part C – ERC-1155 LootCrate1155 📦 ####################
##########################################################################

forge script script/part-C/LootCrate.s.sol:LootCrateScript \
  --rpc-url anvil --private-key $PK_FOR_ANVIL --broadcast -vvvv

forge test --match-path test/part-C/LootCrate.t.sol -vvvvv
```

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
