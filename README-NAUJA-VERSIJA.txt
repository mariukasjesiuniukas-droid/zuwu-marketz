ZUWU MARKET – ATNAUJINIMAS

SVARBU: Ši versija išlaiko esamą Supabase prisijungimo, profilių, skelbimų, žinučių ir admin užsakymų sistemą, o prideda krepšelį, bendrą Discord ticketą, akcijas, kainų filtrus ir Discord narių skaitiklį.

ĮDIEGIMAS
1. Išarchyvuok ZIP ir GitHub repozitorijoje pakeisk index.html bei įkelk visą api/ aplanką (api/create-ticket.js ir api/discord-stats.js).
2. Supabase Dashboard -> SQL Editor: pirmiausia turi būti įvykdytas esamas setup.sql. Tada paleisk upgrade-cart-promotions.sql.
3. Vercel Environment Variables turi būti nustatyti:
   SUPABASE_URL
   SUPABASE_ANON_KEY
   SUPABASE_SERVICE_ROLE_KEY (tik Vercel, niekada ne HTML/GitHub)
   DISCORD_BOT_TOKEN (tik Vercel, niekada ne HTML/GitHub)
   DISCORD_GUILD_ID
   DISCORD_TICKET_CATEGORY_ID
   DISCORD_STAFF_ROLE_ID (neprivaloma)
4. Vercel redeploy.
5. Botas turi būti serveryje, turėti Manage Channels, View Channels, Send Messages, Read Message History, Embed Links. Ticket kategorijoje negali būti botui draudžiančių permission overwrite.
6. Tikras Discord narių skaičius gaunamas per Discord API; tam botas turi būti tame pačiame serveryje.

ADMIN
- Admin UID faile index.html ir setup.sql yra nustatytas į esamą projekto administratoriaus UUID: 760d15f6-6d18-4b40-916b-6473473a66cf. Jei tai ne tavo Auth UID, pakeisk abiejose vietose į savo UID.
- Admin panelėje gali įjungti/išjungti bendrą akciją. Procentinė nuolaida ribojama iki 90%; fiksuota nuolaida nepadaro prekės nemokamos.
- Krepšelio checkout kainas perskaičiuoja Supabase RPC, nepasitikėdamas naršyklės pateiktomis kainomis.

PASTABOS
- Checkout sukuria atskirą orders įrašą kiekvienai krepšelio prekei, bet tik vieną Discord ticket visam krepšeliui.
- Jei Discord ticket kūrimas nepavyksta, Supabase užsakymai vis tiek lieka pateikti. Pataisius Discord teises, ticketą galima kurti pakartotinai tik po atskiro serverio pusės retry įgyvendinimo; šiuo metu naujas checkout sukuria naujus order įrašus.
- Tai atnaujintas projektas, bet prieš viešą paleidimą būtina patikrinti Supabase RLS, Vercel env variables, Discord bot permissions ir testinį užsakymą.
