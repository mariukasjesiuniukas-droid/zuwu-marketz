ZUWU MARKET V5 – CHECKOUT / DISCORD TICKET PAPILDYMAS

Kas šiame atnaujinime pakeista:
- Checkout lange galima pasirinkti PayPal arba banko kortelę.
- Pasirinkimas įrašomas į kiekvieną užsakymą per atskirą RPC `zuwu_submit_cart_v5`.
- Discord ticket pranešime rodomas pasirinktas mokėjimo būdas.
- Sukūrus ticket, kiekvienas jo užsakymas susiejamas su Discord kanalu lentelėje `zuwu_discord_tickets`.
- V4 RPC ir senas V4 checkout palikti nepakeisti; pakeistas tik V5 kopijos frontend.

SVARBU: PayPal/kortelės pasirinkimas nėra mokėjimo apdorojimas. Šis pakeitimas nenuskaito pinigų ir neprašo kortelės numerio/CVV. Tikram mokėjimui reikės oficialaus mokėjimų tiekėjo integracijos ir atskiro saugaus patvirtinimo srauto.

DIEGIMAS TIK TESTINĖJE APLINKOJE:
1. Palik Production V4 nepakeistą. Sukurk GitHub branch `v5-staging` ir atskirą Supabase staging projektą.
2. Įkelk šio ZIP `zuwu-market-v4` katalogo turinį į staging branch.
3. Supabase SQL Editor staging projekte paleisk `v5-ticket-checkout.sql` TIK po V4 migracijų.
4. Vercel staging projekte patikrink esamus env: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, DISCORD_BOT_TOKEN, DISCORD_GUILD_ID, DISCORD_TICKET_CATEGORY_ID. `DISCORD_STAFF_ROLE_ID` neprivalomas senam ticket kūrimui.
5. Testuok su testiniu produktu ir pirkėjo paskyra: abu mokėjimo pasirinkimai, stock sumažėjimas, ticket tekstas ir įrašas `zuwu_discord_tickets`.

APRIBOJIMAI:
- Šis paketas dar NEĮDIEGIA Discord ticket mygtukų „Patvirtinti / Apsiimti / Uždaryti“ ir automatinio Discord statuso sinchronizavimo. Tam reikia atskiro server-side veiksmų API su Discord rolės patikra ir atominiu claim valdymu; neįjunk šių veiksmų vien UI mygtukais.
- Likusios V5 funkcijos iš ankstesnio foundation (wishlist, helpdesk, notifications, reviews, loyalty, fraud, flash deals, pilna admin analitika) dar nėra pilnai sujungtos su UI/API.
- Nepatikrinta tavo tikroje Supabase/Vercel/Discord aplinkoje; tai staging paruoštas kodas, ne Production diegimas.
