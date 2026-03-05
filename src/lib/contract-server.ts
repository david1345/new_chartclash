/**
 * Server-side contract interaction using oracle private key.
 * Use this ONLY in API routes / cron jobs (never in client components).
 */

import { ethers } from "ethers";
import ChartClashArtifact from "./ChartClash.abi.json";

const CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS!;
const USDT_DECIMALS = 6;

function getOracleWallet(): ethers.Wallet {
    const rpcUrl = process.env.POLYGON_RPC_URL || "https://polygon-rpc.com";
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const privateKey = process.env.DEPLOYER_PRIVATE_KEY!;
    return new ethers.Wallet(privateKey, provider);
}

function getContract() {
    const wallet = getOracleWallet();
    return new ethers.Contract(CONTRACT_ADDRESS, ChartClashArtifact.abi, wallet);
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
    const event = receipt.logs
        .map((log: any) => { try { return contract.interface.parseLog(log); } catch { return null; } })
        .find((e: any) => e?.name === "RoundCreated");

    if (!event) throw new Error("RoundCreated event not found in tx receipt");
    return event.args.roundId.toString();
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
    const contract = getContract();
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
