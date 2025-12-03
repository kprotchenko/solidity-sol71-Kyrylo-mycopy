// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TimeLockedWallet is ReentrancyGuard, Pausable, AccessControl {
    uint256 public constant MIN_DELAY = 1 minutes;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 private _nextDepositId;
    /*
     * TLW-1:	Checks: validate non-zero beneficiary, amount > 0, unlock time ≥ min delay, not paused.
     * Effects: create new lock struct, assign unique ID, index by beneficiary.
     * Interactions: none.
     */

    /*
     * Anyone can create a lock for a non-zero beneficiary with an amount and an unlock timestamp at least a minimum
     * delay from now.
     * Support many locks per beneficiary with unique ids.
     */
    struct TimeLockedDeposit {
        uint256 unlockTime; // The unlock timestamp (e.g., 1 min after block.timestamp at lock creation)
        uint256 amount; // The total amount being vested
        bool claimed;
    }

    /*
     * A mapping to store schedules, keyed by a unique identifier - scheduleId
     */
    mapping(uint256 => TimeLockedDeposit) public deposits; // id → struct
    mapping(address => uint256[]) public beneficiaryIds; // beneficiary → array of ids
    mapping(address => mapping(uint256 => bool)) public hasId; // beneficiary → idExists
    mapping(uint256 => bool) public exists; // depositId → idExists

    error DepositIsAbsent();
    error UnlockTimeIsTooSoon();

    event LockCreated(address beneficiary, uint256 depositId, uint256 unlockTime, uint256 amount);

    function createLock(address beneficiary, uint256 unlockTime) external payable whenNotPaused {
        if (msg.value == 0) revert DepositIsAbsent();
        if (block.timestamp + MIN_DELAY >= unlockTime) revert UnlockTimeIsTooSoon();
        uint256 id;
        unchecked {
            id = ++_nextDepositId;
        }

        // store struct
        deposits[id] = TimeLockedDeposit({ amount: msg.value, unlockTimestamp: unlockTime, claimed: false });
        // store enumeration
        beneficiaryIds[beneficiary].push(id);

        // store ownership
        hasId[beneficiary][id] = true;

        // store existence
        exists[id] = true;

        emit LockCreated(beneficiary, id, unlockTime, msg.value);
    }

    error InvalidId();
    error NotYourLock();
    error AlreadyClaimed();
    error ClaimFailed();

    event DepositClaimed(address beneficiary, address receiver, uint256 depositId);

    function claim(uint256 depositId, address receiver) external nonReentrant whenNotPaused {
        if (!exists[depositId]) revert InvalidId();
        if (!hasId[msg.sender][depositId]) revert NotYourLock();
        if (receiver == address(0)) receiver = msg.sender;
        TimeLockedDeposit storage lockedData = deposits[depositId];
        if (lockedData.claimed) revert AlreadyClaimed();
        lockedData.claimed = true;
        (bool success_for_claim,) = receiver.call{ value: lockedData.amount }("");
        if (!success_for_claim) revert ClaimFailed();
        emit DepositClaimed(msg.sender, receiver, depositId);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /*
     * TLW-2:	Reject any plain ETH transfers by reverting in receive() and fallback().
     */
    error RevertOnReceiveEmptyCallData();

    receive() external payable {
        revert RevertOnReceiveEmptyCallData();
    }

    error RevertOnFallbackWithCallData();

    fallback() external payable {
        revert RevertOnFallbackWithCallData();
    }

    /*
     * TLW-3:	Return stored lock data for given ID if it exists.
     */
    function getLockData(uint256 depositId) external returns (TimeLockedDeposit lockData) {
        if (!exists[depositId]) revert InvalidId();
        return deposits[depositId];
    }

    /*
    *TLW-4: Return stored list of lock IDs for a beneficiary without scanning all storage.
    */
    function getBeneficiaryIds(address beneficiary) external returns (uint256[] beneficiaryLockDataIds) {
        return deposits[beneficiary];
    }

    /*
    * TLW-5:	Checks: only beneficiary, lock exists, matured, not claimed/reclaimed, not paused.
    * Effects: mark claimed, calculate and accrue fee.
    * Interactions: low-level call to beneficiary, verify success.
    */

    /*
    * TLW-6:	Same as TLW-5 but sends payout to specified non-zero recipient instead of beneficiary.
    */

    /*
    * TLW-7:	Checks: only depositor, lock exists, matured + grace, not claimed/reclaimed, not paused.
    * Effects: mark reclaimed.
    * Interactions: low-level call to depositor for full amount, verify success.
    */

    /*
    * TLW-8:	Checks: array length ≤ MAX_BATCH, each lock valid, matured, belongs to caller, not claimed/reclaimed, not
    paused.
    * Effects: mark all claimed, sum payouts and fees, accrue fee.
    * Interactions: one low-level call to recipient for total payout, verify success.
    *
    */

    /*
    * TLW-9:	On successful single/batch payout, accrue protocol fee in internal balance; do not forward inline.
    */

    /*
    * TLW-10	Checks: admin only, valid to and amount ≤ accrued fees, not paused.
    * Effects: deduct from protocol fees.
    * Interactions: low-level call to recipient, verify success.
    */
}
