import { expect } from "chai";
import { ethers } from "hardhat";
import { ChartClash } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("ChartClash", function () {
    let chartclash: ChartClash;
    let mockUSDT: any;
    let owner: SignerWithAddress;
    let oracle: SignerWithAddress;
    let alice: SignerWithAddress;
    let bob: SignerWithAddress;

    const USDT_DECIMALS = 6;
    const parseUSDT = (amount: number) => ethers.parseUnits(amount.toString(), USDT_DECIMALS);

    // helper: get latest block timestamp
    const now = async () => {
        const b = await ethers.provider.getBlock("latest");
        return b!.timestamp;
    };

    beforeEach(async () => {
        [owner, oracle, alice, bob] = await ethers.getSigners();

        const MockERC20 = await ethers.getContractFactory("MockERC20");
        mockUSDT = await MockERC20.deploy("Mock USDT", "USDT", 6);
        await mockUSDT.waitForDeployment();

        await mockUSDT.mint(alice.address, parseUSDT(1000));
        await mockUSDT.mint(bob.address, parseUSDT(1000));

        const ChartClash = await ethers.getContractFactory("ChartClash");
        chartclash = await ChartClash.deploy(
            await mockUSDT.getAddress(), oracle.address
        ) as unknown as ChartClash;
        await chartclash.waitForDeployment();

        await mockUSDT.connect(alice).approve(await chartclash.getAddress(), parseUSDT(1000));
        await mockUSDT.connect(bob).approve(await chartclash.getAddress(), parseUSDT(1000));
    });

    // ─────────────────── Deposit ───────────────────
    describe("deposit", () => {
        it("credits internal balance", async () => {
            await chartclash.connect(alice).deposit(parseUSDT(100));
            expect(await chartclash.getBalance(alice.address)).to.equal(parseUSDT(100));
        });

        it("transfers USDT to contract", async () => {
            await chartclash.connect(alice).deposit(parseUSDT(100));
            expect(await mockUSDT.balanceOf(await chartclash.getAddress())).to.equal(parseUSDT(100));
        });

        it("reverts on zero", async () => {
            await expect(chartclash.connect(alice).deposit(0)).to.be.revertedWith("Zero amount");
        });
    });

    // ─────────────────── Withdraw ──────────────────
    describe("withdraw", () => {
        beforeEach(async () => {
            await chartclash.connect(alice).deposit(parseUSDT(100));
        });

        it("withdraws minus 1% fee", async () => {
            const before = await mockUSDT.balanceOf(alice.address);
            await chartclash.connect(alice).withdraw(parseUSDT(100));
            const after = await mockUSDT.balanceOf(alice.address);
            expect(after - before).to.equal(parseUSDT(99));
        });

        it("reverts if insufficient balance", async () => {
            await expect(chartclash.connect(alice).withdraw(parseUSDT(200)))
                .to.be.revertedWith("Insufficient balance");
        });
    });

    // ─────────────────── Betting ───────────────────
    describe("placeBet", () => {
        let roundId: bigint;

        beforeEach(async () => {
            await chartclash.connect(alice).deposit(parseUSDT(200));
            await chartclash.connect(bob).deposit(parseUSDT(200));

            const closeTime = (await now()) + 3600;
            await chartclash.connect(oracle).createRound("BTCUSDT", "1h", parseUSDT(50000), closeTime);
            roundId = 1n;
        });

        it("deducts from balance and adds to pool", async () => {
            await chartclash.connect(alice).placeBet(roundId, true, parseUSDT(100));
            expect(await chartclash.getBalance(alice.address)).to.equal(parseUSDT(100));
            const round = await chartclash.getRound(roundId);
            expect(round.upPool).to.equal(parseUSDT(100));
        });

        it("reverts on double bet", async () => {
            await chartclash.connect(alice).placeBet(roundId, true, parseUSDT(50));
            await expect(chartclash.connect(alice).placeBet(roundId, false, parseUSDT(50)))
                .to.be.revertedWith("Already bet this round");
        });

        it("reverts on insufficient balance", async () => {
            await expect(chartclash.connect(alice).placeBet(roundId, true, parseUSDT(500)))
                .to.be.revertedWith("Insufficient balance");
        });
    });

    // ─────────────────── Settlement ────────────────
    describe("settleRound + claimWinnings", () => {
        let roundId: bigint;

        beforeEach(async () => {
            await chartclash.connect(alice).deposit(parseUSDT(200));
            await chartclash.connect(bob).deposit(parseUSDT(200));

            // Use block timestamp for reliable timing
            const closeTime = (await now()) + 100;
            await chartclash.connect(oracle).createRound("BTCUSDT", "1h", parseUSDT(50000), closeTime);
            roundId = 1n;

            await chartclash.connect(alice).placeBet(roundId, true, parseUSDT(100)); // UP
            await chartclash.connect(bob).placeBet(roundId, false, parseUSDT(100)); // DOWN

            // Fast-forward past closeTime
            await ethers.provider.send("evm_increaseTime", [110]);
            await ethers.provider.send("evm_mine", []);
        });

        it("settles round and allows winner to claim", async () => {
            await chartclash.connect(oracle).settleRound(roundId, parseUSDT(50001));
            const round = await chartclash.getRound(roundId);
            expect(round.settled).to.be.true;

            await chartclash.connect(alice).claimWinnings(roundId);
            const aliceBal = await chartclash.getBalance(alice.address);
            // 100 original + ~97% of 100 from bob
            expect(aliceBal).to.be.gt(parseUSDT(190));
        });

        it("loser cannot claim", async () => {
            await chartclash.connect(oracle).settleRound(roundId, parseUSDT(50001));
            await expect(chartclash.connect(bob).claimWinnings(roundId))
                .to.be.revertedWith("You lost this round");
        });

        it("prevents double claim", async () => {
            await chartclash.connect(oracle).settleRound(roundId, parseUSDT(50001));
            await chartclash.connect(alice).claimWinnings(roundId);
            await expect(chartclash.connect(alice).claimWinnings(roundId))
                .to.be.revertedWith("Already claimed");
        });
    });

    // ─────────────────── Cancelled Round ───────────────────
    describe("cancelled round (one-sided pool)", () => {
        it("refunds bet when pool is one-sided", async () => {
            await chartclash.connect(alice).deposit(parseUSDT(100));
            const closeTime = (await now()) + 100;
            await chartclash.connect(oracle).createRound("BTCUSDT", "1h", parseUSDT(50000), closeTime);

            await chartclash.connect(alice).placeBet(1n, true, parseUSDT(100)); // only UP

            await ethers.provider.send("evm_increaseTime", [110]);
            await ethers.provider.send("evm_mine", []);

            await chartclash.connect(oracle).settleRound(1n, parseUSDT(50001));
            const round = await chartclash.getRound(1n);
            expect(round.cancelled).to.be.true;

            await chartclash.connect(alice).claimRefund(1n);
            expect(await chartclash.getBalance(alice.address)).to.equal(parseUSDT(100));
        });
    });

    // ─────────────────── Access Control ────────────────────
    describe("access control", () => {
        it("non-oracle cannot createRound", async () => {
            const closeTime = (await now()) + 3600;
            await expect(
                chartclash.connect(alice).createRound("BTCUSDT", "1h", parseUSDT(50000), closeTime)
            ).to.be.revertedWith("ChartClash: caller is not oracle");
        });

        it("non-oracle cannot settleRound", async () => {
            const closeTime = (await now()) + 100;
            await chartclash.connect(oracle).createRound("BTCUSDT", "1h", parseUSDT(50000), closeTime);
            await ethers.provider.send("evm_increaseTime", [110]);
            await ethers.provider.send("evm_mine", []);
            await expect(
                chartclash.connect(alice).settleRound(1n, parseUSDT(50001))
            ).to.be.revertedWith("ChartClash: caller is not oracle");
        });

        it("non-owner cannot pause", async () => {
            await expect(chartclash.connect(alice).pause())
                .to.be.revertedWithCustomError(chartclash, "OwnableUnauthorizedAccount");
        });
    });

    // ─────────────────── Edge Cases ────────────────────────
    describe("edge cases", () => {

        it("cannot settle before closeTime", async () => {
            await chartclash.connect(alice).deposit(parseUSDT(100));
            const closeTime = (await now()) + 3600; // 1h from now, NOT elapsed
            await chartclash.connect(oracle).createRound("BTCUSDT", "1h", parseUSDT(50000), closeTime);
            await expect(
                chartclash.connect(oracle).settleRound(1n, parseUSDT(50001))
            ).to.be.revertedWith("Round not closed yet");
        });

        it("cannot bet after round is settled", async () => {
            await chartclash.connect(alice).deposit(parseUSDT(200));
            await chartclash.connect(bob).deposit(parseUSDT(200));
            const closeTime = (await now()) + 100;
            await chartclash.connect(oracle).createRound("BTCUSDT", "1h", parseUSDT(50000), closeTime);
            await chartclash.connect(alice).placeBet(1n, true, parseUSDT(100));
            await chartclash.connect(bob).placeBet(1n, false, parseUSDT(100));
            await ethers.provider.send("evm_increaseTime", [110]);
            await ethers.provider.send("evm_mine", []);
            await chartclash.connect(oracle).settleRound(1n, parseUSDT(50001));
            // Alice tries to bet after settlement
            await expect(
                chartclash.connect(alice).placeBet(1n, true, parseUSDT(50))
            ).to.be.revertedWith("Round is closed");
        });

        it("withdraw zero reverts", async () => {
            await chartclash.connect(alice).deposit(parseUSDT(100));
            await expect(chartclash.connect(alice).withdraw(0))
                .to.be.revertedWith("Zero amount");
        });

        it("skewed pool 99:1 — loser gets nothing, winner gets correct payout", async () => {
            // Alice bets 990 UP, Bob bets 10 DOWN
            await chartclash.connect(alice).deposit(parseUSDT(1000));
            await chartclash.connect(bob).deposit(parseUSDT(1000));
            const closeTime = (await now()) + 100;
            await chartclash.connect(oracle).createRound("BTCUSDT", "1h", parseUSDT(50000), closeTime);
            await chartclash.connect(alice).placeBet(1n, true, parseUSDT(990));  // UP
            await chartclash.connect(bob).placeBet(1n, false, parseUSDT(10));   // DOWN
            await ethers.provider.send("evm_increaseTime", [110]);
            await ethers.provider.send("evm_mine", []);
            // UP wins
            await chartclash.connect(oracle).settleRound(1n, parseUSDT(50001));
            await chartclash.connect(alice).claimWinnings(1n);
            const aliceBal = await chartclash.getBalance(alice.address);
            // Alice had 1000, bet 990 → 10 remaining. Wins 97% of bob's 10 = 9.7
            // Total: 10 + 990 (returned) + 9.7 = 1009.7 USDT
            expect(aliceBal).to.be.gt(parseUSDT(1009));
            expect(aliceBal).to.be.lt(parseUSDT(1010));
            // Bob lost — cannot claim winnings
            await expect(chartclash.connect(bob).claimWinnings(1n))
                .to.be.revertedWith("You lost this round");
        });

        it("oracle address change blocks old oracle", async () => {
            const [, , , , , newOracle] = await ethers.getSigners();
            await chartclash.connect(owner).setOracle(newOracle.address);
            const closeTime = (await now()) + 100;
            // Old oracle can no longer create rounds
            await expect(
                chartclash.connect(oracle).createRound("BTCUSDT", "1h", parseUSDT(50000), closeTime)
            ).to.be.revertedWith("ChartClash: caller is not oracle");
            // New oracle can
            await chartclash.connect(newOracle).createRound("BTCUSDT", "1h", parseUSDT(50000), closeTime);
        });

        it("emergency withdraw-for works when paused", async () => {
            await chartclash.connect(alice).deposit(parseUSDT(100));
            await chartclash.connect(owner).pause();
            const before = await mockUSDT.balanceOf(alice.address);
            await chartclash.connect(owner).emergencyWithdrawFor([alice.address]);
            const after = await mockUSDT.balanceOf(alice.address);
            expect(after - before).to.equal(parseUSDT(100));
        });

        it("cannot deposit or bet while paused", async () => {
            await chartclash.connect(owner).pause();
            await expect(chartclash.connect(alice).deposit(parseUSDT(10)))
                .to.be.revertedWithCustomError(chartclash, "EnforcedPause");
        });

        it("previewPayout returns correct estimate", async () => {
            await chartclash.connect(alice).deposit(parseUSDT(200));
            await chartclash.connect(bob).deposit(parseUSDT(200));
            const closeTime = (await now()) + 100;
            await chartclash.connect(oracle).createRound("BTCUSDT", "1h", parseUSDT(50000), closeTime);
            await chartclash.connect(alice).placeBet(1n, true, parseUSDT(100));
            await chartclash.connect(bob).placeBet(1n, false, parseUSDT(100));
            // Preview for UP bet of 50 more
            const preview = await chartclash.previewPayout(1n, true, parseUSDT(50));
            // upPool would be 150, downPool 100, after 3% fee: 50 + (50/150 * 97) ≈ 82.3
            expect(preview).to.be.gt(parseUSDT(80));
            expect(preview).to.be.lt(parseUSDT(90));
        });
    });

    // ─────────────────── collectFees Security ──────────────────
    describe("collectFees vulnerability (fixed)", () => {
        it("owner CANNOT drain user deposits via collectFees", async () => {
            // Alice deposits 100 USDT
            await chartclash.connect(alice).deposit(parseUSDT(100));

            // Owner tries to collect more than accumulated fees → must revert
            // Before fix: this would succeed. After fix: reverts with "No fees to collect"
            await expect(
                (chartclash.connect(owner) as any).collectFees()
            ).to.be.revertedWith("No fees to collect");

            // Alice's balance is still intact
            expect(await chartclash.getBalance(alice.address)).to.equal(parseUSDT(100));
        });

        it("owner CAN collect only actual accumulated fees", async () => {
            // Generate withdraw fee: Alice deposits 100, withdraws 100 → 1 USDT fee stays in contract
            await chartclash.connect(alice).deposit(parseUSDT(100));
            await chartclash.connect(alice).withdraw(parseUSDT(100));

            const accumulated = await chartclash.accumulatedFees();
            expect(accumulated).to.equal(parseUSDT(1)); // 1% of 100

            const ownerBefore = await mockUSDT.balanceOf(owner.address);
            await (chartclash.connect(owner) as any).collectFees();
            const ownerAfter = await mockUSDT.balanceOf(owner.address);

            expect(ownerAfter - ownerBefore).to.equal(parseUSDT(1));
            expect(await chartclash.accumulatedFees()).to.equal(0);
        });

        it("house fee from winning round accumulates correctly", async () => {
            await chartclash.connect(alice).deposit(parseUSDT(200));
            await chartclash.connect(bob).deposit(parseUSDT(200));
            const closeTime = (await now()) + 100;
            await chartclash.connect(oracle).createRound("BTCUSDT", "1h", parseUSDT(50000), closeTime);
            await chartclash.connect(alice).placeBet(1n, true, parseUSDT(100));
            await chartclash.connect(bob).placeBet(1n, false, parseUSDT(100));
            await ethers.provider.send("evm_increaseTime", [110]);
            await ethers.provider.send("evm_mine", []);
            await chartclash.connect(oracle).settleRound(1n, parseUSDT(50001)); // UP wins
            await chartclash.connect(alice).claimWinnings(1n);

            // House fee = 3% of 100 (losing pool) = 3 USDT
            const fees = await chartclash.accumulatedFees();
            expect(fees).to.equal(parseUSDT(3));
        });
    });
});
