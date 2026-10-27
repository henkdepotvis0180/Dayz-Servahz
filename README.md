# Servahz — DayZ voor Windows, AI, 5× loot en makkelijk bouwen

**Updates:** [wijzigingen per versie](CHANGELOG.md) · [GitHub Releases en downloads](https://github.com/henkdepotvis0180/Dayz-Servahz/releases). De release notes vermelden wat je lokaal moet vervangen en welke controles zijn uitgevoerd.

Een lokaal serverpakket voor **Windows 10/11 + Chernarus**, met DayZ Expansion AI, BaseBuilding en Navigation, plus RaG BaseBuilding, Building Fortifications, MMG en Expansion Weapons. Installeer de officiele game/server en Workshop-mods via Steam, voer de installer uit en start de server. Gamebestanden en mods worden niet meegeleverd.

**Getest:** installatie met testbestanden, configuratiegeneratie, behoud van saves, opnieuw instellen zonder 25× loot, modupdates, backups en het queryprotocol. **Nog lokaal te testen:** de echte Windows-server starten, verbinden, AI-gedrag en bouwen. De Linux-cloudomgeving kan deze Windows/Steam-speltest niet uitvoeren.

## Eén compleet pakket (v0.11.0)

Deze ZIP bevat **alle wijzigingen uit 0.9.0 en 0.10.0, plus GoreZ**: barricades, MMG-rugzakken, Expansion-wapens met magazijnen/munitie, ruimere en sneller bijgevulde testloot, de bestaande RaG-bouwinstellingen en 43 ingestelde bots, én 75% minder stamina voor rechtop sprinten. Je hoeft geen oude ZIPs achtereenvolgens te installeren. Windstride en Survivor Missions zijn niet toegevoegd.

[GoreZ](https://steamcommunity.com/sharedfiles/filedetails/?id=1648967877) voegt bloedeffecten, bloedplassen/-sporen en vliegen bij lichamen toe. Host en alle spelers laden nu **dertien mods** uit `Mods.html`. Installeer **geen aparte BleedTrail** naast GoreZ; die functionaliteit zit al in GoreZ. De modbestanden zelf worden via Steam geleverd, niet in deze ZIP.

**Bestaande installatie in één keer bijwerken:**

1. Stop de server en maak een wereldbackup met `scripts/Backup-World.ps1`.
2. Pak deze ZIP apart uit. Vervang in je bestaande pakketmap `scripts`, `config/mission`, `config/profiles`, `config/mods.json`, `Mods.html` en `04-Teststand.cmd`. Behoud **`config/server.local.json`**, je servermissie en alle saves/profielen.
3. Abonneer host en spelers via `Mods.html` op alle ontbrekende mods, wacht op Steam en importeer de nieuwe preset. Kom je van vóór 0.9.0, dan zijn ook Building Fortifications, MMG en Expansion Weapons nieuw.
4. Voer **`04-Teststand.cmd`** uit. Deze past de complete configuratie toe, inclusief sneller bijvullen en de stamina-aanpassing. Start met **`02-Start-server.cmd`** en controleer met **`03-Controleren.cmd`**.

Geen wipe nodig. Pakkettests controleren installatie, modpaden, loot- en stamina-instellingen en behoud van saves/wachtwoorden. GoreZ-effecten, samenwerking met de huidige DayZ-versie en je andere mods, prestaties en herstartpersistentie moeten lokaal in-game worden gecontroleerd.

## Snel beginnen

1. Pak dit pakket volledig uit op je Windows-pc, bijvoorbeeld naar `C:\DayZ-Servahz`. Bewaar deze map: de knoppen gebruiken de lokale configuratie hierin.
2. Installeer **Steam → Bibliotheek → Tools → DayZ Server**, app-ID **223350**. De host en spelers hebben ook DayZ nodig. Start DayZ eenmaal om launcher en BattlEye te laten installeren.
3. Open **[Mods.html](Mods.html)**. Abonneer je op alle **dertien** mods en wacht tot Steam alle downloads heeft voltooid. Importeer dit bestand ook in de officiele DayZ Launcher via **Mods → Preset → Importeren**. Je vrienden gebruiken hetzelfde bestand.
4. Sluit een eventueel draaiende DayZ-server. Dubbelklik **`01-Instellen.cmd`**. De installer zoekt de Steam-bibliotheken en maakt `config/server.local.json` met jouw paden en een willekeurig adminwachtwoord.
5. Open `config/server.local.json` in Kladblok. Vul voor een prive-server `ServerPassword` in, sla op en voer **`01-Instellen.cmd`** nogmaals uit. Gebruik een ander wachtwoord dan `AdminPassword`. Dit lokale bestand wordt door Git genegeerd.
6. Dubbelklik **`02-Start-server.cmd`**. Laat het servervenster open en wacht enkele minuten. De eerste start maakt Expansion-profielen en de lootwereld aan. Voer **`03-Controleren.cmd`** uit voor configuratie- en querycontrole.
7. Open de DayZ Launcher met alle dertien mods. Kies **Servers → Direct connect**: **`127.0.0.1`, poort `2302`**. Een andere pc in hetzelfde thuisnetwerk gebruikt het LAN-IP van de host, bijvoorbeeld `192.168.1.50`.

Windows kan gedownloade scripts blokkeren. Gebruik zo nodig **Eigenschappen → Blokkering opheffen** op de ZIP en pak opnieuw uit. De `.cmd`-knoppen gebruiken alleen voor hun eigen PowerShell-proces `ExecutionPolicy Bypass`; ze veranderen geen permanente Windows-instelling. Instellen vereist normaal geen administratorrechten als de Steam-map beschrijfbaar is.

**Andere Steam-schijf of verkeerde automatische detectie?** Open PowerShell in de pakketmap:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-Server.ps1 -ServerPath "D:\SteamLibrary\steamapps\common\DayZServer" -WorkshopPath "D:\SteamLibrary\steamapps\workshop\content\221100"
```

`ServerPath` bevat `DayZServer_x64.exe`. `WorkshopPath` bevat de genummerde modmappen, niet `!Workshop` en niet de DayZ-gamemap. Steam kan game, server en Workshop over verschillende bibliotheken verdelen.

## Langer sprinten (v0.10.0)

Rechtop sprinten kost **75% minder stamina**, zonder extra mod. De installer zet alleen `PlayerData.StaminaData.sprintStaminaModifierErc` op `0.25` in de eigen `cfggameplay.json`. Dit maakt ook rechtop sprinten tijdens een gevecht goedkoper. Melee, ontwijken, springen/klimmen, adem inhouden, zwemmen, hurkend sprinten, regeneratie en gewicht houden hun bestaande instellingen. Een zware rugzak kan je maximale staminabalk dus nog steeds verkleinen.

Bijwerken: server stoppen, wereldbackup maken, `scripts` vervangen, **`04-Teststand.cmd`** uitvoeren en starten met **`02-Start-server.cmd`**. `01-Instellen.cmd` past dezelfde sprintaanpassing toe met behoud van je huidige lootinstellingen. Saves en wachtwoorden blijven staan. De aanpassing wordt bij iedere installatie opnieuw toegepast; voor herstel van normaal sprintverbruik zet je de waarde in `Set-EasyBuilding` in `scripts/Servahz.psm1` op `1.0` en voer je de installer opnieuw uit.

## Inhoud en spelregels

| Onderdeel | Instelling |
| --- | --- |
| Map / spelers | Chernarus, 12 slots, eerste en derde persoon |
| Lootconditie | Nieuw gespawnde CE-loot standaard 0–15% beginschade; teststand 0–10% |
| Loot | Vanilla `nominal` en `min` ×5; Military-loot extra ×2, dus standaard ×10 |
| AI | 17 routes, 43 bots verdeeld over de routes; maximaal 12 actieve groepen, hoogstens 31 patrouillebots |
| Moeilijkheid | Nauwkeurigheid 0,15–0,35, 65% uitgaande schade, normale gezondheid; bots zijn lootbaar |
| AI-spawning | Spelers circa 125–900 m van de patrouille; despawn buiten 1100 m |
| AI-benadering | Patrouilles joggen; dreigingen tot 450 m, geluidsonderzoek tot 350 m |
| AI-herhaling | Respawninstelling 15 minuten; despawnvertraging 5 minuten |
| Bouwen | Expansion-muren, vloeren, trappen, ramps, codesloten, safes; vanilla bouwen blijft mogelijk |
| Bouwgemak | Geen verplicht territory, soepelere plaatsingschecks, eenvoudige vlag en snapping |
| Bouwloot | Kits en codesloten in industrie/boerderijen, safes bij industrie/steden/militair |
| Kaart / minimap | M voor kaart; N vasthouden voor GPS/minimap, N kort voor modus; zonder items |
| Tijd | Dag 6× versneld, nacht extra 4× versneld |
| Integriteit | BattlEye standaard actief, `verifySignatures=2`, gelijke gamebuild verplicht |

De wereld heeft een mix van kleine vijandige patrouilles, neutrale overlevenden en bewakers:

| Soort | Gebieden | Ingesteld | Maximaal actief |
| --- | --- | --- | --- |
| Vijandig (`West`/`East`) | Balota, Zelenogorsk, Stary Sobor, NWAF, Tisy, Krasnostav airfield, Vybor, Novy Sobor, Kamensk, Myshkino | 10 groepen, samen 28 bots | 6 groepen, hoogstens 18 bots |
| Overlevenden (`Civilian`) | Chernogorsk, Elektrozavodsk, Berezino, Gorka, Novodmitrovsk | 5 groepen, samen 11 bots | 4 groepen, hoogstens 9 bots |
| Bewakers (`Guards`) | Berezino, Solnichniy | 2 groepen van 2 | 2 groepen, 4 bots |

Dit zijn **43 ingestelde bots**, maar hoogstens **31 gelijktijdig actieve patrouillebots** in twaalf groepen. Ze spawnen alleen nabij spelers, dus bij een solospeler zijn meestal minder groepen actief. Zelf via het adminmenu gespawnde bots tellen niet mee voor deze patrouillelimieten. Het budget is nu zes vijandige groepen, vier groepen overlevenden en twee groepen bewakers. Bij een host die ook de game draait kan dit merkbaar CPU kosten; verlaag bij haperingen eerst de aantallen in `LoadBalancingCategories`.

Overlevenden zijn normaal neutraal maar kunnen zichzelf verdedigen; bewakers kunnen agressief reageren als je wapens richt/heft of hen aanvalt. Bewakers zijn geen garantie op een veilige zone. West en East zijn verschillende vijandige factions en kunnen ook elkaar bevechten. De bestaande accuratesse en 65% uitgaande schade blijven behouden; de respawninstelling is 15 minuten. De groepen gebruiken de bijbehorende standaardloadouts die Expansion zelf aanmaakt.

Het zijn eigen beginroutes: loop ze lokaal na op obstakels; terrein, gevechten en zicht bepalen het daadwerkelijke gedrag. Waypoint-hoogte 0 wordt door Expansion op het terrein geplaatst. Voor deze uitbreiding zijn geen extra mods nodig: vervang met de server gestopt `config/mission/expansion/settings/AIPatrolSettings.json` in je pakketmap door de nieuwste versie, voer `01-Instellen.cmd` uit en start opnieuw. Je wereld hoeft hiervoor niet gewist te worden. De routes en ontmoetingen moeten daarna lokaal in-game worden gecontroleerd.

**5× loot is vijfmaal de economiedoelen, geen garantie op vijfmaal zoveel spullen per huis.** Spawnposities, tiers, events en CE-limieten blijven gelden. `nominal=0`, voertuigevents, zombies en dieren worden niet vervijfvoudigd. De eigen bouwloot heeft vaste aantallen in `building_types.xml`; `TestSuppliesEverywhere` verdubbelt de actieve pakketdoelen, los van de vanilla-factoren. Op bestaande werelden vult de economie geleidelijk bij; de installer verwijdert je wereld nooit om dit te versnellen.

**Meer militaire gear:** `MilitaryLootMultiplier` is standaard `2`, boven op `LootMultiplier: 5`. Elk actief itemtype met een `Military`-usage krijgt dus een doel/minimum van 10× vanilla, inclusief militaire wapens, munitie en kleding die zo zijn gemarkeerd. Items met meerdere usages krijgen dezelfde verhoging ook op hun overige bestaande locaties. In de gewone stand blijven tiers en speciale eventregels behouden. De teststand kan met `TestMilitaryEverywhere` normale militaire loot ook voor burgerlocaties/tier 1–4 toestaan; speciale eventloot blijft apart. Zet de extra factor op `1` voor gewone 5× loot. Oude lokale configuraties krijgen het nieuwe veld automatisch, met behoud van wachtwoorden en paden.

De AI-benadering werkt binnen de ingestelde patrouillegebieden. Afstanden zijn detectielimieten, geen garantie dat een bot je door muren ziet of direct naar je toe loopt. De bots worden niet overal op de kaart om je personage gespawnd.

Traders, geld, helicopters, quests en oneindige stamina zijn geen onderdeel van deze configuratie. Laad niet tegelijk de Expansion Bundle: die bevat dezelfde modules.

## Ruime teststand en beschadigde loot

Gebruik **`04-Teststand.cmd`** met de server gestopt om de lokale instellingen bewust om te zetten naar:

| Instelling | Teststand |
| --- | --- |
| `LootMultiplier` | 8: gewone lootdoelen 8× vanilla |
| `MilitaryLootMultiplier` | 3 extra: militaire lootdoelen totaal 24× vanilla |
| `LootDamageMax` | 0.10: nieuwe CE-loot met 0–10% beginschade |
| `TestMilitaryEverywhere` | true: normale militaire loot ook op burgerlocaties en tiers 1–4 |
| `TestSuppliesEverywhere` | true: extra wapens, munitie, magazijnen, MMG-rugzakken en bouwvoorraad op alle 17 locatiecategorieën en tiers 1–4 |
| `TestFastRestock` | true: dubbele bestaande lootcapaciteit per gebouw/container, sneller bijvullen en herstartaanvulling |

Deze knop voert de installer ook uit. Daarna kun je meteen `02-Start-server.cmd` gebruiken. Hij bewaart vooraf de lokale configuratie onder `.local/Backups/server-before-testmode-*.json`. Paden, wachtwoorden en overige instellingen blijven behouden. Het resultaat blijft ingesteld totdat je de lokale waarden terugzet; het is geen tijdelijke schakelaar. Terugzetten: stop de server, kopieer de gewenste configuratiebackup naar `config/server.local.json` en voer `01-Instellen.cmd` uit. Configuratiebackups bevatten wachtwoorden: houd ze prive.

**Update van een bestaande installatie:** kopieer de nieuwste map `scripts`, de nieuwe knop `04-Teststand.cmd` en de nieuwste `config/mission` uit de ZIP naar je bestaande pakketmap. Behoud je eigen `config/server.local.json`. Met `04-Teststand.cmd` kies je daarna de ruimere loot; alleen `01-Instellen.cmd` behoudt je huidige hoeveelheidsfactoren. De nieuwe AI-routes komen uit `config/mission`.

De gewone installer gebruikt standaard `LootDamageMax: 0.15` als het veld nog ontbreekt. De schade-instelling wijzigt alleen `LootDamageMin`/`LootDamageMax` in de eigen missie `db/globals.xml`; andere globals en de Steam-standaardmissie blijven behouden. Dit betreft loot die de Central Economy nieuw spawnt, niet ieder item uit een zombie, AI-loadout of speciaal eventscript. Botuitrusting kan bovendien in een vuurgevecht beschadigd raken.

**Militaire loot op meer plekken:** de nieuwe teststand voegt voor actieve, normale Military-itemtypen de usages `Town`, `Village`, `Industrial`, `Farm`, `Police` en `Hunting` en tiers `Tier1` t/m `Tier4` toe. Daardoor kunnen bijvoorbeeld normale militaire wapens en kleding ook bij burgergebouwen in lagere tiers verschijnen. Dit is een uitbreiding van mogelijke spawnplekken, geen vaste kans per huis of garantie op een geweer in iedere kamer. Bestaande itemcategorieen, tags en beschikbare proxies bepalen waar een item echt past. `nominal=0`, crafted loot en `deloot=1`-eventloot krijgen deze locatie-uitbreiding niet.

**Extra testvoorraad (v0.7.0):** `TestSuppliesEverywhere` verdubbelt boven op de huidige factoren de doelen/minima van actieve normale wapens (CE-categorie `weapons`), losse munitie, munitiedozen, magazijnen en geselecteerde bouwvoorraad. Gewone wapens/munitie worden in de teststand zo 16× en militaire varianten 48× vanilla. Spijkerdozen, metaalplaten, draad, prikkeldraad, touw, ducttape, bouwgereedschap en codesloten vallen hieronder. De eigen Expansion-bouwkits, safes en codesloten krijgen 2× hun pakketdoelen. Planken en elk van de drie Expansion-lumberformaten krijgen als expliciete testuitzondering een doel van 160 en minimum van 80, met vloerposities als mogelijke spawnplek. Boomstammen, geplaatste bouwwerken, overige crafted items, uitgeschakelde wapens en speciale eventloot worden niet als gewone testloot aangezet.

Deze voorraad krijgt alle 17 usages die de gecontroleerde Chernarus-data gebruikt: `Coast`, `ContaminatedArea`, `Farm`, `Firefighter`, `Historical`, `Hunting`, `Industrial`, `Lunapark`, `Medic`, `Military`, `Office`, `Police`, `Prison`, `School`, `SeasonalEvent`, `Town` en `Village`. Dit omvat ook medische gebouwen, brandweer, kantoren, scholen, gevangenis, kust en pretpark. Bestaande categorieën en tags blijven gelden; alleen planken/lumber krijgen zo nodig `tools` en `floor`. Werkelijke spawns hangen af van beschikbare geschikte posities, actieve locaties en CE-limieten. Er worden geen eventlocaties of extra wapentypen door scripts aangemaakt. De hoge testdoelen kunnen meer serverbelasting geven.

Na een update moet je **`04-Teststand.cmd` opnieuw uitvoeren** om het nieuwe veld aan te zetten. Oude lokale configuraties krijgen `TestSuppliesEverywhere: false` als het ontbreekt; alleen `01-Instellen.cmd` schakelt de uitbreiding dus niet vanzelf in. Zet **beide** velden `TestSuppliesEverywhere` en `TestMilitaryEverywhere` op `false` en voer `01-Instellen.cmd` uit om de originele locaties/tiers en de gewone pakketbouwloot te herstellen voor toekomstige spawns. Andere lootfactoren blijven dan op hun huidige waarden. Laat je lokale configuratie staan bij het vervangen van de map `scripts` uit de nieuwste ZIP.

**Bestaande beschadigde loot wordt niet gerepareerd.** Een herstart wist de economie niet. Met `TestFastRestock` vraagt de server ook aanvulling bij een herstart; anders werken de instellingen tijdens het geleidelijk bijvullen; de wereld hoeft niet te worden verwijderd. De hoeveelheid vrije lootposities, tiers en eventvoorwaarden blijft de feitelijke aantallen begrenzen, ook bij 24×. In de gewone stand blijven militaire locaties nodig; met `TestMilitaryEverywhere: true` kunnen normale militaire items ook op de toegevoegde burgerlocaties verschijnen. Het zichtbare serverlabel kan nog '5x Loot' bevatten: de werkelijke factoren staan in `config/server.local.json` en worden door de installer getoond; pas `Hostname` desgewenst aan.

## Meer zichtbare loot en drie extra mods (v0.9.0)

**Voor jouw ruime teststand: voer na het bijwerken `04-Teststand.cmd` opnieuw uit.** Alleen de nieuwe bestanden kopiëren schakelt het nieuwe veld `TestFastRestock` niet in. Je huidige saves en wachtwoorden blijven behouden. De hoeveelheid loot in je bestaande wereld is hier niet rechtstreeks gemeten; onderstaande wijzigingen nemen bekende CE-beperkingen weg, maar geven geen garantie op een item in iedere kamer.

De nieuwe [Building Fortifications](https://steamcommunity.com/sharedfiles/filedetails/?id=2670506982), [MMG – Mightys Military Gear](https://steamcommunity.com/sharedfiles/filedetails/?id=2663169692) en [Expansion Weapons](https://steamcommunity.com/sharedfiles/filedetails/?id=2792985069) staan in `Mods.html`. Host en alle spelers laden nu **dertien mods**. CF, Dabs Framework en Expansion Core waren al aanwezig. Geen modcode of gamebestanden worden meegeleverd.

**Nieuwe lootselectie:**

| Voorraad | Gewone pakketdoelen per type | Teststand per type |
| --- | --- | --- |
| 13 vuurwapens | doel 60 / minimum 45 | doel 120 / minimum 90 |
| 7 Expansion-magazijnen | doel 120 / minimum 90 | doel 240 / minimum 180 |
| 3 losse munitietypen en 3 munitiedozen | doel 100 / minimum 80 | doel 200 / minimum 160 |
| 7 vizieren/railadapters | doel 30 / minimum 20 | doel 60 / minimum 40 |
| 9 MMG-rugzakvarianten | doel 75 / minimum 60 | doel 150 / minimum 120 |
| 4 barricadekits | doel 40 / minimum 32 | doel 80 / minimum 64 |

Dit zijn vaste pakketdoelen in `servahz_ce/extra_types.xml`, geen extra vermenigvuldiging met `LootMultiplier`. `TestSuppliesEverywhere` verdubbelt deze doelen en opent alle 17 usages/tier 1–4. Wapen- en itemcategorieën, tags en echte lootposities blijven gelden. De teststand heeft daarnaast nog de bestaande vanilla-, RaG- en Expansion-bouwloot.

Wapens: **M9, G36, MPX, MP5, MP5SD, MP7, Kedr, Vityaz, M16, DT11, Benelli M4, AWM en Kar98**. De zeven aparte Expansion-magazijnen staan in de loot; MP5 en M16 gebruiken ook vanilla-magazijnen die al in de economie zitten. De 10 wapens met losse magazijnen hebben **80% kans op een passend magazijn** bij nieuwe CE-spawns. Losse munitie en magazijnen hebben een ingestelde hoeveelheid van 80–100%; munitiedozen blijven gewone dozen. Dit is geen garantie op een volledig geladen wapen. Er zijn geen RPG's, LAW's of granaatwerpers aan de gewone pakketloot toegevoegd.

Rugzakken: zwarte **Assault Pack, Carrier Backpack, Camelback, Supplybag en MMPS**, plus groene en tan Supplybag/MMPS. Volgens de MMG-beschrijving lopen deze modellen van 80 tot 150 slots. Andere MMG-kleding en pantser worden met de mod geladen, maar zijn niet in deze gerichte lootselectie opgenomen.

Barricades: **kleine en middelgrote raamkit, deurkit en dubbele deurkit**. Plaats de juiste kit bij een bestaand raam of deur en voeg de materialen toe die de bouwactie vraagt. Building Fortifications behoudt zijn eigen standaardbouwkosten; de eenvoudige RaG-kosten gelden hier niet. De vier geplaatste barricadeklassen hebben `nominal=0`, `crafted=1` en een CE-levensduur van 45 dagen. Dat is geen onbeperkte levensduur of raidbescherming; onderhoud en herstartpersistentie lokaal controleren.

**Waarom hogere aantallen niet altijd volle huizen geven:** vroeger wijzigde de teststand vooral doelen en locaties. Gebouwcapaciteit, bijvulbudgetten, wachttijden en afstand tot spelers bleven beperkt. Het nieuwe `TestFastRestock: true` doet daarnaast:

- Verdubbelt positieve `lootmax`-waarden uit de Steam-standaardmissie in de eigen `mapgroupproto.xml`. Nul blijft nul; posities, tags en categorieën worden niet gewijzigd. Meer capaciteit maakt geen nieuwe fysieke posities.
- Zet `RestartSpawn=50`: vraagt bij een herstart aanvulling richting de nominale doelen (50% volgens de Bohemia-configuratiereferentie), met behoud van de bestaande opgeslagen wereld.
- Zet `RespawnTypes=30`, `RespawnLimit=50` en `RespawnAttempt=4`, zodat meer typen/items per ronde kunnen worden bijgevuld.
- Verkleint `LootSpawnAvoidance` van de Chernarus-standaard 100 naar **50 meter**. Loop bij een leeg gebouw meer dan 50 meter weg en kom later terug; naast het lootpunt blijven staan kan het spawnen blokkeren.
- Zet `restock=0` voor actieve, gewone vanilla-loot: geen extra wachttijd per type. Crafted en speciale eventloot behouden hun regels.

**Update:** stop de server en maak een wereldbackup. Abonneer host en spelers op de drie nieuwe mods, wacht op Steam en vervang `scripts`, `config/mission`, `config/profiles`, `config/mods.json` en `Mods.html`. Behoud `config/server.local.json`, je missie en saves. Voer **`04-Teststand.cmd`** uit, importeer de nieuwe preset, start met `02-Start-server.cmd` en laat de server laden. Een wereldwipe is niet nodig. Starten/bijvullen kan meer CPU en tijd kosten.

`03-Controleren.cmd` controleert dat de nieuwe CE-bestanden zijn gekoppeld en dat de snelle bijvulwaarden zijn toegepast. In de console moet de extra modloot als **46 itemtypen** worden geteld. Controleer bij ontbrekende items ook het nieuwste RPT op onbekende klassen of modfouten; pakkettests starten geen echte DayZ-server.

**Terugzetten:** server stoppen, `TestFastRestock` op `false` zetten en `01-Instellen.cmd` uitvoeren. De vijf bijvulglobals, normale `restock`-waarden en gebouwcapaciteit worden dan uit de Steam-standaardmissie hersteld; andere globals blijven staan. `LootMultiplier`, andere testvelden en reeds bestaande loot blijven behouden. Zet voor herstel van de originele locaties ook `TestMilitaryEverywhere` en `TestSuppliesEverywhere` uit. De installer leest telkens de standaardmissie: herhaald instellen stapelt de capaciteitsfactor niet. `mapgroupproto.xml` is nu een beheerd bestand; bewerk de Steam-standaardmissie niet.

Bronnen: [Bohemia CE-configuratie](https://community.bistudio.com/wiki/DayZ:Central_Economy_Configuration), [officiële Expansion CE-data](https://github.com/ExpansionModTeam/DayZ-Expansion-Missions/tree/248dd215738550bff9cc3b5a0c84c5e895074712/Template/Chernarus/expansion_ce), [MMG-klassennamen in de community-marktconfiguratie van Expansion](https://github.com/ExpansionModTeam/DayZ-Expansion-Unofficial-Market-Settings/blob/fdf7815b1a97f9ae717e2022199102af8c3945c7/Market/MMG%20Gear/MMG_Gear.json) en [de oorspronkelijke barricadeconfiguratie](https://github.com/Dumpgrah/Public-BuildingFortification/blob/c14eee2927eb3f387ed95166fdf846cece07782a/BuildingFortifications/scripts/config.cpp). Modbestanden worden via Steam geladen; controleer daadwerkelijk spawnen, compatibiliteit en performance in-game.

## Kaart en minimap

[DayZ-Expansion-Navigation](https://steamcommunity.com/sharedfiles/filedetails/?id=2792984722) is de zevende mod, vereist op server en clients. De afhankelijkheden CF, Dabs Framework en Expansion Core waren al aanwezig.

- **M** opent de grote Expansion-kaart met je eigen positie.
- **Houd N ingedrukt** om de GPS/minimap rechtsonder te tonen of verbergen. **Druk kort op N** om tussen kaart- en GPS-informatie te wisselen.
- Een fysiek kaart-, GPS- of kompasitem is niet vereist. Persoonlijke markers en het HUD-kompas zijn ingeschakeld.
- Controleer bij toetsconflicten **Options → Controls → Expansion**. Bestaande client-keybindings kunnen afwijken van de standaard.
- Groepsgenoten en bots worden niet automatisch op de kaart getoond; deze configuratie levert geen groepsmod of radar.

**Bestaande installatie bijwerken:** stop de server, abonneer je op Navigation en wacht op Steam. Kopieer uit de nieuwste pakketversie de mappen `scripts` en `config/mission`, plus `config/mods.json` en `Mods.html`, naar je bestaande pakketmap. Behoud `config/server.local.json`. Voer `01-Instellen.cmd` uit en start opnieuw. Importeer de nieuwe `Mods.html` in de clientlauncher; ook vrienden laden alle dertien mods. Dit vergt geen wereldwipe. Controleer lokaal M en N na het inloggen; pakkettests bewijzen geen werkende in-game HUD.

## Makkelijker bouwen met RaG (v0.8.0)

**Nieuw:** [RaG_Core](https://steamcommunity.com/sharedfiles/filedetails/?id=3556131153) en [RaG_BaseBuilding](https://steamcommunity.com/sharedfiles/filedetails/?id=3157695626). Server en alle spelers laden nu **dertien mods** uit `Mods.html`. Expansion blijft aanwezig voor je bestaande gebouwen, codesloten, safes en andere functies. Er wordt geen modcode meegeleverd: abonneer je via Steam.

**Update:** stop de server en maak een wereldbackup. Abonneer je op beide RaG-mods en wacht op Steam. Vervang `scripts`, `config/mission`, `config/profiles`, `config/mods.json` en `Mods.html` in je pakketmap. Behoud `config/server.local.json`, je missie en saves. Voer `01-Instellen.cmd` uit (of `04-Teststand.cmd` voor testloot), importeer de nieuwe preset en start opnieuw. Geen wipe nodig.

Zo bouw je met de meegeleverde RaG-startinstellingen:

1. Zaag hout tot **planken**. Combineer **2 planken + 1 losse spijker** en kies bijvoorbeeld een RaG-muur-, vloer-, deur- of trapkit. Maak een spijkerdoos open voor losse spijkers. Kits en het herbruikbare `RaG_BB_Book` zijn ook als loot toegevoegd; de teststand verspreidt ze over alle 17 locatiecategorieën.
2. Neem de kit in je handen en plaats hem. **Pijl omlaag** wisselt snapping, **pijl rechts** wisselt aansluitpunten; **pijl omhoog** laat je bij een snap-punt roteren. Gebruik **Page Up/Down** voor hoogte. Controleer eventuele andere keybindings onder RaG BaseBuilding.
3. Voeg **2 planken per houten bouwstap** toe, neem een **hamer of hatchet** en voer de bouwactie uit. Een deur kan eerst een frame en daarna een deur vereisen: iedere stap kost opnieuw 2 planken. Geen spijkers, boomstammen of metaal voor houten bouwstappen; de optionele metalen deur kost 1 metaalplaat. Een stap duurt circa 5 seconden.
4. Gebruik een **vanilla drie- of viercijferig combinatieslot** op een afgebouwde geschikte deur/poort. Het Expansion-codeslot werkt niet automatisch op RaG-delen; een aparte compatibiliteitsmod is niet onderdeel van dit pakket.

Dit is eenvoudiger bouwen, maar **geen hout-en-ragsrecept**: de kit vraagt nog één spijker. De standaard RaG-materialen zijn via JSON instelbaar; rags als receptingrediënt vraagt maatwerk. RaG verandert de bouwkosten van bestaande Expansion-delen niet.

De installer maakt bij ontbreken `Servahz/Profiles/RaG_Core/Configs/RaG_BaseBuilding/RaG_BaseBuilding.json` uit `config/profiles` aan. **Een bestaand RaG-profiel wordt behouden**, dus eigen kosten, onbekende velden en instellingen blijven staan. Pas bij een bestaande RaG-installatie de live profielwaarden bewust aan met de server gestopt; alleen het bronbestand vervangen verandert dat profiel niet. De configbackup bewaart het bestaande RaG-profiel; de wereldbackup bewaart alle profielen en saves. Verander `Version` niet. Bouwschade en dismantling blijven mogelijk: dit is geen raidbescherming.

[RaG-configuratie en kosten](https://tyson89.github.io/RaG-Mod-Wikis/mods/basebuilding/server-configuration/) en [installatie/compatibiliteit](https://tyson89.github.io/RaG-Mod-Wikis/mods/basebuilding/server-setup/) zijn als bron gebruikt. Lokaal controleren: kit craften, plaatsen, hout toevoegen, bouwen, slot bedienen en persistentie na herstart. Controleer ook of routes en de extra bots soepel draaien.

## Bouwen met de bestaande Expansion-delen

- **Stok + touw**: blader door recepten voor bouwkits; kits zijn ook als loot beschikbaar.
- Plaats een kit en wissel snapping met **X**. Bouw met **hamer/bijl, planken, spijkers en lumber**. Lumber zaag je uit boomstammen met een handzaag of ijzerzaag.
- Bouw na het muurframe verder naar muur, deur of poort. Bevestig een Expansion-codeslot; de code is vier cijfers.
- Optioneel territory: **3 stokken + touw** voor een vlaggenkit. De mast wordt eenvoudig opgebouwd. Houd je vlag bij: onderhoud en verval blijven bestaan.
- Bouwen kost nog materialen. Buiten territories kunnen anderen met gereedschap demonteren. Binnen territories is demontage door buitenstaanders geblokkeerd; schade en raiding zijn hiermee niet automatisch uitgeschakeld.

## Vrienden en portforwarding

Test eerst op de host, daarna met een tweede pc in je LAN, daarna van buitenaf.

1. Geef de host een vast LAN-IP met een **DHCP-reservering** in je router.
2. Zet je vertrouwde thuisnetwerk in Windows op **Particulier**. Open PowerShell **als administrator** in de pakketmap:

   ```powershell
   # Alleen thuisnetwerk:
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Set-Firewall.ps1 -Mode LAN
   # Internetvrienden, na instellen en toepassen van ServerPassword:
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Set-Firewall.ps1 -Mode Friends
   ```

3. Forward handmatig in de router naar het LAN-IP van de host:

   | Protocol | Buiten → binnen | Gebruik |
   | --- | --- | --- |
   | UDP | 2302–2305 → 2302–2305 | Game en gereserveerde naburige gamepoorten |
   | UDP | 27016 → 27016 | Steam-serverquery |

   Dit zijn de standaardpoorten. Het pakket reserveert `GamePort` t/m `GamePort+3`; pas bij andere poorten ook de routerregels aan. Er is geen TCP- of RCon-forward nodig. Het firewallscript wijzigt alleen zijn eigen `DayZ-Servahz-UDP`-regel, nooit de router.

4. Vrienden importeren `Mods.html`, laden de dertien mods en verbinden met **jouw publieke IPv4-adres**, gamepoort **2302** en het serverwachtwoord. De host gebruikt zelf het LAN-adres of `127.0.0.1`.
5. Laat iemand buiten je LAN testen: sommige routers ondersteunen geen NAT-loopback. Een TCP-poortchecker test deze UDP-server niet.

LAN werkt, internet niet? Vergelijk het WAN-adres van je router met je publieke IPv4. **CGNAT**, bijvoorbeeld een WAN-adres in `100.64.0.0/10`, of dubbele NAT kan inkomende verbindingen blokkeren. Vraag je provider om publiek IPv4 of configureer beide routers/bridge mode. Een mesh-VPN zoals Tailscale is een alternatief; host en vrienden moeten dat zelf installeren, dit pakket configureert het niet.

De Friends-firewallregel accepteert gameverkeer van alle bronadressen, uitsluitend op het particuliere netwerkprofiel. Deel je serverwachtwoord alleen met vrienden. Verwijderen:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Set-Firewall.ps1 -Remove
```

## Aanpassen en bijwerken

**Stop normaal via de in-game chat:** verstuur `#login jouwAdminPassword` (gebruik de lokale waarde van `AdminPassword`) en daarna `#shutdown`. Wacht tot het serverproces weg is. Instellen en backups weigeren zolang een `DayZServer_x64`-proces draait. Gebruik dit pakket niet gelijktijdig met een andere serverinstantie.

Pas bronbestanden hieronder aan en voer `01-Instellen.cmd` opnieuw uit:

| Bestand | Aanpassing |
| --- | --- |
| `config/server.local.json` | Naam, wachtwoorden, slots, paden, poorten, `LootMultiplier`, `MilitaryLootMultiplier`, `LootDamageMax`, `TestMilitaryEverywhere`, `TestSuppliesEverywhere`, `TestFastRestock` en tijd |
| `config/mission/expansion/settings/AIPatrolSettings.json` | Bots, routes, faction, accuratesse, afstanden en groepsbudget |
| `config/mission/expansion/settings/BaseBuildingSettings.json` | Bouwregels, territories en codesloten |
| `config/mission/expansion/settings/MapSettings.json` | Kaart, minimap, positie, markers en vereiste items |
| `config/mission/servahz_ce/building_types.xml` | Bouwloot en levensduur gebouwde onderdelen |
| `config/mission/servahz_ce/extra_types.xml` | Nieuwe wapens, magazijnen, munitie, rugzakken en barricadekits |
| `config/mission/servahz_ce/extra_spawnabletypes.xml` | Passende magazijnen bij nieuwe wapenspawns |
| `config/profiles/RaG_Core/Configs/RaG_BaseBuilding/RaG_BaseBuilding.json` | RaG-startinstellingen; alleen gekopieerd als het live profiel ontbreekt |

De installer vervangt de beheerde doelconfiguraties. Directe wijzigingen daarin verdwijnen bij opnieuw instellen: wijzig de bronbestanden hierboven. Overige Expansion-profielinstellingen blijven behouden. Verander `m_Version` niet zelf: dit zijn schema-versies.

**Update:** maak een wereldbackup, laat Steam server en mods volledig bijwerken, voer de installer opnieuw uit en herstart. Vrienden werken dezelfde mods bij. Eigen modkopieen worden volledig vervangen zodat oude PBO's verdwijnen. De standaardmissie blijft onaangeraakt. De eigen missie wordt niet volledig ververst: bij DayZ-updates die andere missiebestanden veranderen moet je die na backup bewust vergelijken en bijwerken. Deze installer migreert wereldsaves niet automatisch.

## Wereldbackup

Met de server gestopt:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Backup-World.ps1 -Destination "D:\DayZ-Backups\voor-update-2026-10-27"
```

Kies een nieuwe map buiten de missie/runtime. Dit bewaart de missie inclusief `storage_1` (wereld/spelers), Expansion-profielen en configuratie. De backup bevat je wachtwoorden: bewaar hem prive, liefst ook op een andere schijf. Automatische installatiebackups bevatten **alleen beheerde configuraties**, niet de wereld.

**Terugzetten:** stop de server; bewaar huidige bestanden apart. Zet `mission` uit de backup terug als `mpmissions\servahz.chernarusplus`, `Profiles` als `Servahz\Profiles`, `serverDZ.cfg` als `Servahz\serverDZ.cfg` en `server.local.json` in de pakketmap `config`. Controleer paden en game/modversies. Een configbackup alleen herstelt geen spelerswereld.

## AI-admin en diagnose

Na de eerste serverstart zijn de Expansion-profielen en loadouts aangemaakt. Stop de server en voeg eventueel je 17-cijferige SteamID64 toe:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Set-AIAdmin.ps1 -SteamId64 JOUW_17_CIJFERIGE_STEAMID64
```

Vervang de placeholder door je ID en herstart. Het AI-menu gebruikt standaard **T**; controleer de DayZ-toetsinstellingen. Dit geeft AI-beheer, geen volledige algemene admin-tool. Het oorspronkelijke `AISettings.json` wordt geback-upt.

Logs: `<DayZServer>\Servahz\Profiles`, vooral de nieuwste `.RPT`, `script*.log` en `crash*.log`. Deel geen lokale config met wachtwoorden.

| Probleem | Controle |
| --- | --- |
| Ontbrekende PBO, verkeerde versie/signature | Alle dertien mods bijwerken; opnieuw instellen; geen Bundle erbij laden |
| Launcher toont modnamen als een gecombineerde regel | Gebruik de nieuwste scripts; Windows PowerShell 5.1 gaf eerder een geneste modlijst door. In het RPT moeten modpaden met puntkomma's gescheiden zijn, met voor elke mod zijn eigen pad |
| `Unknown type ViewController` | Dabs Framework ontbreekt, is oud of wordt niet geladen |
| Installer vindt mods niet | Downloads afwachten; juiste Workshop-map onder app `221100` gebruiken |
| Oude Steam-schijf ontbreekt | De installer slaat onbereikbare Steam-bibliotheken over. Controleer bij een expliciet pad `ServerPath`/`WorkshopPath` of de schijf is aangesloten |
| Querycontrole faalt | Server laten laden; querypoort en logs controleren; eerst lokaal proberen |
| Query werkt, verbinden niet | Gamepoort, clientmods, BattlEye en gamebuild controleren |
| Geen bots | Nader een patrouillegebied vanaf meer dan 125 m en wacht; controleer loadouts en logs |
| JSON-fout | Bronconfig repareren, opnieuw instellen; versievelden niet willekeurig aanpassen |
| Hoge CPU/RAM-belasting | Minder actieve AI, lagere lootfactor en/of minder spelers |

Begin voor een kleine groep met een recente CPU, SSD en ongeveer **16 GB RAM in de host-pc**; meer als je op dezelfde pc speelt. Werkelijk gebruik hangt af van bots, loot, bases en spelers.

## Lokale acceptatiecontrole

- `03-Controleren.cmd` slaagt: configuratie/modbestanden kloppen en de verwachte servernaam antwoordt op A2S_INFO. Dat bewijst nog geen speelbaarheid.
- Je kunt met alle dertien mods inloggen, bewegen en loot oprapen.
- AI verschijnt bij Balota/Stary/NWAF; bewegen, vechten en looten werken. Controleer routes op obstakels.
- **M** toont de kaart met je positie; **N vasthouden** toont GPS/minimap en kort N wisselt modus.
- Een Expansion-kit plaatsen, bouwen en een codeslot gebruiken werkt.
- Een RaG-kit maken met 2 planken + 1 spijker; iedere houten bouwstap kost 2 planken. Plaatsen, afbouwen en een vanilla combinatieslot werken, ook na herstart.
- Stop normaal, herstart en controleer personage, inventaris en gebouw.
- Een vriend buiten je LAN kan verbinden en spelen.

## Bestanden en onderhoudstests

```text
<DayZServer>/
  DayZServer_x64.exe                    # van Steam
  keys/                                # publieke modhandtekeningsleutels
  mpmissions/servahz.chernarusplus/      # eigen missie en storage_1
  Servahz/
    .servahz-managed
    serverDZ.cfg                       # lokaal gegenereerd, bevat wachtwoorden
    Mods/                              # eigen Workshop-modkopieen
    Profiles/                          # logs, instellingen en AI-loadouts
    Backups/                           # automatische configuratiebackups
```

Onderhoudstests vereisen Python 3.10+ en PowerShell. Vanuit de repository:

```powershell
python -m unittest discover -s tests -v
```

Op Linux kan `SERVAHZ_PWSH` naar PowerShell 7 wijzen. Zonder PowerShell worden integratietests expliciet overgeslagen. `SERVAHZ_VANILLA_MISSION` kan naar een standaard-Chernarus-missie wijzen om volledige CE-data te controleren. Tests gebruiken tijdelijke mappen en nep-PBO's/nep-executable en starten geen DayZ. Een lokale testresponder controleert A2S. Windows Steam-detectie, firewall, processtart en echte clients vereisen de lokale acceptatiecontrole.

## Bronnen

- [Expansion-wiki](https://github.com/salutesh/DayZ-Expansion-Scripts/wiki) en jouw [Steam-installatiegids](https://steamcommunity.com/sharedfiles/filedetails/?id=2430317812).
- [AI-patrouilles](https://github.com/salutesh/DayZ-Expansion-Scripts/wiki/%5BServer-Hosting%5D-How-to-create-AI-Patrols), [bouwinstellingen](https://github.com/salutesh/DayZ-Expansion-Scripts/wiki/%5BServer-Hosting%5D-BaseBuildingSettings) en [bouwrecepten](https://github.com/salutesh/DayZ-Expansion-Scripts/wiki/Basebuilding-Guide).
- Schema's gecontroleerd tegen de stabiele Expansion `release`, commit `0d26645ca31bc574bc3ebee1d4bc9192727f3c43` (1.9.80). Standaardloadouts worden door de geinstalleerde mod aangemaakt.
- [Expansion-missievoorbeelden](https://github.com/ExpansionModTeam/DayZ-Expansion-Missions) en [Bohemia Central Economy](https://github.com/BohemiaInteractive/DayZ-Central-Economy) zijn geraadpleegd voor CE, classnames en gameplay. De installer gebruikt jouw eigen Steam-standaardmissie.
- Workshop-ID's en afhankelijkheden staan in [config/mods.json](config/mods.json) en [Mods.html](Mods.html).

Dit is een onafhankelijk serverpakket. Download de game en mods via Steam en respecteer de licenties van DayZ en Expansion.
