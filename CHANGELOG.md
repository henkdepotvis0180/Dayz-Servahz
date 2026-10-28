# Wijzigingen per versie

Elke versie beschrijft het pakket op dat moment. Instellingen in latere versies kunnen eerdere waarden vervangen. De datums hieronder zijn lokale datums voor Nederland.

**Bestaande installatie:** stop de server en behoud `config/server.local.json` en je wereldsave. Maak een wereldbackup voordat je bijwerkt. De hieronder genoemde bestanden vervang je in de uitgepakte pakketmap, naast `01-Instellen.cmd`.

## [0.15.0] — 2026-10-28

### Bruikbare wapenvoorraad en meer eten in winkels en huizen

- Alle 21 geselecteerde modvuurwapens krijgen doel 30/minimum 24, in de teststand 60/48. Vijf voorheen dubbel zo hoge Expansion-wapendoelen zijn verlaagd; totaal 630 normaal / 1260 test. Gewone actieve vanilla-vuurwapens worden na de bestaande vermenigvuldigers begrensd op 30 normaal / 60 met testvoorraad. Event-/crafted-/uitgeschakelde klassen blijven ongemoeid.
- De 18 wapens met losse magazijnen krijgen bij nieuwe CE-spawns 95% kans op hun geselecteerde magazijn. De vijftien losse modmagazijnen krijgen gelijkere doelen: 60/48 normaal, 120/96 test. Gecontroleerde wapen-magazijn-munitiekoppelingen staan in `config/loot-balance.json`.
- SCAR-H, SR-25 en M110 gekoppeld aan vanilla `.308 Winchester`; de eerdere aparte `GCGN_Ammo_762x51` wordt niet meer als losse CE-loot gespawnd (doel/minimum 0). Bestaande items worden niet verwijderd. SNAFU .338 en .300 AAC verhoogd naar 100/80, in testvoorraad 200/160.
- Bijpassende losse munitie/magazijnen krijgen minstens tweemaal het individuele wapendoel, 80–100% hoeveelheid en dezelfde locatiecategorieën/tiers als het bijbehorende modwapen. Dit reserveert geen complete set per gebouw en garandeert geen geladen wapen.
- 27 bestaande houdbare voedsel-/dranktypen krijgen driemaal hun huidige doelen/minima, ook Town/Village en tiers 1–4. Geen activering van uitgeschakeld, geopend, rauw of speciaal eventvoedsel.
- Winkels, horeca en huizen met bruikbare schappen krijgen aparte food-only plekken: maximaal zes bestaande schapposities in winkels/horeca en twee in huizen. Posities worden verplaatst uit het gemengde schap; geen nieuwe of dubbele coördinaten, geen verhoging van het totale gebouwdoel. Nul-capaciteit blijft uitgeschakeld.
- Geen wijziging aan mods, bots, stamina, savebestanden, wachtwoorden of de keuze voor snelle bijvulling. Bestaande wereldloot verdwijnt niet direct; de nieuwe verdeling komt via nieuwe spawns/bijvulling beschikbaar.

**Bijwerken:** stop de server en dubbelklik `Servahz-Update-v0.15.0.cmd` in de bestaande pakketmap. Vereist basis 0.13.0; 0.14.0 mag worden overgeslagen. Het script maakt een backup en vervangt automatisch de gewijzigde bestanden, inclusief de nieuwe balansconfiguratie. Geen nieuwe Workshop-mods, handmatig kopiëren, teststand opnieuw aanzetten of wipe nodig.

**Controle:** pakkettests en controles met officiële Chernarus-CE-data voor wapendoelen, passende voorraad, voedseldoelen, food-only plekken, behoud van bestaande coördinaten/uitgeschakelde typen, herhaald instellen en save-/instellingenbehoud. Windows-tests controleren ook de één-bestandsupdater. De echte spreiding per gebouw, laden/schieten met de actuele Workshop-versies en het tempo waarin een bestaande wereld bijvult moeten lokaal in-game worden beoordeeld.

## [0.14.0] — 2026-10-28

