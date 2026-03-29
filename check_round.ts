
import { getRoundOnChain } from './src/lib/contract-server';
import * as dotenv from 'dotenv';
dotenv.config({ path: '.env.development' });

async function main() {
    try {
        const round = await getRoundOnChain("7");
        console.log("Round 7 Data:", JSON.stringify(round, (key, value) =>
            typeof value === 'bigint' ? value.toString() : value, 2));
    } catch (e: any) {
        console.error("Error fetching round 7:", e.message);
    }
}

main();
