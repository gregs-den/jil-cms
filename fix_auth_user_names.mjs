// One-time maintenance script: re-syncs auth.users' user_metadata.name from the
// correct (clean UTF-8) members.name. Fixes corruption ("ñ" -> "??") introduced by
// an earlier bulk Auth-user import that read a non-UTF-8-encoded source file.
//
// This only touches user_metadata.name — nothing else in auth.users or in your
// members/profiles tables. Your app never reads this field anywhere, so it's
// purely cosmetic (fixes the "Display name" column in the Supabase dashboard).
//
// Usage (run locally — your service role key never leaves your machine, and is
// never sent to or seen by Claude):
//
//   npm install                # only needed once, if you haven't already
//   SUPABASE_URL=https://xstqlpfeogldcttpdtjy.supabase.co \
//   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key \
//   node fix_auth_user_names.mjs --dry-run     (preview only, no writes)
//
//   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... node fix_auth_user_names.mjs
//                                                (actually applies the fixes)
//
// Find your service role key in the Supabase dashboard under
// Project Settings > API > service_role (keep it secret — never commit it).

import { createClient } from "@supabase/supabase-js";

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
const dryRun = process.argv.includes("--dry-run");

if (!url || !key) {
  console.error("Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY env vars first (see comments at the top of this file).");
  process.exit(1);
}

const supabase = createClient(url, key, { auth: { persistSession: false } });

async function main() {
  const { data: profiles, error: profilesError } = await supabase
    .from("profiles")
    .select("id, username, member_id")
    .not("member_id", "is", null);
  if (profilesError) throw profilesError;

  const memberIds = [...new Set(profiles.map(p => p.member_id))];
  const { data: members, error: membersError } = await supabase
    .from("members")
    .select("id, name")
    .in("id", memberIds);
  if (membersError) throw membersError;
  const memberNameById = Object.fromEntries(members.map(m => [m.id, m.name]));

  let allUsers = [], page = 1;
  while (true) {
    const { data, error } = await supabase.auth.admin.listUsers({ page, perPage: 200 });
    if (error) throw error;
    allUsers = allUsers.concat(data.users);
    if (data.users.length < 200) break;
    page += 1;
  }
  const userById = Object.fromEntries(allUsers.map(u => [u.id, u]));

  let fixed = 0, skipped = 0, missing = 0;
  for (const profile of profiles) {
    const correctName = memberNameById[profile.member_id];
    const user = userById[profile.id];
    if (!correctName || !user) { missing += 1; continue; }

    const currentName = user.user_metadata?.name;
    if (currentName === correctName) { skipped += 1; continue; }

    console.log(`${dryRun ? "[dry-run] " : ""}Fixing ${user.email}: "${currentName}" -> "${correctName}"`);
    if (!dryRun) {
      const { error } = await supabase.auth.admin.updateUserById(user.id, {
        user_metadata: { ...user.user_metadata, name: correctName },
      });
      if (error) { console.error(`  Failed: ${error.message}`); continue; }
    }
    fixed += 1;
  }

  console.log(`\nDone. ${dryRun ? "Would fix" : "Fixed"}: ${fixed}, already correct: ${skipped}, no linked member/user: ${missing}`);
}

main().catch(err => { console.error(err); process.exit(1); });