### Eén updatescript in plaats van opnieuw het complete pakket

- Versie 0.13.0 is de vaste Windows-basis. Vanaf deze release is het enige zelf gepubliceerde downloadbestand `Servahz-Update-vX.Y.Z.cmd`; geen nieuwe volledige Windows-ZIP. GitHub toont daarnaast zelf de broncodearchieven.
- Kies een updateversie op GitHub. Het offline script bevat alleen de publieke pakketbestanden die verschillen van 0.13.0, inclusief eerdere wijzigingen tot de gekozen versie. Tussenliggende updates zijn niet nodig. Geen verandering aan mods, loot, bots, stamina of bouwen in 0.14.0.
- Het script herkent een ondersteunde, ongewijzigde pakketversie, weigert eigen pakketwijzigingen en downgrades, controleert moddownloads en stopt als DayZ nog draait. Een ontbrekende basis wordt niet automatisch overschreven of aangemaakt.
- Automatische wereld-/profiel-/configuratiebackup en backup van te vervangen pakketbestanden; daarna bestandsvervanging, instellen en statische controle. Saves, wachtwoorden en lokale loot-/bijvulkeuzes blijven behouden. Geen Steam-downloads, wipe of automatische serverstart.
- Herhalen na succes doet niets. Na een mislukte installer of controle kan hetzelfde script opnieuw instellen. Bij een gedeeltelijke bestandskopie of herstel van de live configuratie kan handmatig herstel uit de backup nodig zijn.

**Bijwerken:** heb eerst basispakket 0.13.0 geïnstalleerd. Stop de server, zet `Servahz-Update-v0.14.0.cmd` naast `01-Instellen.cmd` en dubbelklik. Geen bestanden handmatig vervangen. Download je het script elders, geef dan de bestaande pakketmap op. Oudere installaties eerst met het volledige 0.13.0-pakket bijwerken; `config/server.local.json`, saves en profielen behouden. Backups onder `.local/Backups` bevatten privéwachtwoorden.

**Controle:** integratietests voor de ingesloten payload, backup, save-/wachtwoord-/instellingenbehoud, opnieuw starten, ontbrekende basis, eigen bestandswijzigingen, ontbrekende mods, beschadigde payload en downgradeblokkering. Op Windows wordt ook de echte `.cmd`-launcher uitgevoerd. Echte DayZ-spelwerking en de lokale dubbelklik-/Windows-beveiligingsmeldingen blijven lokaal te controleren.

## [0.13.0] — 2026-10-28

### SNAFU-wapens met begrensd lootbudget

- SNAFU Weapons toegevoegd als vijftiende mod, op server en alle clients. Het eerdere Steam-abonnement alleen maakte de mod nog niet onderdeel van het pakket; deze release voegt modlijst, preset en lootkoppelingen toe.
- Acht wapens: SCAR-H Black, HK416, SR-25, M110 Black, M24, T5000, Honey Badger Black en Vector .45 ACP. Inclusief acht magazijntypen, drie extra munitietypen, twee vizieren en 80% kans op een passend magazijn bij nieuwe CE-wapenspawns.
- Nieuwe SNAFU-wapens, magazijnen en munitie: doel 30/minimum 24; in de teststand 60/48 op alle 17 locatiecategorieën/tier 1–4. De twee vizieren krijgen elk 10/8 normaal en 20/16 in de teststand. Nu 67 extra CE-itemtypen in totaal.
- Acht bestaande Expansion-wapendoelen van 60 naar 30: totaal pakketdoel voor vuurwapens blijft 780 normaal / 1560 test, verdeeld over 21 typen. De nieuwe magazijnen/munitie voegen 330 normale / 660 testdoelen toe; twee vizieren voegen nog 20 normale / 40 testdoelen toe. Geen massale import van alle SNAFU-varianten.
- Bestaande loot, saves, wachtwoorden en profielen worden niet verwijderd. Bots, stamina en bijvulinstellingen blijven gelijk. De complete ZIP bevat alle eerdere updates.

