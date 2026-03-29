import { NextResponse } from "next/server";
import type { User } from "@supabase/supabase-js";

import { getAllowedAdminEmails, isAllowedAdminEmail } from "@/lib/admin";
import { createClient } from "@/lib/supabase/server";

type AuthResult = {
  response?: NextResponse;
  user?: User;
};

export async function requireAuthenticatedUser(): Promise<AuthResult> {
  const supabase = await createClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    return {
      response: NextResponse.json(
        { success: false, error: "Unauthorized" },
        { status: 401 }
      ),
    };
  }

  return { user };
}

export async function requireAdminUser(): Promise<AuthResult> {
  const auth = await requireAuthenticatedUser();
  if (auth.response || !auth.user) {
    return auth;
  }

  if (getAllowedAdminEmails().length === 0) {
    return {
      response: NextResponse.json(
        { success: false, error: "Admin allowlist is not configured" },
        { status: 503 }
      ),
    };
  }

  if (!isAllowedAdminEmail(auth.user.email)) {
    return {
      response: NextResponse.json(
        { success: false, error: "Forbidden" },
        { status: 403 }
      ),
    };
  }

  return auth;
}

export function verifyCronSecret(req: Request): NextResponse | null {
  const configuredSecret = process.env.CRON_SECRET;
  const secretHeader = req.headers.get("x-cron-secret");
  const authorizationHeader = req.headers.get("authorization");
  const bearerToken = authorizationHeader?.startsWith("Bearer ")
    ? authorizationHeader.slice(7)
    : null;

  if (
    !configuredSecret ||
    (secretHeader !== configuredSecret && bearerToken !== configuredSecret)
  ) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  return null;
}

export async function requireAdminOrCron(req: Request): Promise<NextResponse | null> {
  const cronAuth = verifyCronSecret(req);
  if (!cronAuth) {
    return null;
  }

  const adminAuth = await requireAdminUser();
  return adminAuth.response ?? null;
}
