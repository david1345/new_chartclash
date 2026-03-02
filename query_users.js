const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const env = fs.readFileSync('.env.development', 'utf-8');
const supabaseUrl = env.match(/NEXT_PUBLIC_SUPABASE_URL=(.*)/)[1];
const supabaseKey = env.match(/SUPABASE_SERVICE_ROLE_KEY=(.*)/)[1];

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
  const { data: { users }, error } = await supabase.auth.admin.listUsers();
  if (error) {
    console.error(error);
    return;
  }
  console.log("USERS IN DB:");
  users.forEach(u => {
    console.log(`ID: ${u.id}, Email: ${u.email}, Provider: ${u.app_metadata?.provider}, Identities: ${JSON.stringify(u.identities?.map(i => i.provider))}`);
  });
}
check();
