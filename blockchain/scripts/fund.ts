import { ethers } from "hardhat";

async function main() {
    const TARGET = "0x14D0b7413E0c9d780Bd183A2E450216332CF75Ea";
    const USDT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

    const [deployer] = await ethers.getSigners();

    // Send 10 ETH for gas
    await deployer.sendTransaction({
        to: TARGET,
        value: ethers.parseEther("10")
    });
    console.log("✅ Sent 10 ETH to", TARGET);

    // Mint 10,000 MockUSDT
    const usdt = await ethers.getContractAt("MockERC20", USDT_ADDRESS);
    await usdt.mint(TARGET, ethers.parseUnits("10000", 6));
    console.log("✅ Minted 10,000 MockUSDT to", TARGET);
}

main().catch(console.error);
