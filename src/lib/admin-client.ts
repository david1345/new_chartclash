function parseAdminEmails(configured?: string | null): string[] {
  if (!configured) {
    return [];
  }

  return configured
    .split(",")
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
}

export function getAllowedAdminEmails() {
  return parseAdminEmails(process.env.NEXT_PUBLIC_ADMIN_EMAILS);
}

export function isAllowedAdminEmail(email?: string | null) {
  if (!email) return false;
  return getAllowedAdminEmails().includes(email.trim().toLowerCase());
}
