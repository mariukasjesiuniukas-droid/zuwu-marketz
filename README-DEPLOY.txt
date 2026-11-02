ZUWU MARKET – DISCORD TICKETŲ FUNKCIJOS PRIDĖJIMAS

Ši pataisa prideda trūkstamą Vercel API funkciją. index.html, setup.sql ir užsakymų/admin logika palikti nepakeisti.

1. GitHub repozitorijoje išsaugok dabartinę veikiančią versiją (commit arba atsarginį ZIP).
2. Įkelk visą aplanką api/ su failu create-ticket.js į repozitorijos šaknį (ten pat, kur index.html).
3. Vercel -> Settings -> Environment Variables patikrink, kad būtų šie kintamieji:
   SUPABASE_URL
   SUPABASE_ANON_KEY
   SUPABASE_SERVICE_ROLE_KEY
   DISCORD_BOT_TOKEN
   DISCORD_GUILD_ID
   DISCORD_TICKET_CATEGORY_ID
   DISCORD_STAFF_ROLE_ID (neprivalomas)
4. Secret reikšmes įrašyk tik Vercel. Niekada jų nedėk į index.html, GitHub ar pokalbį.
5. Vercel -> Deployments -> redeploy naują commit.
6. Testuok tik su savo paskyra ir bandomuoju užsakymu.

SVARBU:
- Discord botui serveryje reikia Manage Channels, View Channels ir Send Messages teisių.
- Pirkėjas turi būti prisijungęs per Discord OAuth, ne vien el. paštu.
- API patikrina Supabase sesiją, užsakymo savininką ir Discord OAuth tapatybę.
- API naudoja service role tik serveryje. Niekada nepublikuok šio rakto.
- Jei Discord identity nerandama Supabase Auth vartotojo identities sąraše, ticketas nebus sukurtas. Tuomet reikės peržiūrėti Supabase Discord provider konfigūraciją.
- Šis ZIP nėra diegiamas automatiškai: pirmiausia reikia įkelti api/ į GitHub ir nustatyti Vercel Environment Variables.
