
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

function decodeJWT(token: string) {
    try {
        const parts = token.split('.');
        if (parts.length !== 3) throw new Error('Invalid JWT format');
        const payload = parts[1];
        const decoded = Buffer.from(payload, 'base64').toString('utf-8');
        return JSON.parse(decoded);
    } catch (e) {
        return null;
    }
}

function analyzeKey() {
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;

    console.log("--- KEY ANALYSIS ---");
    if (!key) {
        console.error("No Key found");
        return;
    }

    const claims = decodeJWT(key);
    if (!claims) {
        console.error("FAIL: Key is not a valid JWT");
        return;
    }

    console.log("Role:", claims.role);
    console.log("Project Ref:", claims.ref);
    console.log("Exp:", new Date(claims.exp * 1000).toISOString());

    // Check match with URL
    const expectedRef = url?.split('//')[1].split('.')[0];
    console.log("Expected Ref (from URL):", expectedRef);

    if (claims.ref === expectedRef) {
        console.log("✅ Project Ref MATCHES.");
    } else {
        console.error("❌ Project Ref MISMATCH. Key belongs to a different project!");
    }

    if (claims.role !== 'service_role') {
        console.error("❌ Role MISMATCH. This is NOT a service_role key.");
    } else {
        console.log("✅ Role is service_role.");
    }
}

analyzeKey();
