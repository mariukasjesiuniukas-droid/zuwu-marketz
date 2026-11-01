# ZUWU MARKET — prototipas

## Paleidimas
1. Išarchyvuok `zuwu-market-prototype.zip`.
2. Atidaryk `index.html` naršyklėje.
3. Nereikia diegti papildomų programų.

## Kas veikia prototipe
- Lietuviškas responsive marketplace puslapis.
- Kategorijų filtravimas ir paieška.
- Rikiavimas pagal kainą.
- Demonstracinis prisijungimas.
- Demonstracinių skelbimų kūrimas ir saugojimas naršyklės `localStorage`.

## Svarbūs apribojimai
Tai yra FRONTEND demonstracinis prototipas, o ne paruošta viešai prekybai platforma.
- Prisijungimas nėra tikras autentifikavimas. Nenaudok tikrų slaptažodžių.
- Discord OAuth2 mygtukas yra tik vieta būsimai integracijai.
- Skelbimai saugomi tik tame pačiame naršyklės profilyje.
- Nėra serverio, duomenų bazės, moderavimo backend, tikrų pranešimų ar mokėjimų.
- Domenas `zuwu.market` nėra užregistruotas ar prijungtas.

## Prieš viešą paleidimą
Reikės backend, saugios autentifikacijos (pvz., Supabase Auth), duomenų bazės su prieigos taisyklėmis, serverio pusėje tikrinamų įkėlimų, moderavimo įrankių, privatumo politikos, naudojimo taisyklių ir teisėto mokėjimų teikėjo, jei mokėjimai bus įjungiami.
Discord OAuth2 raktų niekada nedėk į frontend kodą. Naudok serverio aplinkos kintamuosius.
