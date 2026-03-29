// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ChartClash
 * @notice Prediction market contract for BTC UP/DOWN betting on Polygon
 * @dev Uses a trusted backend oracle for price settlement
 *      Internal balance model: users deposit USDT once, bet/withdraw from internal balance
 */
contract ChartClash is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    // ─────────────────────────────────────────────
    // State Variables
    // ─────────────────────────────────────────────

    IERC20 public immutable usdt;
    address public oracle;               // trusted backend wallet that submits close prices
    uint256 public withdrawFeeBps = 100; // 1% fee (100 / 10000)
    uint256 public constant FEE_DENOM = 10_000;
    uint256 public constant HOUSE_FEE_BPS = 300; // 3% house cut (YELLOW/RED zone)
    uint256 public constant GREEN_FEE_BPS  = 100; // 1% house cut (GREEN zone — early bettor reward)

    mapping(address => uint256) public balances; // internal USDT balances (6 decimals)
    uint256 public accumulatedFees;              // tracked house + withdraw fees only

    struct Bet {
        uint256 amount;
        bool isUp;
        bool claimed;
        uint8 zone; // 0=GREEN (<33%), 1=YELLOW (33-66%), 2=RED (66-90%), BLOCK (>=90%) not stored
    }

    struct Round {
        string  asset;          // e.g. "BTCUSDT"
        string  timeframe;      // e.g. "1h"
        uint256 openPrice;      // price * 1e6
        uint256 openTime;       // when betting opened (unix timestamp)
        uint256 closeTime;      // unix timestamp
        uint256 upPool;         // total UP bets
        uint256 downPool;       // total DOWN bets
        uint256 closePrice;     // set on settlement
        bool    settled;
        bool    cancelled;      // true if no bets on one side → refund all
    }

    mapping(uint256 => Round) public rounds;
    mapping(uint256 => mapping(address => Bet)) public bets;
    uint256 public nextRoundId = 1;

    // ─────────────────────────────────────────────
    // Events
    // ─────────────────────────────────────────────

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);
    event RoundCreated(uint256 indexed roundId, string asset, string timeframe, uint256 openTime, uint256 closeTime);
    event BetPlaced(uint256 indexed roundId, address indexed user, bool isUp, uint256 amount, uint8 zone);
    event RoundSettled(uint256 indexed roundId, uint256 closePrice, bool upWon);
    event RoundCancelled(uint256 indexed roundId);
    event Claimed(uint256 indexed roundId, address indexed user, uint256 amount);
    event OracleUpdated(address indexed newOracle);

    // ─────────────────────────────────────────────
    // Modifiers
    // ─────────────────────────────────────────────

    modifier onlyOracle() {
        require(msg.sender == oracle, "ChartClash: caller is not oracle");
        _;
    }

    // ─────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────

    constructor(address _usdt, address _oracle) Ownable(msg.sender) {
        require(_usdt != address(0), "Invalid USDT address");
        require(_oracle != address(0), "Invalid oracle address");
        usdt = IERC20(_usdt);
        oracle = _oracle;
    }

    // ─────────────────────────────────────────────
    // Admin Functions
    // ─────────────────────────────────────────────

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Invalid oracle");
        oracle = _oracle;
        emit OracleUpdated(_oracle);
    }

    function setWithdrawFee(uint256 _bps) external onlyOwner {
        require(_bps <= 500, "Max 5%");
        withdrawFeeBps = _bps;
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    /**
     * @notice Emergency: return all user funds during a pause
     * Only callable when paused
     */
    function emergencyWithdrawFor(address[] calldata users) external onlyOwner whenPaused {
        for (uint256 i = 0; i < users.length; i++) {
            uint256 bal = balances[users[i]];
            if (bal > 0) {
                balances[users[i]] = 0;
                usdt.safeTransfer(users[i], bal);
            }
        }
    }

    /**
     * @notice Collect ONLY accumulated house fees — cannot touch user deposits
     */
    function collectFees() external onlyOwner {
        uint256 amount = accumulatedFees;
        require(amount > 0, "No fees to collect");
        accumulatedFees = 0;
        usdt.safeTransfer(owner(), amount);
    }

    // ─────────────────────────────────────────────
    // Deposit / Withdraw
    // ─────────────────────────────────────────────

    /**
     * @notice Deposit USDT into internal balance
     * @dev User must approve this contract first
     */
    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Zero amount");
        // CEI: update state before external call
        balances[msg.sender] += amount;
        usdt.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Withdraw USDT from internal balance (1% fee deducted)
     */
    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Zero amount");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        uint256 fee = (amount * withdrawFeeBps) / FEE_DENOM;
        uint256 payout = amount - fee;

        // CEI: update state before external call
        balances[msg.sender] -= amount;
        accumulatedFees += fee;  // track fee — cannot be collected until claimable

        usdt.safeTransfer(msg.sender, payout);
        emit Withdrawn(msg.sender, payout, fee);
    }

    // ─────────────────────────────────────────────
    // Round Management (Oracle)
    // ─────────────────────────────────────────────

    /**
     * @notice Create a new prediction round
     */
    function createRound(
        string calldata asset,
        string calldata timeframe,
        uint256 openPrice,
        uint256 closeTime
    ) external onlyOracle returns (uint256 roundId) {
        require(closeTime > block.timestamp, "Close time must be in future");

        roundId = nextRoundId++;
        rounds[roundId] = Round({
            asset: asset,
            timeframe: timeframe,
            openPrice: openPrice,
            openTime: block.timestamp,
            closeTime: closeTime,
            upPool: 0,
            downPool: 0,
            closePrice: 0,
            settled: false,
            cancelled: false
        });

        emit RoundCreated(roundId, asset, timeframe, block.timestamp, closeTime);
    }

    // ─────────────────────────────────────────────
    // Betting
    // ─────────────────────────────────────────────

    /**
     * @notice Place a bet on a round using internal balance
     */
    function placeBet(
        uint256 roundId,
        bool isUp,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        Round storage r = rounds[roundId];
        require(r.closeTime > 0, "Round does not exist");
        require(!r.settled && !r.cancelled, "Round ended");
        require(bets[roundId][msg.sender].amount == 0, "Already bet this round");
        require(amount > 0, "Zero amount");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // ── Zone calculation ──────────────────────────────────────────
        uint256 duration = r.closeTime - r.openTime;
        uint256 elapsed  = block.timestamp > r.openTime ? block.timestamp - r.openTime : 0;

        // BLOCK zone: last 10% of candle → betting not allowed
        require(elapsed * 10 < duration * 9, "Bet window closed (BLOCK zone)");

        // Zone: 0=GREEN (<33%), 1=YELLOW (33-66%), 2=RED (66-90%)
        uint8 zone;
        if (elapsed * 3 < duration) {
            zone = 0; // GREEN
        } else if (elapsed * 3 < duration * 2) {
            zone = 1; // YELLOW
        } else {
            zone = 2; // RED
        }
        // ─────────────────────────────────────────────────────────────

        require(block.timestamp < r.closeTime, "Round is closed");

        // Deduct from internal balance
        balances[msg.sender] -= amount;

        // Record bet with zone
        bets[roundId][msg.sender] = Bet({ amount: amount, isUp: isUp, claimed: false, zone: zone });

        // Add to pool
        if (isUp) {
            r.upPool += amount;
        } else {
            r.downPool += amount;
        }

        emit BetPlaced(roundId, msg.sender, isUp, amount, zone);
    }

    // ─────────────────────────────────────────────
    // Settlement (Oracle)
    // ─────────────────────────────────────────────

    /**
     * @notice Settle a round with the closing price from Binance
     * @dev If one side is empty, round is cancelled and all bets are refunded via claimRefund
     */
    function settleRound(uint256 roundId, uint256 closePrice) external onlyOracle {
        Round storage r = rounds[roundId];
        require(r.closeTime > 0, "Round does not exist");
        require(block.timestamp >= r.closeTime, "Round not closed yet");
        require(!r.settled && !r.cancelled, "Already finalized");

        r.closePrice = closePrice;

        // If one side is empty OR prices are tied → cancel round, refund all
        if (r.upPool == 0 || r.downPool == 0 || closePrice == r.openPrice) {
            r.cancelled = true;
            emit RoundCancelled(roundId);
            return;
        }

        r.settled = true;
        bool upWon = closePrice > r.openPrice;  // tie already handled above
        emit RoundSettled(roundId, closePrice, upWon);
    }

    // ─────────────────────────────────────────────
    // Claim Winnings / Refund
    // ─────────────────────────────────────────────

    /**
     * @notice Claim winnings after a settled round
     * Zone-based fee: GREEN bettors pay 1% house fee, YELLOW/RED pay 3%
     * Fee is taken from each winner's proportional share of the losing pool
     */
    function claimWinnings(uint256 roundId) external nonReentrant {
        Round storage r = rounds[roundId];
        require(r.settled, "Round not settled");

        Bet storage b = bets[roundId][msg.sender];
        require(b.amount > 0, "No bet");
        require(!b.claimed, "Already claimed");

        bool upWon = r.closePrice > r.openPrice;
        require(b.isUp == upWon, "You lost this round");

        b.claimed = true;

        uint256 winPool  = upWon ? r.upPool  : r.downPool;
        uint256 losePool = upWon ? r.downPool : r.upPool;

        // Winner's raw share of losing pool (before fee)
        uint256 winnerLoseShare = (b.amount * losePool) / winPool;

        // Zone-based fee: GREEN (zone=0) → 1%, YELLOW/RED → 3%
        uint256 feeBps = (b.zone == 0) ? GREEN_FEE_BPS : HOUSE_FEE_BPS;
        uint256 houseFee = winnerLoseShare * feeBps / FEE_DENOM;
        accumulatedFees += houseFee;

        // Winner's payout = original bet + share of losing pool minus fee
        uint256 winnings = winnerLoseShare - houseFee;
        uint256 payout   = b.amount + winnings;

        // Credit internal balance
        balances[msg.sender] += payout;
        emit Claimed(roundId, msg.sender, payout);
    }

    /**
     * @notice Refund bet if round was cancelled (one-sided pool)
     */
    function claimRefund(uint256 roundId) external nonReentrant {
        Round storage r = rounds[roundId];
        require(r.cancelled, "Round not cancelled");

        Bet storage b = bets[roundId][msg.sender];
        require(b.amount > 0, "No bet");
        require(!b.claimed, "Already claimed");

        b.claimed = true;
        balances[msg.sender] += b.amount;
        emit Claimed(roundId, msg.sender, b.amount);
    }

    // ─────────────────────────────────────────────
    // View Functions
    // ─────────────────────────────────────────────

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getRound(uint256 roundId) external view returns (Round memory) {
        return rounds[roundId];
    }

    function getBet(uint256 roundId, address user) external view returns (Bet memory) {
        return bets[roundId][user];
    }

    /**
     * @notice Preview payout for a given bet (before placing)
     */
    function previewPayout(
        uint256 roundId,
        bool isUp,
        uint256 betAmount
    ) external view returns (uint256 estimatedPayout) {
        Round storage r = rounds[roundId];
        uint256 myPool   = isUp ? r.upPool + betAmount : r.downPool + betAmount;
        uint256 theirPool = isUp ? r.downPool : r.upPool;
        if (myPool == 0 || theirPool == 0) return betAmount; // no pool yet

        uint256 theirAfterFee = theirPool * (FEE_DENOM - HOUSE_FEE_BPS) / FEE_DENOM;
        uint256 winnings = (betAmount * theirAfterFee) / myPool;
        estimatedPayout = betAmount + winnings;
    }
}
