ZUWU MARKET - Discord ticket API

SVARBU: ikelkite siame archyve esanti api aplanka i ta pati GitHub projekto saknini aplanka, kuriame yra index.html.
Galutine struktura turi buti:
  index.html
  api/create-ticket.js

NEKELKITE viso papildomo aplanko (pvz. zuwu-ticket-root) i repo kaip vieno poaplankio.
NEKEISKITE index.html ar setup.sql.

Vercel projekte patikrinkite Root Directory: jis turi rodyti i aplanka, kuriame yra index.html ir api aplankas.
Po GitHub commit palaukite naujo Production deployment.

Vercel Environment Variables (Production):
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
DISCORD_BOT_TOKEN
DISCORD_GUILD_ID
DISCORD_TICKET_CATEGORY_ID
DISCORD_STAFF_ROLE_ID (optional)

Pakeitus Environment Variables reikia naujo deployment.
Niekada nedekite slaptu raktu i GitHub ar i narsykles koda.
