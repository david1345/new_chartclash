import { ethers } from "hardhat";

async function main() {
    const CONTRACT = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
    const USDT = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
    const USER = "0x14D0b7413E0c9d780Bd183A2E450216332CF75Ea";
    const DEPLOYER = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

    const chartclash = await ethers.getContractAt("ChartClash", CONTRACT);
    const usdt = await ethers.getContractAt("MockERC20", USDT);

    const userContractBal = await chartclash.getBalance(USER);
    const deployerContractBal = await chartclash.getBalance(DEPLOYER);
    const userUSDT = await usdt.balanceOf(USER);

    console.log("User contract balance   :", ethers.formatUnits(userContractBal, 6), "USDT");
    console.log("Deployer contract balance:", ethers.formatUnits(deployerContractBal, 6), "USDT");
    console.log("User wallet USDT        :", ethers.formatUnits(userUSDT, 6), "USDT");
}

main().catch(console.error);