**Bijwerken:** stop de server en maak een wereldbackup. Vervang `scripts`, `config/mission`, `config/mods.json` en `Mods.html`. Behoud `config/server.local.json` en saves/profielen. Host en spelers laden SNAFU naast de bestaande mods, importeren de preset en wachten op Steam. Voer **`01-Instellen.cmd`** uit om je huidige test-/bijvulkeuze te behouden; daarna `02-Start-server.cmd`. `03-Controleren.cmd` moet 67 extra itemtypen tonen. Geen wipe.

**Controle:** pakkettests voor vijftien afzonderlijke modpaden, preset, nieuwe CE-typen en magazijnkoppelingen, gelijkblijvend vuurwapenbudget, testdoelen, herhaald instellen en behoud van saves/wachtwoorden. Echte modcompatibiliteit, spawnklassen, richten/schieten, magazijnen, munitie en persistentie blijven lokaal in-game te controleren.

## [0.12.0] — 2026-10-28

### Boomstammen en bouwmaterialen stapelen

- BaseBuildingItemStackandRepair toegevoegd als veertiende mod aan modlijst en launcher-preset, op server en alle clients vereist.
- Volgens de modbeschrijving onder andere 20 boomstammen/brandhout, 50 planken/metaalplaten en 250 spijkers per stapel. De mod wijzigt ook gereedschapstapels en reparaties met ducttape/epoxy. Geen aanpassing van de eigen loot-, bot-, stamina- of profielinstellingen.
- Splits stammen vóór bevestigen aan bouwkits: volgens de maker kan anders de hele stapel worden verbruikt. Splits gereedschap vóór gebruik om schade aan de hele stapel te voorkomen.
- Geen SNAFU of Building Backpack toegevoegd. De Windows-ZIP bevat alle eerdere pakketupdates; modbestanden blijven via Steam geleverd.

**Bijwerken vanaf 0.11.0:** stop de server, maak een wereldbackup en vervang `config/mods.json` en `Mods.html`. Abonneer host en spelers op BaseBuildingItemStackandRepair, wacht op Steam en importeer de nieuwe preset. Voer **`01-Instellen.cmd`** uit om bestaande loot-/testinstellingen te behouden, daarna `02-Start-server.cmd`. Behoud lokale configuratie, wachtwoorden, profielen en wereldsave. Geen wipe.

**Controle:** pakkettests voor veertien afzonderlijke modpaden, preset en sleutels, bestaande loot/stamina/bouwinstellingen en save-/wachtwoordbehoud. Stapels, splitsen, reparaties, interactie met RaG/Expansion en herstartpersistentie moeten nog lokaal in-game worden gecontroleerd.

## [0.11.0] — 2026-10-27

### Compleet pakket met GoreZ, lootuitbreiding en minder sprintverbruik

- GoreZ toegevoegd als dertiende mod op host en clients: bloedeffecten, bloedsporen/-plassen en vliegen bij lichamen. Geen aparte BleedTrail toevoegen; GoreZ bevat deze functionaliteit al.
- Eén cumulatieve Windows-ZIP bevat alles uit 0.9.0 (barricades, MMG-rugzakken, Expansion-wapens en ruimere/snellere testloot) en 0.10.0 (75% minder verbruik bij rechtop sprinten), inclusief alle eerdere bouw- en botinstellingen. Oude ZIPs zijn niet nodig.
- Alleen GoreZ toegevoegd uit de laatste suggesties; geen Windstride of Survivor Missions. Modcode wordt via Steam geleverd.
- Lokale configuratie, wachtwoorden, profielen en wereldsaves blijven behouden; geen wipe.

**Bijwerken in één keer:** stop de server en maak een wereldbackup. Vervang `scripts`, `config/mission`, `config/profiles`, `config/mods.json`, `Mods.html` en `04-Teststand.cmd` in je bestaande pakketmap. Behoud `config/server.local.json` en je saves. Abonneer host en spelers op alle ontbrekende mods uit `Mods.html`, wacht op Steam en importeer de preset. Voer **`04-Teststand.cmd`** uit en start met `02-Start-server.cmd`. Vanaf vóór 0.9.0 zijn naast GoreZ ook Building Fortifications, MMG en Expansion Weapons nodig.

