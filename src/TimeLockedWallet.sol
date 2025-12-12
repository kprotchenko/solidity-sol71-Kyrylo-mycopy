// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TimeLockedWallet is ReentrancyGuard, Pausable, AccessControl {
    uint256 public constant MIN_DELAY = 1 minutes;
    uint256 public constant GRACE_PERIOD = 1 years;
    uint256 public constant PROTOCOL_FEE = 0.01;
    uint256 public constant MAX_NUMBER_OF_DEPOSITS_PER_BATCH = 32;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public _nextDepositId;
    uint256 public _accruedFees;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
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
    mapping(address => mapping(uint256 => bool)) public beneficiaryHasId; // beneficiary → idExists
    mapping(address => mapping(uint256 => bool)) public depositorHasId; // depositor → idExists
    mapping(uint256 => bool) public exists; // depositId → idExists

    error DepositIsAbsent();
    error ClaimTimeIsTooSoon();

    event LockCreated(address beneficiary, uint256 depositId, uint256 unlockTime, uint256 amount);

    function createLock(address beneficiary, uint256 unlockTime) external payable whenNotPaused {
        if (msg.value == 0) revert DepositIsAbsent();
        if (block.timestamp + MIN_DELAY >= unlockTime) revert ClaimTimeIsTooSoon();
        uint256 id;
        unchecked {
            id = ++_nextDepositId;
        }

        // store struct
        deposits[id] = TimeLockedDeposit({ amount: msg.value, unlockTimestamp: unlockTime, claimed: false });
        // store enumeration
        beneficiaryIds[beneficiary].push(id);

        // store ownership
        beneficiaryHasId[beneficiary][id] = true;
        depositorHasId[msg.sender][id] = true;

        // store existence
        exists[id] = true;

        emit LockCreated(beneficiary, id, unlockTime, msg.value);
    }

    error ClaimFailed();

    event DepositClaimed(address beneficiary, address receiver, uint256 depositId);

    function claim(uint256 depositId, address receiver) external nonReentrant whenNotPaused {
        uint256 _value = basicChecksAndEffectsThenGetReceiversAmount(depositId, false);

        // Optional receiver -> default to msg.sender
        if (receiver == address(0)) receiver = msg.sender;

        // Interactions (CEI pattern)
        (bool success_for_claim,) = receiver.call{ value: _value }("");
        if (!success_for_claim) revert ClaimFailed();

        // Log
        emit DepositClaimed(msg.sender, receiver, depositId);
    }

    error ReclaimTimeIsTooSoon();
    error ReclaimFailed();

    event DepositReclaimed(address depositor, uint256 depositId);

    function reclaim(uint256 depositId) external nonReentrant whenNotPaused {
        uint256 _value = basicChecksAndEffectsThenGetReceiversAmount(depositId, true);

        // 7. Interactions (CEI pattern)
        (bool success_for_reclaim,) = msg.sender.call{ value: _value }("");
        if (!success_for_reclaim) revert ReclaimFailed();

        // 8. Log
        emit DepositReclaimed(msg.sender, depositId);
    }

    error NumberOfDepositsGreaterThenMax();
    error ButchClaimFailed();

    event DepositsClaimed(address beneficiary, address receiver, uint256[] depositIds);

    function butchClaim(uint256[] depositIds, address receiver) external nonReentrant whenNotPaused {
        if (depositIds.length > MAX_NUMBER_OF_DEPOSITS_PER_BATCH) revert NumberOfDepositsGreaterThenMax();
        // 0. Optional receiver -> defaults to msg.sender
        if (receiver == address(0)) receiver = msg.sender;
        uint256 _value = 0;
        for (uint256 i = 0; i < depositIds.length; i++) {
            uint256 depositId = depositIds[i];
            _value += basicChecksAndEffectsThenGetReceiversAmount(depositId, false);
        }
        // 7. Interactions (CEI pattern)
        (bool success_for_claim,) = receiver.call{ value: _value }("");
        if (!success_for_claim) revert ButchClaimFailed();
        // 8. Log
        emit DepositsClaimed(msg.sender, receiver, depositIds);
    }

    error InvalidId();
    error NotYourLock();
    error NotOneOfYourLocks(uint256 depositId);
    error AlreadyClaimed();

    function basicChecksAndEffectsThenGetReceiversAmount(uint256 depositId, bool isReclaim)
        internal
        returns (uint256 protocol_fee_amount)
    {
        // 1. Checks
        // 1.1. ID must exist
        if (!exists[depositId]) revert InvalidId();

        if (isReclaim) {
            // 1.2. ID must belong to depositor who is a msg.sender
            if (!depositorHasId[msg.sender][depositId]) revert NotYourLock();
        } else {
            // 1.2. ID must belong to beneficiary who is a msg.sender
            if (!beneficiaryHasId[msg.sender][depositId]) revert NotOneOfYourLocks(depositId);
        }

        // 1.3. Load the deposit from storage
        TimeLockedDeposit storage lockedData = deposits[depositId];

        // 1.4. Cannot claim twice
        if (lockedData.claimed) revert AlreadyClaimed();

        if (isReclaim) {
            // 1.5. Cannot reclaim till after the GRACE_PERIOD is passed
            if (block.timestamp < lockedData.unlockTime + GRACE_PERIOD) revert ReclaimTimeIsTooSoon();
        } else {
            // 1.5. Cannot claim before unlock time
            if (block.timestamp < lockedData.unlockTime) revert ClaimTimeIsTooSoon();
        }

        // 2. Effects
        lockedData.claimed = true;
        uint256 protocol_fee_amount = lockedData.amount * PROTOCOL_FEE;
        unchecked {
            _accruedFees += protocol_fee_amount;
        }

        return lockedData.amount - protocol_fee_amount;
    }

    error NoFeesAccruedToWithdraw();
    error BalanceTooSmallToWithdraw();
    error WithdrawalFailed();
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant whenNotPaused{
        // CHECKS
        if(_accruedFees == 0) revert NoFeesAccruedToWithdraw();
        if(address(this).balance < _accruedFees) revert BalanceTooSmallToWithdraw();

        // EFFECTS
        uint256 amountToWithdraw = _accruedFees;
        _accruedFees = 0;
        // INTERACTIONS
        (bool success_for_withdrawal,) = msg.sender.call{ value: amountToWithdraw }("");
        if (!success_for_withdrawal) revert WithdrawalFailed();
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
