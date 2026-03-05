"use client";

import { ethers } from "ethers";
import ChartClashArtifact from "./ChartClash.abi.json";

const CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS!;
const USDT_ADDRESS = process.env.NEXT_PUBLIC_USDT_ADDRESS!;

// Minimal ERC20 ABI for approve/balanceOf
const ERC20_ABI = [
    "function approve(address spender, uint256 amount) returns (bool)",
    "function allowance(address owner, address spender) view returns (uint256)",
    "function balanceOf(address account) view returns (uint256)",
    "function decimals() view returns (uint8)",
];

export function getProvider(): ethers.BrowserProvider {
    if (typeof window === "undefined" || !window.ethereum) {
        throw new Error("MetaMask not found. Please install MetaMask.");
    }
    return new ethers.BrowserProvider(window.ethereum);
}

export async function getSigner(): Promise<ethers.JsonRpcSigner> {
    const provider = getProvider();
    await provider.send("eth_requestAccounts", []);
    return provider.getSigner();
}

export async function getChartClashContract(withSigner = false) {
    if (withSigner) {
        const signer = await getSigner();
        return new ethers.Contract(CONTRACT_ADDRESS, ChartClashArtifact.abi, signer);
    }
    const provider = getProvider();
    return new ethers.Contract(CONTRACT_ADDRESS, ChartClashArtifact.abi, provider);
}

export async function getUSDTContract(withSigner = false) {
    if (withSigner) {
        const signer = await getSigner();
        return new ethers.Contract(USDT_ADDRESS, ERC20_ABI, signer);
    }
    const provider = getProvider();
    return new ethers.Contract(USDT_ADDRESS, ERC20_ABI, provider);
}

/**
 * Deposit USDT into ChartClash contract
 * 1. approve USDT spend
 * 2. call deposit()
 */
export async function depositUSDT(amountUSDT: number): Promise<string> {
    const signer = await getSigner();
    const amount = ethers.parseUnits(amountUSDT.toString(), 6); // USDT = 6 decimals

    const usdt = new ethers.Contract(USDT_ADDRESS, ERC20_ABI, signer);
    const chartclash = new ethers.Contract(CONTRACT_ADDRESS, ChartClashArtifact.abi, signer);

    // Check allowance first
    const allowance = await usdt.allowance(await signer.getAddress(), CONTRACT_ADDRESS);
    if (allowance < amount) {
        const approveTx = await usdt.approve(CONTRACT_ADDRESS, amount);
        await approveTx.wait();
    }

    const tx = await chartclash.deposit(amount);
    await tx.wait();
    return tx.hash;
}

/**
 * Withdraw USDT from ChartClash contract
 */
export async function withdrawUSDT(amountUSDT: number): Promise<string> {
    const signer = await getSigner();
    const amount = ethers.parseUnits(amountUSDT.toString(), 6);
    const chartclash = new ethers.Contract(CONTRACT_ADDRESS, ChartClashArtifact.abi, signer);
    const tx = await chartclash.withdraw(amount);
    await tx.wait();
    return tx.hash;
}

/**
 * Get user's internal contract balance in USDT
 */
export async function getContractBalance(address: string): Promise<number> {
    const chartclash = await getChartClashContract(false);
    const raw = await chartclash.getBalance(address);
    return parseFloat(ethers.formatUnits(raw, 6));
}

/**
 * Place a bet on-chain using internal contract balance (via MetaMask)
 */
export async function placeBetOnChain(
    onChainRoundId: string,
    isUp: boolean,
    amountUSDT: number
): Promise<string> {
    const signer = await getSigner();
    const chartclash = new ethers.Contract(CONTRACT_ADDRESS, ChartClashArtifact.abi, signer);
    const amount = ethers.parseUnits(amountUSDT.toString(), 6);
    const tx = await chartclash.placeBet(BigInt(onChainRoundId), isUp, amount);
    await tx.wait();
    return tx.hash;
}

/**
 * Connect wallet and return address
 */
export async function connectWallet(): Promise<string> {
    const signer = await getSigner();
    return signer.getAddress();
}