**Controle:** pakkettests voor alle dertien modpaden/preset, behoud van saves/wachtwoorden, lootkoppelingen, bijvullen, botbudgetten, bouwinstellingen en sprintverbruik. GoreZ-effecten, daadwerkelijke modcompatibiliteit, prestaties en persistentie lokaal in-game controleren.

## [0.10.0] — 2026-10-27

### Minder stamina voor lange afstanden

- Rechtop sprinten gebruikt 25% van het normale verbruik (`sprintStaminaModifierErc=0.25`). Dit geldt ook voor rechtop sprinten tijdens gevechten; er is geen gevechtsdetectie.
- Melee, ontwijken, springen/klimmen, adem inhouden, zwemmen, hurkend sprinten, regeneratie en de gewichtsbeperking houden hun bestaande instellingen. Er is geen extra mod nodig.
- Installer en teststand passen dit toe in de eigen missie. Lokale wachtwoorden, saves en de Steam-standaardmissie blijven behouden; geen wipe.

**Bijwerken:** stop de server, maak een wereldbackup, vervang `scripts` en voer voor jouw teststand `04-Teststand.cmd` uit. Start daarna met `02-Start-server.cmd`. `01-Instellen.cmd` past dezelfde stamina-aanpassing toe met behoud van de huidige lootinstellingen.

**Controle:** pakkettests controleren het sprintverbruik en behoud van overige PlayerData/stamina-instellingen, standaardmissie en saves. In-game nog controleren: lange afstand sprinten met dezelfde bepakking, melee/ontwijken, adem inhouden en springen. Gewicht kan de maximale staminabalk nog steeds beperken.

## [0.9.0] — 2026-10-27

### Barricades, grote rugzakken, extra wapens en sneller zichtbare testloot

- Building Fortifications, MMG – Mightys Military Gear en DayZ-Expansion-Weapons toegevoegd: nu twaalf mods op host en clients.
- 46 gerichte CE-itemtypen: 13 vuurwapens, 7 magazijnen, 6 munitietypen/-dozen, 7 vizieren/railadapters, 9 rugzakvarianten en 4 barricadekits. Geen RPG/LAW/granaatwerpers in de gewone lootselectie.
- Ruime vaste doelen, verdubbeld en alle 17 locatiecategorieën/tier 1–4 in de teststand. Bijvoorbeeld per type doel 120 vuurwapens, 240 magazijnen en 150 rugzakken. Beschikbare posities en categorieën blijven de echte verdeling begrenzen.
- Tien wapens hebben bij nieuwe CE-spawns 80% kans op een passend magazijn. Losse munitie en magazijnen gebruiken 80–100% hoeveelheid; munitiedozen behouden hun normale inhoud.
- Geplaatste barricades krijgen aparte CE-levensduurregels (45 dagen), zonder ze als losse bouwwerken te spawnen. RaG-kosten en bestaande botbudgetten blijven gelijk.
- Nieuw `TestFastRestock`, standaard uit en aan via `04-Teststand.cmd`: 2× positieve gebouw-/containercapaciteit, `RestartSpawn=50`, `RespawnTypes=30`, `RespawnLimit=50`, `RespawnAttempt=4`, `LootSpawnAvoidance=50` en `restock=0` voor actieve gewone vanilla-loot.
- Dit verruimt naast aantallen ook het bijvullen. Er is geen vaste lootgarantie per huis; de toestand van de eigen live wereld is hier niet gemeten. Initialisatie kan meer CPU/tijd vragen.
- Nieuwe CE-bestanden worden expliciet gekoppeld en statisch gecontroleerd. Herhaald instellen stapelt niet. Uitschakelen van `TestFastRestock` herstelt de vijf beheerde bijvulglobals, gebouwcapaciteit en normale restock uit de standaardmissie.
- Lokale configuratie, wachtwoorden, profielen en wereldsaves blijven behouden; geen wipe. Nieuwe beheerde bestanden worden in configuratiebackups meegenomen.

