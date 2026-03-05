import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config({ path: "../.env.development" });

const PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY || "0x" + "0".repeat(64);
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY || "";

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.20",
        settings: {
            optimizer: { enabled: true, runs: 200 },
        },
    },
    networks: {
        // Local testnet
        hardhat: {},
        // Polygon Amoy testnet
        amoy: {
            url: "https://rpc-amoy.polygon.technology/",
            accounts: [PRIVATE_KEY],
            chainId: 80002,
        },
        // Polygon Mainnet
        polygon: {
            url: process.env.POLYGON_RPC_URL || "https://polygon-rpc.com",
            accounts: [PRIVATE_KEY],
            chainId: 137,
        },
    },
    etherscan: {
        apiKey: {
            polygon: POLYGONSCAN_API_KEY,
            polygonAmoy: POLYGONSCAN_API_KEY,
        },
    },
};

export default config;
