ZUWU MARKET V3 – papildomos funkcijos

Failai: index.html, api/*, esamos V2 SQL migracijos ir v3-community-features.sql.

DIEGIMAS:
1. Padarykite GitHub/Vercel atsarginę kopiją.
2. Pakeiskite index.html ir išsaugokite api aplanką iš šio ZIP.
3. Supabase SQL Editor paleiskite v3-community-features.sql PO ankstesnių V2 migracijų.
4. Patikrinkite, kad z u w u_is_admin() turi tikrą jūsų admin UUID; nekeiskite RLS į viešą.
5. Redeploy Vercel.

ĮTRAUKTA: admin statistikos kortelės, kuponų sukūrimo/įjungimo UI, kategorijų CRUD UI, mėgstamiausios prekės, trending pagal patvirtintus/įvykdytus užsakymus, atsiliepimų įrašymo UI (tik įvykdytas užsakymas), pranešimų lentelė ir DB triggeris užsakymo būsenai pasikeitus, pranešimo apie skelbimą UI.

SVARBU / RIBOJIMAI:
- Kupono patikrinimo UI dar netaiko nuolaidos į galutinę checkout sumą. NENAUDOKITE kuponų kaip mokėjimo nuolaidos, kol serverio RPC nėra atnaujintas, kad atominiu būdu patikrintų ir panaudotų kodą.
- Kategorijų UI valdo atskirą kategorijų lentelę; esama listing forma dar turi statinį kategorijų pasirinkimą.
- Atsiliepimų pateikimo funkcija yra paruošta, bet produktų kortelių pilnas atsiliepimų rodymas dar nėra įjungtas.
- Pranešimai įrašomi DB; pilnas pranešimų inbox UI ir push prenumerata dar neįdiegti.
- Trending skaičiuojamas pagal approved/paid/fulfilled užsakymų eilutes, ne pagal apsilankymus.
- Admin statistika skaičiuoja užsakymų sumas pagal esamą orders lentelę; tai nėra apskaitos ar realių mokėjimų ataskaita.
- Patikrinkite Vercel Environment Variables ir Discord ticket veikimą testiniu užsakymu.
- Niekada nekelkite service_role rakto ar Discord bot tokeno į GitHub.