**Bijwerken:** stop de server en maak een wereldbackup. Abonneer host en alle spelers op de drie nieuwe mods en wacht op Steam. Vervang `scripts`, `config/mission`, `config/profiles`, `config/mods.json` en `Mods.html`. Behoud `config/server.local.json` en je wereldsave. Voer **`04-Teststand.cmd`** opnieuw uit; importeer de nieuwe preset en start met `02-Start-server.cmd`. Laat de server laden. Ga bij lege gebouwen meer dan 50 meter weg en kom later terug. `03-Controleren.cmd` moet de 46 extra itemtypen en snelle bijvulwaarden herkennen.

**Controle:** 27 pakkettests geslaagd met testbestanden en 27 met officiële Chernarus-data. Tests voor alle modpaden, nieuwe CE-koppelingen, magazijnen, doelen, capaciteit, herhaald instellen, uitschakelen en behoud van saves/wachtwoorden/overige globals. Nog lokaal in-game te controleren: echte moddownloads, spawnklassen en magazijncompatibiliteit, lootverdeling, barricades plaatsen/bouwen/sluiten en persistentie na herstart, rugzakcapaciteit en serverprestaties.

## [0.8.0] — 2026-10-27

### RaG BaseBuilding erbij en circa 20% meer bots

- RaG_Core en RaG_BaseBuilding toegevoegd aan de modlijst en launcher-preset: nu negen mods op server en alle clients. Bestaande Expansion-mods blijven aanwezig.
- Nieuwe RaG-profielen starten met 2 planken + 1 spijker per kit en 2 planken per houten bouwstap, circa 5 seconden bouwtijd. De optionele metalen deur kost 1 metaalplaat. Dit is geen hout-en-ragsrecept; dat vereist een eigen receptmod.
- 21 RaG-spelerkits en het bouwboek als CE-loot toegevoegd. De teststand verdubbelt hun pakketdoelen en gebruikt alle 17 locatiecategorieën; admin-gereedschap en hologrammen zijn geen loot.
- RaG-profiel wordt alleen bij ontbreken aangemaakt; bestaande profielinstellingen blijven byte voor byte behouden en worden bij opnieuw instellen geback-upt. Wereldbackup bevat ook RaG-profielen. Saves en lokale wachtwoorden worden niet vervangen.
- Patrouilles van 36 naar 43 ingestelde bots (+19,4%); berekend maximum van 26 naar 31 actieve bots (+19,2%). Nog steeds 17 routes en maximaal 12 actieve groepen: 6 vijandige, 4 overlevenden en 2 bewakers. Moeilijkheidsinstellingen blijven gelijk.
- Bestaande Expansion-bouwdelen en codesloten blijven beschikbaar. Gebruik op RaG-delen vanilla combinatiesloten; Expansion-codeslotcompatibiliteit is geen onderdeel van deze release.

**Bijwerken:** stop de server en maak een wereldbackup. Abonneer host en spelers op RaG_Core en RaG_BaseBuilding en wacht op Steam. Vervang `scripts`, `config/mission`, `config/profiles`, `config/mods.json` en `Mods.html` in de pakketmap. Behoud `config/server.local.json` en de wereldsave. Voer `01-Instellen.cmd` uit, of `04-Teststand.cmd` voor de teststand, importeer de nieuwe preset en start opnieuw. Een reeds bestaand RaG-profiel behoudt zijn eigen bouwkosten.

**Controle:** 24 pakkettests geslaagd met testbestanden en 24 met officiële Chernarus-data. De tests controleren de negen modpaden, RaG-kosten/loot, eerste profielaanmaak, behoud en backup van bestaande profielen/saves/wachtwoorden, herhaald instellen en alle combinaties van botbudgetten. Lokaal nog controleren: de echte moddownloads en game starten, RaG-kits craften/plaatsen/afbouwen, slotwerking, herstartpersistentie en prestaties met extra bots.

## [0.7.0] — 2026-10-27

### Wapens, munitie en bouwvoorraad op alle soorten testlocaties

