-- Seed 5 Test Users
-- Password: "123456"
-- This script requires the pgcrypto extension (standard in Supabase).

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT;
    v_password TEXT := '123456';
    v_encrypted_pw TEXT;
    i INTEGER;
BEGIN
    -- Pre-calculate hash for consistency/performance (or use crypt() in loop)
    v_encrypted_pw := crypt(v_password, gen_salt('bf'));

    FOR i IN 1..5 LOOP
        v_email := 'test' || i || '@mail.com';
        v_user_id := gen_random_uuid();

        -- 1. Insert into auth.users
        -- Check if exists first to avoid error spam or duplicate key if ID differs but email conflict
        IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = v_email) THEN
            INSERT INTO auth.users (
                instance_id,
                id,
                aud,
                role,
                email,
                encrypted_password,
                email_confirmed_at,
                recovery_sent_at,
                last_sign_in_at,
                raw_app_meta_data,
                raw_user_meta_data,
                created_at,
                updated_at,
                confirmation_token,
                email_change,
                email_change_token_new,
                recovery_token
            ) VALUES (
                '00000000-0000-0000-0000-000000000000',
                v_user_id,
                'authenticated',
                'authenticated',
                v_email,
                v_encrypted_pw,
                now(),
                now(),
                now(),
                '{"provider":"email","providers":["email"]}',
                '{}',
                now(),
                now(),
                '',
                '',
                '',
                ''
            );
            
            -- Profiles should be created by Trigger usually, but let's ensure it for seeding
            INSERT INTO public.profiles (id, email, username, points, streak)
            VALUES (v_user_id, v_email, 'User ' || i, 1000, 0)
            ON CONFLICT (id) DO NOTHING;
            
            RAISE NOTICE 'Created user: %', v_email;
        ELSE
            RAISE NOTICE 'User already exists: %', v_email;
        END IF;
    END LOOP;
END $$;
