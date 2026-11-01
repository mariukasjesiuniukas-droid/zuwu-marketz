ZUWU MARKET – DISCORD TICKETŲ ĮJUNGIMAS

KAIP VEIKS
- Pirkėjas turi būti prisijungęs prie ZUWU MARKET per Discord OAuth (Supabase Discord provider).
- Paspaudus „Užsakyti“, svetainė sukuria Supabase užsakymą ir kviečia /api/create-ticket.
- Vercel funkcija patikrina prisijungusį vartotoją, užsakymo savininką ir susietą Discord paskyrą.
- Bote sukuriamas privatus kanalas kategorijoje, kurį mato pirkėjas ir nurodytas staff role (jei nustatytas).
- Į kanalą išsiunčiama prekė, kaina, užsakymo ID ir pirkėjo žinutė.

1. DISCORD SERVERIS / BOTAS
- Discord Developer Portal -> pasirink savo Application -> Bot -> Reset Token (jei reikia) ir nukopijuok BOT TOKEN. Niekam jo nesiųsk.
- Botą pakviesk į savo serverį su bot scope ir Manage Channels, View Channels, Send Messages, Read Message History, Embed Links leidimais.
- Serverio nustatymuose susikurk kategoriją, pvz. „ZUWU TICKETS“.
- Įsitikink, kad botui leidžiama kurti kanalus toje kategorijoje. Jei naudoji staff rolę, botui nereikia jos valdyti, bet staff rolė turi turėti prieigą prie sukurtų ticket kanalų.
- Nukopijuok serverio ID (Developer Mode -> dešiniu pelės ant serverio -> Copy Server ID).
- Nukopijuok ticket kategorijos ID (dešiniu pelės ant kategorijos -> Copy Category ID).
- Jei nori, nukopijuok administracijos rolės ID (dešiniu pelės ant rolės -> Copy Role ID). Tai neprivaloma.

2. VERCEL ENVIRONMENT VARIABLES
Vercel -> tavo projektas -> Settings -> Environment Variables pridėk:
SUPABASE_URL = https://fhjymwbiyzgllpcyzfqb.supabase.co
SUPABASE_ANON_KEY = tavo Supabase publishable key (sb_publishable_...)
SUPABASE_SERVICE_ROLE_KEY = Supabase Project Settings -> API Keys -> service_role secret. ŠIS RAKTAS YRA YPAČ SLAPTAS. Tik Vercel Environment Variables, niekada HTML/GitHub/Discord/ChatGPT.
DISCORD_BOT_TOKEN = tavo Discord boto tokenas (slaptas; tik Vercel Environment Variables)
DISCORD_GUILD_ID = tavo Discord serverio ID
DISCORD_TICKET_CATEGORY_ID = ticketų kategorijos ID
DISCORD_STAFF_ROLE_ID = administracijos rolės ID (neprivaloma)
Pasirink Production (ir Preview, jei bandysi preview) ir išsaugok.

3. PERDEPLOY
- GitHub repo įkelk naują index.html ir visą api aplanką su create-ticket.js.
- Commit changes.
- Vercel automatiškai persidiegs. Jei pridėjai env variables po deploy, Vercel -> Deployments -> Redeploy.

4. BANDYMAS
- Prisijunk į ZUWU MARKET būtent per Discord mygtuką (ne vien el. paštu).
- Pasirink prekę ir pateik testinį užsakymą.
- Tikrink, ar Discord serveryje atsirado privatus #pirkti-... kanalas ir ar jame yra užsakymo informacija.

SAUGUMAS / PASTABOS
- Niekada nesiųsk boto tokeno ar Supabase service_role rakto per pokalbį ir nedėk jų į index.html.
- Jei tokeną netyčia paviešinai, nedelsdamas resetink Discord Developer Portal ir pakeisk Vercel env variable.
- Botas turi turėti Manage Channels ir būti tame pačiame serveryje, kurio ID nurodytas.
- Ši funkcija sukuria ticketą tik po to, kai Supabase submit_order RPC sėkmingai sukuria užsakymą.
- Jei Discord OAuth nėra susietas su ZUWU paskyra, užsakymas bus sukurtas, bet ticketo funkcija paprašys pirmiausia prisijungti per Discord.
