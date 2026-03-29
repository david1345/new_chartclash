"use client";

import { ethers } from "ethers";
import ChartClashArtifact from "./ChartClash.abi.json";

const CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS!;
const USDT_ADDRESS = process.env.NEXT_PUBLIC_USDT_ADDRESS!;
const POLYGON_MAINNET_USDT = "0xc2132d05d31c914a87c6611c10748aeb04b58e8f";

type WalletChainConfig = {
    chainId: string;
    chainName: string;
    rpcUrls: string[];
    blockExplorerUrls: string[];
    nativeCurrency: {
        name: string;
        symbol: string;
        decimals: number;
    };
};

const CHAIN_CONFIGS: Record<string, WalletChainConfig> = {
    "31337": {
        chainId: "0x7A69",
        chainName: "Hardhat Local",
        rpcUrls: ["http://127.0.0.1:8545"],
        blockExplorerUrls: [],
        nativeCurrency: { name: "ETH", symbol: "ETH", decimals: 18 },
    },
    "80002": {
        chainId: "0x13882",
        chainName: "Polygon Amoy",
        rpcUrls: ["https://rpc-amoy.polygon.technology/"],
        blockExplorerUrls: ["https://amoy.polygonscan.com"],
        nativeCurrency: { name: "POL", symbol: "POL", decimals: 18 },
    },
    "137": {
        chainId: "0x89",
        chainName: "Polygon",
        rpcUrls: ["https://polygon-rpc.com"],
        blockExplorerUrls: ["https://polygonscan.com"],
        nativeCurrency: { name: "POL", symbol: "POL", decimals: 18 },
    },
};

function getDefaultChainId(): string {
    if (process.env.NEXT_PUBLIC_CHAIN_ID) {
        return process.env.NEXT_PUBLIC_CHAIN_ID;
    }

    if (USDT_ADDRESS?.toLowerCase() === POLYGON_MAINNET_USDT) {
        return "137";
    }

    return "80002";
}

function getChainConfig(): WalletChainConfig {
    return CHAIN_CONFIGS[getDefaultChainId()] ?? CHAIN_CONFIGS["80002"];
}

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

export async function ensureWalletChain(): Promise<void> {
    if (typeof window === "undefined" || !window.ethereum) {
        throw new Error("MetaMask not found. Please install MetaMask.");
    }

    const chainConfig = getChainConfig();

    try {
        await window.ethereum.request({
            method: "wallet_switchEthereumChain",
            params: [{ chainId: chainConfig.chainId }],
        });
    } catch (error: any) {
        if (error?.code !== 4902) {
            throw error;
        }

        await window.ethereum.request({
            method: "wallet_addEthereumChain",
            params: [chainConfig],
        });
    }
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
    await ensureWalletChain();
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
    await ensureWalletChain();
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
    await ensureWalletChain();
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
    await ensureWalletChain();
    const signer = await getSigner();
    return signer.getAddress();
}

export function getBlockExplorerTxUrl(txHash: string): string | null {
    const [baseUrl] = getChainConfig().blockExplorerUrls;
    if (!baseUrl) return null;
    return `${baseUrl}/tx/${txHash}`;
}
