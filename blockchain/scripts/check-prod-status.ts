import { ethers, network } from "hardhat";
import * as dotenv from "dotenv";
dotenv.config({ path: "../.env.development" });

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("-----------------------------------------");
    console.log("Checking Production Status");
    console.log("Deployer Address:", deployer.address);
    console.log("Network:", network.name);
    
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("MATIC Balance:", ethers.formatEther(balance), "MATIC");

    const usdtAddress = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F";
    const usdt = await ethers.getContractAt([
        "function balanceOf(address) view returns (uint256)",
        "function decimals() view returns (uint8)",
        "function symbol() view returns (string)"
    ], usdtAddress);

    try {
        const symbol = await usdt.symbol();
        const decimals = await usdt.decimals();
        const usdtBal = await usdt.balanceOf(deployer.address);
        console.log(`${symbol} Balance:`, ethers.formatUnits(usdtBal, decimals), symbol);
    } catch (e) {
        console.log("Could not fetch USDT balance (maybe wrong network or RPC issue)");
    }
    console.log("-----------------------------------------");
}

main().catch(console.error);
