import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';

dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function migrate() {
    console.log('🚀 Starting Data Migration to New Supabase...');

    // 1. Load Data
    const users = JSON.parse(fs.readFileSync('migrate_users.json', 'utf8'));
    const profiles = JSON.parse(fs.readFileSync('migrate_profiles.json', 'utf8'));
    const predictions = JSON.parse(fs.readFileSync('migrate_predictions.json', 'utf8'));

    console.log(`- Users to migrate: ${users.length}`);
    console.log(`- Profiles to migrate: ${profiles.length}`);
    console.log(`- Predictions to migrate: ${predictions.length}`);

    // [Step 1] Migrate auth.users
    // We'll use a SQL RPC to insert directly into auth.users to preserve IDs and Passwords
    const sqlUsers = `
    CREATE OR REPLACE FUNCTION public.migrate_auth_users(p_users jsonb)
    RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
    DECLARE
        u jsonb;
    BEGIN
        FOR u IN SELECT * FROM jsonb_array_elements(p_users) LOOP
            INSERT INTO auth.users (
                id, instance_id, aud, role, email, encrypted_password, 
                email_confirmed_at, raw_app_meta_data, raw_user_meta_data, 
                created_at, updated_at, last_sign_in_at, is_super_admin, is_anonymous
            ) VALUES (
                (u->>'id')::uuid, (u->>'instance_id')::uuid, u->>'aud', u->>'role', u->>'email', u->>'encrypted_password',
                (u->>'email_confirmed_at')::timestamptz, (u->>'raw_app_meta_data')::jsonb, (u->>'raw_user_meta_data')::jsonb,
                (u->>'created_at')::timestamptz, (u->>'updated_at')::timestamptz, (u->>'last_sign_in_at')::timestamptz,
                (u->>'is_super_admin')::boolean, (u->>'is_anonymous')::boolean
            ) ON CONFLICT (id) DO NOTHING;
        END LOOP;
    END;
    $$;
    `;

    console.log('Inserting auth.users...');
    await supabase.rpc('migrate_auth_users', { p_users: users });
    // If RPC doesn't exist yet, we might need to apply it via SQL Editor or a trick.
    // For now, let's assume we can apply this SQL via a separate step or try to run it.
    // Actually, I'll use a direct PostgreSQL connection if possible, or just use the Admin API.
    // Given limitations, let's try the Admin API for Users but we lose passwords.
    // WAIT! I have the production_final_sync.sql idea. I can just append the inserts to it!
}

// Re-thinking: The fastest way is to generate SQL INSERT statements and provide them to the user.
// Because I can't easily run SQL as superuser via the JS SDK.

async function generateSql() {
    const users = JSON.parse(fs.readFileSync('migrate_users.json', 'utf8'));
    const profiles = JSON.parse(fs.readFileSync('migrate_profiles.json', 'utf8'));
    const predictions = JSON.parse(fs.readFileSync('migrate_predictions.json', 'utf8'));

    // Try to load notifications and activity_logs if they were exported
    const notifications = fs.existsSync('migrate_notifications.json') ? JSON.parse(fs.readFileSync('migrate_notifications.json', 'utf8')) : [];
    const activityLogs = fs.existsSync('migrate_activity_logs.json') ? JSON.parse(fs.readFileSync('migrate_activity_logs.json', 'utf8')) : [];

    // [1] auth.users SQL (Sensitive)
    let authSql = '-- [AUTH.USERS MIGRATION]\n';
    authSql += '-- NOTE: Run this with high privileges (e.g. Supabase Support or custom wrapper)\n';
    for (const u of users) {
        const cols = Object.keys(u).join(', ');
        const vals = Object.values(u).map(v => v === null ? 'NULL' : `'${String(v).replace(/'/g, "''")}'`).join(', ');
        authSql += `INSERT INTO auth.users (${cols}) VALUES (${vals}) ON CONFLICT (id) DO NOTHING;\n`;
    }
    fs.writeFileSync('migrate_auth_users.sql', authSql);

    // [2] public schema SQL
    let publicSql = '-- [PUBLIC DATA MIGRATION]\n\n';

    publicSql += '-- Profiles\n';
    for (const p of profiles) {
        const cols = Object.keys(p).join(', ');
        const vals = Object.values(p).map(v => v === null ? 'NULL' : `'${String(v).replace(/'/g, "''")}'`).join(', ');
        publicSql += `INSERT INTO public.profiles (${cols}) VALUES (${vals}) ON CONFLICT (id) DO NOTHING;\n`;
    }

    publicSql += '\n-- Predictions\n';
    for (const p of predictions) {
        const cols = Object.keys(p).join(', ');
        const vals = Object.values(p).map(v => v === null ? 'NULL' : `'${String(v).replace(/'/g, "''")}'`).join(', ');
        publicSql += `INSERT INTO public.predictions (${cols}) VALUES (${vals}) ON CONFLICT (id) DO NOTHING;\n`;
    }

    if (notifications.length > 0) {
        publicSql += '\n-- Notifications\n';
        for (const n of notifications) {
            // Handle column naming conflict: prefer is_read over read
            const filteredN = { ...n };
            if ('read' in filteredN && 'is_read' in filteredN) {
                delete (filteredN as any).read;
            } else if ('read' in filteredN && !('is_read' in filteredN)) {
                (filteredN as any).is_read = filteredN.read;
                delete (filteredN as any).read;
            }

            const cols = Object.keys(filteredN).join(', ');
            const vals = Object.values(filteredN).map(v => v === null ? 'NULL' : `'${String(v).replace(/'/g, "''")}'`).join(', ');
            publicSql += `INSERT INTO public.notifications (${cols}) VALUES (${vals}) ON CONFLICT (id) DO NOTHING;\n`;
        }
    }

    if (activityLogs.length > 0) {
        publicSql += '\n-- Activity Logs\n';
        for (const a of activityLogs) {
            const cols = Object.keys(a).join(', ');
            const vals = Object.values(a).map(v => v === null ? 'NULL' : `'${String(v).replace(/'/g, "''")}'`).join(', ');
            publicSql += `INSERT INTO public.activity_logs (${cols}) VALUES (${vals}) ON CONFLICT (id) DO NOTHING;\n`;
        }
    }

    fs.writeFileSync('migrate_public_data.sql', publicSql);
    console.log('Generated migrate_auth_users.sql and migrate_public_data.sql (including history)');
}

generateSql();
