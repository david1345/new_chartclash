import { ethers, network } from "hardhat";

function cleanAddress(addr: string): string {
    // Remove accidental double 0x (e.g. 0x0x14D0b...)
    return addr.startsWith("0x0x") ? "0x" + addr.slice(4) : addr;
}

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying with:", deployer.address);
    console.log("Network:", network.name);
    const bal = await ethers.provider.getBalance(deployer.address);
    console.log("Balance:", ethers.formatEther(bal), "MATIC\n");

    // ── USDT Address ────────────────────────────────────────
    let usdtAddress: string;

    if (network.name === "polygon") {
        // Polygon mainnet: official Tether USDT
        usdtAddress = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F";
        console.log("Using mainnet USDT:", usdtAddress);
    } else {
        // Testnet (amoy / hardhat): deploy MockERC20
        console.log("Testnet: deploying MockERC20 (mock USDT)...");
        const MockERC20 = await ethers.getContractFactory("MockERC20");
        const mockUSDT = await MockERC20.deploy("Mock USDT", "USDT", 6);
        await mockUSDT.waitForDeployment();
        usdtAddress = await mockUSDT.getAddress();
        console.log("Mock USDT deployed to:", usdtAddress);

        // Mint 10,000 USDT to deployer for testing
        const mintAmount = ethers.parseUnits("10000", 6);
        await (mockUSDT as any).mint(deployer.address, mintAmount);
        console.log("Minted 10,000 test USDT to deployer\n");
    }

    // ── Oracle Address ───────────────────────────────────────
    const rawOracle = process.env.ORACLE_WALLET_ADDRESS || deployer.address;
    const oracleAddress = cleanAddress(rawOracle);
    console.log("Oracle:", oracleAddress);

    // ── Deploy ChartClash ────────────────────────────────────
    console.log("\nDeploying ChartClash...");
    const ChartClash = await ethers.getContractFactory("ChartClash");
    const chartclash = await ChartClash.deploy(usdtAddress, oracleAddress);
    await chartclash.waitForDeployment();

    const contractAddress = await chartclash.getAddress();
    console.log("✅ ChartClash deployed to:", contractAddress);

    console.log("\n─────────────────────────────────");
    console.log("Add these to .env.development:");
    console.log(`NEXT_PUBLIC_CONTRACT_ADDRESS=${contractAddress}`);
    console.log(`NEXT_PUBLIC_USDT_ADDRESS=${usdtAddress}`);
    console.log("─────────────────────────────────");
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});
