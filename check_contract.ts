
import { ethers } from "ethers";
import ChartClashArtifact from "./src/lib/ChartClash.abi.json";
import * as dotenv from 'dotenv';
dotenv.config({ path: '/Users/kimdonghyouk/project3/new_chartclash/.env.development' });

const CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS!;
const RPC_URL = process.env.POLYGON_RPC_URL!;

async function main() {
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const contract = new ethers.Contract(CONTRACT_ADDRESS, ChartClashArtifact.abi, provider);

    try {
        const nextId = await contract.nextRoundId();
        console.log("Next Round ID:", nextId.toString());

        const round = await contract.getRound(7n);
        console.log("Round 7 Data:", JSON.stringify(round, (key, value) =>
            typeof value === 'bigint' ? value.toString() : value, 2));
    } catch (e: any) {
        console.error("Error:", e.message);
    }
}

main();
