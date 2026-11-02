ZUWU MARKET V4 – UI, sandėlio likučiai ir Discord automatizacija

ĮTRAUKTA
- Atskiros navigacijos skiltys: Pagalba, Prekės, Krepšelis, Saugumas, Mano profilis, Žinutės, Taisyklės. Admin ir Atsijungti rodomi pagal prisijungimą/teises.
- Žinučių burbulų išvaizda, laiko žymos, Enter siuntimas ir Shift+Enter nauja eilutė.
- Admin sandėlio valdymas: tikslus likutis, papildymo kiekis ir likučio išsaugojimas.
- Checkout tikrina likutį ir SQL funkcija atominiu būdu sumažina atsargas.
- Papildžius prekę kviečiamas /api/restock-notice ir siunčiamas embed į Discord restock kanalą.
- Kai adminas nustato užsakymo statusą Įvykdyta, /api/grant-buyer-role suteikia Discord rolę pirkėjui, jeigu jis prisijungęs per Discord.
- Taisyklės skiltis.

DIEGIMAS
1. Atsarginė kopija: išsaugok dabartinį GitHub/Vercel veikiančios versijos commit. Įkelk visą šio ZIP turinį į repo (ne tik index.html), išsaugodamas api/ katalogą.
2. Supabase SQL Editor paleisk v4-inventory-discord.sql PO setup.sql, upgrade-cart-promotions.sql ir ankstesnių V3 migracijų.
3. Svarbu: esamoms prekėms stock po migracijos bus 0. Admin panelėje nustatyk realų kiekį kiekvienai prekei. Taip apsaugoma nuo netyčinio neteisingo pardavimo.
4. Vercel Environment Variables: ADMIN_USER_ID (tas pats Supabase Auth UID kaip index.html ADMIN_USER_ID), DISCORD_RESTOCK_CHANNEL_ID (kanalo ID), DISCORD_BUYER_ROLE_ID (rolės „Pirkėjas“ ID), taip pat jau naudojami SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, DISCORD_BOT_TOKEN, DISCORD_GUILD_ID. Slaptus raktus laikyk tik Vercel.
5. Discord Developer Portal / serveris: botas turi View Channel, Send Messages, Embed Links leidimus #restock kanale; Manage Roles leidimą ir bot role turi būti aukščiau už „Pirkėjas“ rolę. Pirkėjas turi būti tame pačiame Discord serveryje.
6. Redeploy Vercel. Testuok su testine preke ir testine paskyra.

SAUGUMAS IR RIBOJIMAI
- API patikrina admin UID prieš Discord pranešimą ir rolės suteikimą.
- Automatinė rolė veikia tik jei pirkėjas susiejo Discord paskyrą per Discord OAuth ir yra tavo Discord serveryje.
- Jei statusas pakeistas į „Įvykdyta“, bet Discord rolės API nepavyko, statusas lieka pakeistas; pakartotinai nustatyk „Įvykdyta“ po boto konfigūracijos sutvarkymo.
- Šis ZIP nebuvo paleistas tavo Vercel/Supabase/Discord aplinkoje, todėl būtinas testavimas po diegimo.
- Kuponų nuolaidos iš V3 UI nėra įtrauktos į checkout sumą, kol serverio checkout RPC atskirai jų nepatvirtina.