- Nieuw veld `TestSuppliesEverywhere`: standaard uit; `04-Teststand.cmd` schakelt het in naast de bestaande testinstellingen.
- Actieve normale wapens, munitie, munitiedozen, magazijnen en geselecteerde bouwmaterialen/gereedschappen krijgen dubbele doelen en minima boven op de ingestelde factoren: in de teststand 16× voor gewone en 48× voor militaire varianten.
- Deze voorraad en de actieve Expansion-bouwkits, safes en codesloten krijgen alle 17 Chernarus-locatiecategorieën en tiers 1–4. Expansion-doelen worden 2× de pakketwaarden.
- Planken en drie Expansion-lumberformaten krijgen testlootdoelen van 160/minimum 80. Overige crafted/uitgeschakelde items, geplaatste bouwwerken en speciale eventloot krijgen geen nieuwe spawnregels.
- Hoeveelheden zijn economiedoelen, geen garantie per gebouw. Categorieën, tags, geschikte posities en actieve locaties begrenzen de verdeling.
- Bestaande lokale instellingen, wachtwoorden en saves blijven behouden. Herhaald instellen stapelt de factoren niet; uitschakelen herstelt bronregels voor toekomstige spawns.
- Windows-testworkflow gebruikt het Windows PowerShell-modulepad; tests verwerken console-regelafbreking en korte Windows-tempmapnamen.

**Bijwerken:** stop de server en maak een wereldbackup. Vervang `scripts`, voer `04-Teststand.cmd` uit en start opnieuw. Behoud `config/server.local.json` en de wereldsave. De configuratie vóór de testknop wordt privé bewaard onder `.local/Backups`. Voor terugzetten: beide velden `TestSuppliesEverywhere` en `TestMilitaryEverywhere` op `false`, daarna `01-Instellen.cmd`; hoeveelheidsfactoren eventueel apart terugzetten. Bestaande loot wordt geleidelijk aangevuld; geen wipe nodig.

**Controle:** 22 pakkettests geslaagd met synthetische bestanden en 22 met officiële Chernarus-data, inclusief hoeveelheden, alle locatiecategorieën, herhaald instellen, terugzetten en behoud van saves/wachtwoorden. Werkelijke lootverdeling, lumber oprapen en bouwen, prestaties en herstartpersistentie moeten lokaal in DayZ worden gecontroleerd.

## [0.6.0] — 2026-10-27

### Militaire loot op meer plekken in de teststand

- De teststand voegt voor normale militaire loot steden, dorpen, industrie, boerderijen, politie- en jachtlocaties toe, plus Chernarus-tiers 1–4.
- Dit geldt voor 255 actieve, normale militaire itemtypen in de gecontroleerde Chernarus-data. Beschikbare spawnposities en itemtags blijven bepalen waar loot daadwerkelijk past.
- Uitgeschakelde, crafted en speciale eventloot behouden hun locatieregels.
- Nieuw veld `TestMilitaryEverywhere`; de gewone stand gebruikt `false`, `04-Teststand.cmd` zet dit op `true`.
- Uitschakelen en opnieuw instellen herstelt de oorspronkelijke locaties/tiers voor toekomstige spawns.
- De releasegeschiedenis is vastgelegd in deze changelog en GitHub Releases. Nieuwe versietags kunnen automatisch release notes publiceren.

**Bijwerken:** vervang `scripts` door de nieuwste versie, voer `04-Teststand.cmd` opnieuw uit en start de server. Bestaande loot wordt geleidelijk aangevuld/vervangen; een herstart vervangt niet alles direct.

**Controle:** 20 pakkettests geslaagd, plus de teststandcontrole met officiële Chernarus-data. De daadwerkelijke verdeling moet lokaal in-game worden beoordeeld.

