ZUWU MARKET V5 – CHECKOUT INTEGRACIJA

Kas pakeista šiame pakete:
- Krepšelyje pridėtas PayPal arba banko kortelės pasirinkimas. Tai tik mokėjimo būdo pasirinkimas; automatinis mokėjimų apdorojimas dar neįdiegtas. Kortelės duomenų svetainė neprašo ir nesaugo.
- Checkout dabar kviečia public.zuwu_submit_cart_v5, perduodamas p_items, p_buyer_note ir p_payment_method.
- Discord ticket žinutėje parodomas pasirinktas mokėjimo būdas.
- Sukūrus Discord ticket, kiekvienas užsakymas susiejamas su kanalu public.zuwu_discord_tickets lentelėje. Pakartotinis API kvietimas atpažįsta esamą ticket pagal topic ir atnaujina susiejimus.
- Palaikomas TICKET_SUPPORT_ROLE_ID (taip pat senasis DISCORD_STAFF_ROLE_ID).

DIEGIMAS TIK V5 STAGING:
1. Išarchyvuok paketą ir įkelk jo turinį į atskirą V5 GitHub branch/repository.
2. Vercel projekte, kuris prijungtas tik prie V5 staging, nustatyk šiuos Environment Variables: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, DISCORD_BOT_TOKEN, DISCORD_GUILD_ID, DISCORD_TICKET_CATEGORY_ID, TICKET_SUPPORT_ROLE_ID.
3. Service role key ir bot token laikyk tik Vercel Environment Variables – niekada nedėk į index.html ar GitHub.
4. Įsitikink, kad Discord bot turi Manage Channels ir Send Messages teises, o ticket kategorija priklauso nurodytam serveriui.
5. Deploy į V5 staging domeną ir išbandyk su testine preke maža suma.

SVARBU:
- PayPal/Card pasirinkimas nėra tikras mokėjimas. Nežymėk užsakymo kaip apmokėto vien dėl pasirinkto metodo. Tikram mokėjimui reikės mokėjimų tiekėjo ir server-side webhook patvirtinimo.
- Šis pakeitimas neįgyvendina visų V5 funkcijų (pvz. ticket claim/status sync, loyalty, fraud UI, pilno support centro).
- V4 Production nekeisk ir šio ZIP nekelk į Production.
