ZUWU MARKET – SUPABASE CONNECTED STARTER

This version connects email/password authentication and marketplace listings to Supabase.
Supabase project URL configured: https://fhjymwbiyzgllpcyzfqb.supabase.co
The browser publishable key is configured in index.html. Publishable keys are intended for browser use; database access must be protected by Row Level Security policies.

IMPORTANT SETUP BEFORE TESTING
1. In Supabase > Authentication > URL Configuration:
   - Set Site URL to your Vercel website URL (for example https://your-project.vercel.app).
   - Add that same URL to Redirect URLs. Add your custom domain too if configured.
2. In Supabase > Authentication > Providers > Email, enable Email provider.
3. For Discord login, enable Discord provider in Supabase and configure a Discord OAuth application. Add Supabase's displayed callback URL to Discord Developer Portal OAuth2 Redirects. The Discord button will not work until this is configured.
4. Ensure the SQL tables and RLS policies from the setup tutorial have been run.
5. In Supabase SQL Editor, run the extra SQL below to allow authenticated users to create their own profile row when they first sign in, if your profiles table does not already have it:

create policy "Users create own profile"
on public.profiles for insert
with check (auth.uid() = id);

The existing listing policies must allow authenticated users to insert rows only when seller_id = auth.uid().

DEPLOY
1. Extract this ZIP.
2. Open your GitHub repository.
3. Replace the old index.html with this new index.html (and optionally upload this README).
4. Commit changes. Vercel should redeploy automatically.

CURRENTLY CONNECTED
- Email/password registration and login
- Logout
- Load shared active listings from Supabase
- Create shared listings in Supabase
- Discord OAuth button (requires provider configuration)

NOT YET IMPLEMENTED
- Listing photo upload (Storage bucket and upload policies required)
- Buyer/seller messaging UI
- Payment processing
- Admin moderation and reporting
- Full production security review

Do not add Supabase secret/service_role keys or database passwords to this website. Never collect payment card details directly.