Bronwijziging: [cfa9b25](https://github.com/henkdepotvis0180/Dayz-Servahz/commit/cfa9b25).

## [0.5.0] — 2026-10-27

### Drukkere wereld en ruime teststand

- 36 bots op 17 routes; maximaal 12 actieve groepen en 26 patrouillebots, afhankelijk van spelers in de buurt.
- Groepsbudgetten: maximaal 6 vijandige groepen, 4 groepen overlevenden en 2 groepen bewakers.
- Nieuwe routes bij Kamensk, Myshkino, Gorka en Novodmitrovsk. Respawninstelling naar 15 minuten.
- Nieuwe knop `04-Teststand.cmd`: gewone lootdoelen 8×, militaire lootdoelen 24×, nieuwe CE-loot met 0–10% beginschade.
- De gewone installer voegt bij ontbreken `LootDamageMax: 0.15` toe. Bestaande items worden niet gerepareerd.
- De testknop bewaart de vorige lokale configuratie onder `.local/Backups` en behoudt paden/wachtwoorden. Deze backups bevatten je wachtwoorden; bewaar ze privé.
- Geen wereldwipe. Testinstellingen blijven actief totdat je ze terugzet.

**Bijwerken:** vervang `scripts` en `config/mission`, voeg `04-Teststand.cmd` toe. Voer voor de ruimere loot `04-Teststand.cmd` uit en start opnieuw. Voor behoud van de bestaande hoeveelheidsfactoren gebruik je `01-Instellen.cmd`.

**Controle:** 20 pakkettests geslaagd, ook met officiële Chernarus-data. Routes, prestaties en loot blijven lokaal te controleren.

Bronwijziging: [a04202a](https://github.com/henkdepotvis0180/Dayz-Servahz/commit/a04202a).

## [0.4.0] — 2026-10-27

### Meer leven met gemengde AI

- 28 bots verdeeld over 13 routes; maximaal 7 actieve groepen en 16 patrouillebots.
- Mix van vijandige West/East-patrouilles, neutrale Civilian-overlevenden en Guards-bewakers.
- Extra activiteit bij Vybor, Novy Sobor, Cherno, Elektro, Berezino en Solnichniy.
- Overlevenden kunnen zich verdedigen; bewakers kunnen reageren op dreigend gedrag. Ze vormen geen gegarandeerde veilige zone.
- Zelf gespawnde adminbots vallen buiten de patrouillebudgetten.

**Bijwerken:** vervang `config/mission/expansion/settings/AIPatrolSettings.json`, voer `01-Instellen.cmd` uit en start opnieuw. Geen extra mods nodig.

**Controle:** 18 pakkettests geslaagd; factionregels en groepsbudgetten tegen Expansion gecontroleerd. Nieuwe routes nog lokaal te testen.

Bronwijziging: [3ffea31](https://github.com/henkdepotvis0180/Dayz-Servahz/commit/3ffea31).

## [0.3.2] — 2026-10-27

### Herstel laden van mods onder Windows PowerShell

- Een aangeleverd serverlog toonde dat alle modnamen als één ongeldige mapnaam aan DayZ werden doorgegeven.
- De modlijst wordt nu expliciet uitgepakt, zodat elke mod een eigen pad krijgt en paden met puntkomma's worden gescheiden.
- Regressietest voor het arraygedrag van Windows PowerShell 5.1 en controle van alle afzonderlijke startpaden.
- Afsluitinstructie verduidelijkt: in-game `#login` met je adminwachtwoord en daarna `#shutdown`.

**Bijwerken:** vervang `scripts`, voer `01-Instellen.cmd` uit en start opnieuw. Controleer daarna het nieuwste RPT en de launcher-modlijst.

**Controle:** 18 pakkettests geslaagd, inclusief nagebootst PowerShell 5.1-arraygedrag. De launcher herkende na de lokale update alle zeven mods afzonderlijk.

Bronwijziging: [27a7414](https://github.com/henkdepotvis0180/Dayz-Servahz/commit/27a7414).

## [0.3.1] — 2026-10-27

### In-game kaart en minimap

- DayZ-Expansion-Navigation toegevoegd als zevende mod, op server en clients vereist.
- `M` opent de kaart met jouw positie. `N` vasthouden toont/verbergt GPS/minimap; kort `N` wisselt de weergave.
- Geen fysiek kaart-, GPS- of kompasitem nodig. Persoonlijke markers en HUD-kompas ingeschakeld.
- Kaartinstellingen worden meegenomen in installatie, configuratiebackup en controles.

**Bijwerken:** abonneer je op Navigation en wacht op Steam. Vervang `scripts`, `config/mission`, `config/mods.json` en `Mods.html`. Voer `01-Instellen.cmd` uit en start opnieuw. Importeer het nieuwe `Mods.html` in de launcher; vrienden laden dezelfde zeven mods.

**Controle:** 17 pakkettests geslaagd. HUD en toetsbindingen moeten lokaal in-game worden gecontroleerd.

Bronwijziging: [d8fd903](https://github.com/henkdepotvis0180/Dayz-Servahz/commit/d8fd903).

## [0.3.0] — 2026-10-27

### Dichtere AI-ontmoetingen en meer militaire loot

- Minimale spawnafstand voor patrouilles van 250 naar 125 meter.
- Patrouilles joggen; detectielimieten voor dreigingen naar 450 meter en geluid naar 350 meter.
- Nieuw `MilitaryLootMultiplier: 2`, boven op 5× gewone loot: militaire lootdoelen worden standaard 10× vanilla.
- Oude lokale configuraties krijgen het nieuwe veld met behoud van paden en wachtwoorden.
- Militaire tiers, eventregels en oorspronkelijke locaties bleven in deze versie behouden.

**Bijwerken:** vervang `scripts` en `config/mission`, voer `01-Instellen.cmd` uit en start opnieuw.

**Controle:** 15 pakkettests geslaagd, ook met officiële Chernarus-data. Werkelijk AI-gedrag en loot lokaal te beoordelen.

Bronwijziging: [fdd4d5f](https://github.com/henkdepotvis0180/Dayz-Servahz/commit/fdd4d5f).

## [0.2.0] — 2026-10-27

### Steam-detectie met ontbrekende schijven hersteld

- Niet-bereikbare Steam-bibliotheken worden overgeslagen voordat paden worden opgebouwd.
- Oude opgeslagen paden worden opnieuw gezocht; een expliciet opgegeven onbereikbaar pad geeft een gerichte foutmelding.
- Regressiecontroles voor ontbrekende schijven en Steam-libraryverwijzingen toegevoegd.

**Bijwerken:** vervang `scripts` en voer `01-Instellen.cmd` opnieuw uit. Behoud `config/server.local.json`.

**Controle:** 14 pakkettests geslaagd.

Bronwijziging: [e9bdd16](https://github.com/henkdepotvis0180/Dayz-Servahz/commit/e9bdd16).

## [0.1.0] — 2026-10-27

### Eerste Windows-serverpakket

- Windows 10/11, Chernarus, 12 spelers en zes Workshop-mods: CF, Dabs Framework, Expansion Core, Licensed, AI en BaseBuilding.
- Installatie-, start- en controlescripts met Steam-detectie, eigen missie, modkopieën en publieke modsleutels.
- Zes vijandige patrouilles met samen 14 ingestelde bots; maximaal vier groepen tegelijk.
- 5× vanilla-lootdoelen, eigen Expansion-bouwloot en soepelere bouwregels. Bouwen kost nog materialen.
- Lokale configuratie met adminwachtwoord, configuratiebackups, wereldbackupscript en AI-adminhelper.
- Nederlandse handleiding met lokale verbinding, firewall en portforwarding. Modpreset in `Mods.html`.
- Windows PowerShell-testworkflow toegevoegd.

**Installeren:** installeer DayZ Server en de mods via Steam, voer `01-Instellen.cmd` uit en start met `02-Start-server.cmd`. Voor nieuwe installaties wordt de nieuwste release aanbevolen, inclusief latere fixes.

**Controle:** 12 pakkettests geslaagd, ook met officiële Chernarus-data. Dit waren pakkettests met testbestanden; de echte Windows-speltest was op dat moment nog niet uitgevoerd.

Bronwijziging: [4e1079c](https://github.com/henkdepotvis0180/Dayz-Servahz/commit/4e1079c).
