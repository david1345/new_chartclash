async function testCC() {
    const toTs = Math.floor(Date.now() / 1000); // Now (which is 2026-02-20)

    // Test PAXG
    const urlPAXG = `https://min-api.cryptocompare.com/data/v2/histominute?fsym=PAXG&tsym=USD&limit=1&toTs=${toTs}`;
    const resPAXG = await fetch(urlPAXG);
    const dataPAXG = await resPAXG.json();
    if (dataPAXG.Data?.Data?.[0]) {
        console.log(`[CryptoCompare PAXG History] Price: ${dataPAXG.Data.Data[0].close}`);
    }

    // Test XAU
    const urlXAU = `https://min-api.cryptocompare.com/data/v2/histominute?fsym=XAU&tsym=USD&limit=1&toTs=${toTs}`;
    const resXAU = await fetch(urlXAU);
    const dataXAU = await resXAU.json();
    if (dataXAU.Data?.Data?.[0]) {
        console.log(`[CryptoCompare XAU History] Price: ${dataXAU.Data.Data[0].close}`);
    }
}

testCC();
