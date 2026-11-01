ZUWU MARKET — VIENAS ADMINISTRATORIUS + KATALOGAS + UŽSAKYMAI

Kas įtraukta
- Supabase el. pašto / slaptažodžio registracija ir prisijungimas.
- Discord OAuth prisijungimas (Supabase Discord provider).
- Tik vienas nustatytas ADMIN_USER_ID gali kurti, redaguoti ir trinti skelbimus.
- Viešas katalogas su žaidimų valiutos, skinų / daiktų, žaidimų kodų ir kitos kategorijomis.
- Admino skelbimų nuotraukų įkėlimas į Supabase Storage bucket listing_images.
- Profiliai ir privačios žinutės (naudoja jau sukurtas profiles ir messages lenteles).
- Užsakymo pateikimas be mokėjimo: pirkėjas pateikia užklausą, adminas peržiūri ir patvirtina / atmeta / pažymi įvykdytu.
- Discord serverio mygtukas: https://discord.gg/mMeb5vn6Vz
- Jokios reklamos.

SVARBU APIE MOKĖJIMUS
Šioje versijoje kortelių / PayPal atsiskaitymas NEĮJUNGTAS. Pirma reikia patikrinti, ar konkretūs skaitmeniniai žaidimų produktai leidžiami mokėjimo tiekėjo taisyklėse ir platformų licencijose. Niekada nerink kortelių duomenų pačioje svetainėje. Tik po patvirtinimo mokėjimo tiekėjas turi būti prijungtas per saugų serverio webhook, o ne per naršyklės JS. Paskyrų / prenumeratų prieigų perpardavimas gali pažeisti platformų taisykles; šiame kataloge jų kaip atskiros kategorijos nėra.

DIEGIMAS
1. Išskleisk ZIP. GitHub repo pakeisk seną index.html nauju. Įkelk ir setup.sql / README.txt (SQL failas nėra būtinas Vercel, jį paleisi Supabase).
2. Supabase -> Authentication -> Users. Susikurk savo paskyrą, patvirtink el. paštą, surask savo vartotoją ir nukopijuok UID (UUID).
3. Atidaryk setup.sql. Pakeisk VISAS PAKEISK_ADMIN_USER_UUID vietas į savo UID. Viena vieta SQL funkcijoje, kita index.html faile (ADMIN_USER_ID). UID yra UUID, ne el. pašto adresas.
4. Supabase -> SQL Editor -> New query. Įklijuok setup.sql su savo pakeistu UUID ir paleisk.
5. Supabase -> Storage. SQL automatiškai sukuria / atnaujina PUBLIC bucket listing_images. Esami bucket avatars paliekami.
6. Patikrink, kad profiles lentelė turi: id, username, avatar_url, bio, updated_at. listings lentelė turi: id (uuid), seller_id (uuid), title, description, price, category, image_url, status, created_at. messages lentelė turi: sender_id, receiver_id, listing_id, content, created_at. Jų RLS turi riboti žinutes tik pokalbio dalyviams.
7. Supabase -> Authentication -> URL Configuration: Site URL https://www.zuwumarket.store; Redirect URLs pridėk https://www.zuwumarket.store/** ir savo Vercel domeną/**. Discord provider turi būti įjungtas.
8. GitHub -> Commit changes. Vercel automatiškai persiųs naują versiją. Patikrink svetainę.

KAIP VEIKIA ADMINAS
- Prisijunk su ta paskyra, kurios UID įrašytas ADMIN_USER_ID.
- Atsiras mygtukas Admin ir Skelbti prekę.
- Kiti vartotojai gali registruotis, naršyti, rašyti žinutes ir pateikti užsakymus, bet negali skelbti.
- Užsakymą sukurs saugi submit_order() SQL funkcija: kaina paimama iš listings lentelės, ne iš naršyklės įvesties.
- Admin -> Užsakymai: pakeisk būseną į Patvirtinta / Atmesta / Įvykdyta / Grąžinta.

SVARBIOS PASTABOS / APRIBOJIMAI
- Ši versija yra veikiantis prototipas, ne pilnai audituota komercinė platforma.
- Užsakymo patvirtinimas nėra mokėjimo patvirtinimas. Nėra kortelių ar PayPal checkout, automatinio išmokėjimo ar webhook.
- Prieš viešą paleidimą pridėk privatumo politiką, naudojimo taisykles, kontaktus, skundų / grąžinimų tvarką, apsaugą nuo spam ir moderavimo procesą.
- Neįkelk slaptažodžių, paskyrų prisijungimų, recovery kodų ar kitų slaptų duomenų į skelbimus / žinutes.
- Jei anksčiau turėjai viešą listing_images bucket su kitomis upload politikomis, setup.sql įdeda ribojančias taisykles. Patikrink Storage -> Policies po paleidimo.
- Po OAuth prisijungimo naudok domeną, kuris įtrauktas į Supabase Redirect URLs.

Failai
- index.html — svetainės front-end.
- setup.sql — Supabase lentelės, RLS ir saugus užsakymo RPC.


ATNAUJINIMAS: ŽINUČIŲ IR UŽSAKYMŲ PRANEŠIMAI
1. Supabase SQL Editor paleisk notifications-migration.sql.
2. Įkelk atnaujintą index.html į GitHub (pakeisk seną).
3. Vercel automatiškai iš naujo įdiegs svetainę.
4. Prisijungęs profilį atsidaryk „Mano užsakymai“ – ten matysi būsenas.
5. „Įjungti naršyklės pranešimus“ leidžia gauti pranešimus, kai svetainė atidaryta ir naršyklė leidžia pranešimus.

PayPal: šiame kataloge yra žaidimų valiuta ir skaitmeniniai virtualūs daiktai. PayPal Acceptable Use Policy riboja virtualių žaidimų valiutų ir tam tikrų skaitmeninių prekių operacijas. Todėl PayPal mygtukas neįjungiamas, kol PayPal raštu nepatvirtina konkrečių tavo prekių tinkamumo.
