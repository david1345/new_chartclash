/**
 * Server-side contract interaction using oracle private key.
 * Use this ONLY in API routes / cron jobs (never in client components).
 */

import { ethers } from "ethers";
import ChartClashArtifact from "./ChartClash.abi.json";

const CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS!;
const USDT_DECIMALS = 6;

function getProvider() {
    const rpcUrl = process.env.POLYGON_RPC_URL || "https://polygon-rpc.com";
    return new ethers.JsonRpcProvider(rpcUrl);
}

function getOracleWallet(): ethers.Wallet {
    const provider = getProvider();
    const privateKey = process.env.DEPLOYER_PRIVATE_KEY!;
    return new ethers.Wallet(privateKey, provider);
}

function getContract() {
    const wallet = getOracleWallet();
    return new ethers.Contract(CONTRACT_ADDRESS, ChartClashArtifact.abi, wallet);
}

function getReadContract() {
    return new ethers.Contract(CONTRACT_ADDRESS, ChartClashArtifact.abi, getProvider());
}

/**
 * Create a round on-chain. Called by cron at candle open.
 * @returns on-chain roundId (BigInt → string)
 */
export async function createRoundOnChain(
    asset: string,
    timeframe: string,
    openPriceUSD: number,
    closeTimeUnix: number   // seconds
): Promise<string> {
    const contract = getContract();
    const openPriceScaled = ethers.parseUnits(openPriceUSD.toFixed(6), USDT_DECIMALS);
    const tx = await contract.createRound(asset, timeframe, openPriceScaled, closeTimeUnix);
    const receipt = await tx.wait();

    // Parse RoundCreated event to get roundId
    for (const log of receipt.logs) {
        try {
            const parsed = contract.interface.parseLog(log);
            if (parsed && parsed.name === "RoundCreated") {
                return parsed.args.roundId.toString();
            }
        } catch (e) {
            // Not our event or parsing failed, skip
        }
    }

    throw new Error("RoundCreated event not found in tx receipt logs");
}

/**
 * Settle a round on-chain with the closing price. Called by cron after candle closes.
 */
export async function settleRoundOnChain(
    onChainRoundId: string,
    closePriceUSD: number
): Promise<string> {
    const contract = getContract();
    const closePriceScaled = ethers.parseUnits(closePriceUSD.toFixed(6), USDT_DECIMALS);
    const tx = await contract.settleRound(BigInt(onChainRoundId), closePriceScaled);
    const receipt = await tx.wait();
    return receipt.hash;
}

/**
 * Get round data from chain.
 */
export async function getRoundOnChain(onChainRoundId: string) {
    const contract = getReadContract();
    const round = await contract.getRound(BigInt(onChainRoundId));
    return {
        asset: round.asset,
        timeframe: round.timeframe,
        openPrice: parseFloat(ethers.formatUnits(round.openPrice, USDT_DECIMALS)),
        closePrice: parseFloat(ethers.formatUnits(round.closePrice, USDT_DECIMALS)),
        upPool: parseFloat(ethers.formatUnits(round.upPool, USDT_DECIMALS)),
        downPool: parseFloat(ethers.formatUnits(round.downPool, USDT_DECIMALS)),
        settled: round.settled,
        cancelled: round.cancelled,
    };
}

export async function getBetOnChain(onChainRoundId: string, userAddress: string) {
    const contract = getReadContract();
    const bet = await contract.getBet(BigInt(onChainRoundId), userAddress);

    return {
        amount: parseFloat(ethers.formatUnits(bet.amount, USDT_DECIMALS)),
        isUp: Boolean(bet.isUp),
        claimed: Boolean(bet.claimed),
        zone: Number(bet.zone),
    };
}

export async function getWalletAddressFromTransaction(txHash: string) {
    const tx = await getProvider().getTransaction(txHash);

    if (!tx?.from) {
        throw new Error(`Transaction not found: ${txHash}`);
    }

    return tx.from;
}
