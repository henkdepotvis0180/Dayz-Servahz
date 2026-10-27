# Wijzigingen per versie

Elke versie beschrijft het pakket op dat moment. Instellingen in latere versies kunnen eerdere waarden vervangen. De datums hieronder zijn lokale datums voor Nederland.

**Bestaande installatie:** stop de server en behoud `config/server.local.json` en je wereldsave. Maak een wereldbackup voordat je bijwerkt. De hieronder genoemde bestanden vervang je in de uitgepakte pakketmap, naast `01-Instellen.cmd`.

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
