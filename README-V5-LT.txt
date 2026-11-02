ZUWU MARKET V5 – SAUGUS PARUOŠIMO PAKETAS

SVARBU
V4 šaltinio kopija palikta kataloge /zuwu-market-v4 ir nepakeista. V5 migracija bei PWA failai yra atskiri. Tai dar nėra pilnai sujungtas ir Production aplinkoje patikrintas V5 leidimas: reikia prijungti kiekvienos funkcijos UI ir serverio API bei atlikti testus tavo Supabase/Vercel/Discord aplinkoje.

SAUGUS DIEGIMO PLANAS
1. GitHub sukurk naują branch: v5-staging. Production branch nekeisk.
2. Išsaugok dabartinį Vercel Production deployment ir Supabase backup.
3. V5 migraciją vykdyk tik atskiroje Supabase STAGING duomenų bazėje ir tik po visų V4 migracijų.
4. PWA failus laikyk atskirai. Prieš aktyvuojant, prijunk manifest linką ir service worker registraciją į index.html.
5. API/Discord integracijas diek tik po server-side admin patikros. Niekada nekelk SUPABASE_SERVICE_ROLE_KEY ar DISCORD_BOT_TOKEN į naršyklės kodą ar GitHub.
6. Testuok su atskiromis pirkėjo ir admin paskyromis. Patikrink RLS: vienas vartotojas negali matyti kito bilietų, žinučių, norų sąrašo ar loyalty istorijos.
7. Tik po testų sujunk v5-staging į Production. Jei kyla problemų, grįžk į ankstesnį Vercel deployment.

DUOMENŲ BAZĖS PAGRINDAS
- Užsakymų įvykių istorija / sekimo laiko juosta
- Norų sąrašas ir restock prenumeratos
- Pagalbos bilietai ir atsakymai
- Pranešimų centras
- Pardavėjų atsiliepimai ir reputacijos duomenys
- Flash Deals
- Loyalty taškų apskaita (ledger)
- Sukčiavimo pranešimai ir administratoriaus audito žurnalas
- Discord susiejimo įrašų pagrindas

SAUGUMAS IR NEUŽBAIGTI DARBAI
Migracija remiasi jau esančia public.zuwu_is_admin() funkcija. Prieš diegiant patikrink, kad joje yra teisingas tavo Supabase Auth UID. Pateiktos lentelės yra saugus pagrindas, bet pinigų, atsargų, loyalty taškų, review patvirtinimo, anti-fraud sprendimų ir Discord role sync muutused peavad vykti per validuotus serverio API/RPC. Šiame pakete dar nėra pilnai prijungtų V5 ekranų, checkout/loyalty taisyklių, anti-fraud automatikos ar live admin analitikos.

PWA
Service worker necache'ina autentifikacijos, Supabase, API, užsakymų ar vartotojų duomenų. Tai sąmoningai konservatyvus offline shell. PWA reikia aktyvuoti tik prijungus jį prie svetainės ir patikrinus HTTPS.
