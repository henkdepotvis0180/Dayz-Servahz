# Servahz — DayZ voor Windows, AI, 5× loot en makkelijk bouwen

**Updates:** [wijzigingen per versie](CHANGELOG.md) · [GitHub Releases en downloads](https://github.com/henkdepotvis0180/Dayz-Servahz/releases). De release notes vermelden wat je lokaal moet vervangen en welke controles zijn uitgevoerd.

## Downloaden: eerst de basis, daarna jouw updateversie

**Nieuwe installatie:** download eenmalig [basispakket 0.13.0 (Windows-ZIP)](https://github.com/henkdepotvis0180/Dayz-Servahz/releases/download/v0.13.0/Dayz-Servahz-v0.13.0-Windows.zip), pak het uit en voer `01-Instellen.cmd` uit. Dit is de vaste basis, inclusief de mods tot en met SNAFU. Heb je 0.13.0 al, dan hoef je die niet opnieuw te downloaden.

**Bijwerken vanaf 0.13.0:** kies op [GitHub Releases](https://github.com/henkdepotvis0180/Dayz-Servahz/releases) de gewenste versie vanaf **0.14.0**. Download onder **Assets** alleen **`Servahz-Update-vX.Y.Z.cmd`**. Iedere nieuwe release levert dat ene bestand, geen nieuw volledig Windows-pakket. De automatisch door GitHub getoonde “Source code”-archieven zijn niet nodig.

1. Stop de DayZ-server. Download eventuele nieuwe Workshop-mods die in de release staan op host en clients.
2. Zet het updatescript in je bestaande pakketmap, naast `01-Instellen.cmd`, en dubbelklik erop. Staat het ergens anders, dan vraagt het om die pakketmap.
3. Het script controleert de basis, eigen bestandswijzigingen en vereiste moddownloads, maakt automatisch een wereld-/profiel-/configuratiebackup en een backup van te vervangen pakketbestanden, past de gewijzigde bestanden toe en voert instellen plus de statische controle uit.
4. Importeer na een modwijziging de bijgewerkte `Mods.html` bij host en vrienden. Start met `02-Start-server.cmd`.

Saves, wachtwoorden, eigen serverpaden, testloot en de keuze voor snelle bijvulling blijven behouden. Er wordt geen teststand aangezet. Backups staan in `.local/Backups/update-vX.Y.Z-...`; deze bevatten lokale wachtwoorden, dus houd ze privé. Het script downloadt geen mods en start de server niet automatisch.

**Versies kiezen:** elke update bevat de wijzigingen van 0.13.0 tot de gekozen versie. Je kunt tussenliggende updates overslaan. Vereisten en eerdere wijzigingen tot die versie komen dus mee; dit is een keuze van updateversie. Downgraden wordt geblokkeerd. Een opnieuw gestart, al geslaagd script meldt dat de update al is toegepast. Vanaf 0.16.1 worden officiële bestanden per bestand herkend, ook bij een mix van versies na handmatig bijwerken. Windows-regeleinden en een UTF-8-BOM zijn toegestaan. Echte eigen wijzigingen in beheerde scripts/configuraties worden vooraf geweigerd; lokale instellingen en live profielen mag je wel aanpassen. Oude documentatie blokkeert de update niet en wordt vóór vervanging geback-upt.

**Als instellen of controleren mislukt:** start de server nog niet. Los de gemelde fout op en start het updatescript opnieuw. Zijn alle pakketbestanden al vervangen, dan probeert het instellen opnieuw. Vanaf 0.16.1 kun je een gedeeltelijke update met herkenbare officiële bestanden opnieuw starten. Ontbrekende bestanden uit de payload worden opnieuw geplaatst; bij onbekende wijzigingen blijft herstel nodig vanuit de genoemde backup; voor herstel van de wereld bevat `world` de missie, profielen en configuratie. De updater claimt geen automatische terugdraaiing van de live serverconfiguratie.

**Melding “Geen ongewijzigd ondersteund basispakket gevonden”?** Gebruik de nieuwere updater **0.16.2** in dezelfde bestaande pakketmap. Die accepteert gemengde officiële bestanden en normale tekstverschillen tussen Windows en Unix. Je hoeft 0.16.0 niet eerst te installeren. Bij echte verschillen toont hij bijvoorbeeld `Onbekende inhoud: scripts/...` of `Ontbreekt: config/...` en schrijft hij een lijst onder `.local/UpdateDiagnostics`. Alleen de bestandsnamen en redenen worden opgeslagen; stuur geen lokale wachtwoorden of configuratie-inhoud mee. Een ontbrekend ongewijzigd basisbestand wordt niet uit de delta gereconstrueerd en eigen functionele wijzigingen worden niet geforceerd vervangen.

**Blokkade op `config/server.example.json`:** gebruik updater **0.16.2**. Het voorbeeld is alleen voor de eerste installatie; je actieve instellingen staan in `config/server.local.json`. Zodra die actieve instellingen geldig zijn, mag het voorbeeld afwijken of ontbreken. De updater laat een bestaand voorbeeld ongewijzigd, ook als het eigen waarden bevat. Je hoeft niets te hernoemen, te vervangen of te uploaden; beide configuratiebestanden blijven lokaal.

Vanaf een oudere versie dan 0.13.0 werk je eerst bij met het volledige basispakket volgens de 0.13.0-instructies hieronder. Kies daarbij `01-Instellen.cmd` om je huidige lootinstellingen te behouden.

## Een RaG-deur verdwijnt of het combinatieslot reageert verkeerd (v0.18.1)

Gebruik [update 0.18.1](https://github.com/henkdepotvis0180/Dayz-Servahz/releases/tag/v0.18.1) om **`07-Bouwdiagnose.cmd`** toe te voegen. Dit is een diagnosehulpmiddel, geen bevestigde slotreparatie of herstel van een verdwenen deur. Stop de server en voer het ene updatescript uit naast `01-Instellen.cmd`; de bestaande updater maakt eerst een wereld-/profielbackup. Daarna kun je 07 uitvoeren met de server nog gestopt. Het verzamelen van de diagnose vereist geen serverstart, teststand of lootverversing.

De knop leest de actieve numerieke RaG-bouwinstellingen en deurkosten, vergelijkt de twee RaG-modkopieën op de server met de lokale Workshop-download, toont wereldopslag-/backupmetadata en zoekt naar relevante fout-/bouwmeldingen in recente logstaarten. **GELIJK** bij een mod betekent gelijke lokale PBO-inhoud, niet automatisch de nieuwste Steam-versie of dezelfde clientbestanden. Bij **WIJKT AF** of **ONVOLLEDIG**: houd de server gestopt, laat Steam de twee RaG-mods voltooien/repareren en voer 01 opnieuw uit. Ook spelers moeten dezelfde actuele mods laden. Dit is een herstelstap voor een afwijkende kopie, geen garantie dat daarmee iedere slotfout is opgelost.

07 schrijft uitsluitend **`.local/BuildDiagnostics/<datum-tijd>.txt`** in de pakketmap en toont de samenvatting op het scherm. De wereld, lokale serverinstellingen, profielen en bronlogs blijven ongewijzigd. Alleen vaste categorieën, tijden en toegestane publieke klasse-/functienamen worden uit logs overgenomen; volledige logregels, gebruikersgegevens, slotcodes en privéconfiguratie worden niet afgedrukt. Deel alleen dit diagnoserapport. Het programma ontleedt geen wereldsave en kan dus niet bewijzen dat een specifieke deur is verwijderd of nog aanwezig is. Logsignalen zijn aanwijzingen, geen automatische oorzaakvaststelling.

Het ontbreken van aparte CE-lootregels voor geplaatste RaG-delen is **geen bewezen opschoonfout**. De [RaG-installatiedocumentatie](https://tyson89.github.io/RaG-Mod-Wikis/mods/basebuilding/server-setup/) adviseert kits/het boek en waarschuwt tegen het toevoegen van de geplaatste implementatieklassen aan `types.xml`. Volgens de [RaG-configuratiedocumentatie](https://tyson89.github.io/RaG-Mod-Wikis/mods/basebuilding/server-configuration/) zet `BaseInfiniteLifetime=1` de levensduur na opslag laden op 45 dagen. Die instelling voorkomt niet iedere verwijdering en herstelt geen verdwenen object. Deze update verandert haar niet.

Bij verlies van bouwdelen: stop normaal en bewaar eerst een aparte actuele wereld-/profielbackup met `scripts/Backup-World.ps1` volgens de backupinstructies hieronder. De diagnose toont alleen of oudere wereldbackupmappen aanwezig zijn, niet of zij jouw deur bevatten of volledig herstelbaar zijn. Een volledige oude wereld terugzetten kan recente bouw- en spelersvoortgang vervangen; er wordt hier niets automatisch teruggezet. Controleer met het lokale rapport en de in-game situatie voordat een herstelkeuze wordt gemaakt.

## Opslag controleren terwijl de server draait (v0.18.3)

Als geplaatste muren/deuren verdwijnen en de wereldbestanden in 07 een oude schrijftijd hebben, controleer dan eerst of de draaiende server dezelfde installatie, missie en opslag gebruikt. Een oude map alleen bewijst geen opschoonfout. DayZ ondersteunt andere configuratie-, missie- en opslagpaden in de [startparameters](https://community.bohemia.net/wiki/DayZ:Server_Configuration).

**Zonder de bestaande server te stoppen:** download [08-Opslagdiagnose.cmd](https://raw.githubusercontent.com/henkdepotvis0180/Dayz-Servahz/v0.18.3/08-Opslagdiagnose.cmd), sla het bestand met extensie `.cmd` op naast 01 en dubbelklik. Vervang een oudere losse 08 met dit bestand. Dit is een zelfstandige leescontrole; installatie van een update, 01 of een herstart is niet nodig. Laat de server met zijn bestaande startopdracht draaien om juist die te onderzoeken. Deel alleen **`.local/StorageDiagnostics/<datum-tijd>.txt`**. Als de server al gestopt is, kan de controle ook gestopt worden uitgevoerd; herstart hem niet uitsluitend voor dit rapport zonder eerst de actuele wereld veilig te stellen. Geen teststand of lootverversing gebruiken.

08 vergelijkt de executable, absolute config-/profielpaden en poort van de draaiende Windows-processen met het pakket. Toont ook overrides voor missie/opslag, meerdere processen, geselecteerde numerieke configvelden, opslagmetadata en privacyveilige categorieën voor mogelijke opslagfouten. Relatieve of onleesbare procespaden blijven **ONBEKEND**; de werkmap wordt niet gegokt. Een recente map is niet automatisch de actieve wereld, een gelijke startselectie bewijst geen geslaagde opslag, en huidige configtekst kan na de serverstart zijn gewijzigd. De controle ontleedt geen saves en doet geen schrijftest onder het serveraccount.

08 controleert ook de XML en koppeling naar `servahz_ce/building_types.xml`, geselecteerde RaG-kit-levensduren, opslagvlaggen in **`db/economy.xml`** en bouw-/`cheatCheck`-regels in `cfgIgnoreList.xml`. Versie 0.18.2 zocht het economiebestand abusievelijk buiten `db`; zijn melding "economy.xml ontbreekt of ongeldig" bewees dus geen serverfout. Het officiële pad staat in de [Bohemia-documentatie](https://community.bohemia.net/wiki/DayZ:Central_Economy_setup_for_custom_terrains). Opslagmeldingen bevatten vaste trefwoorden en toegestane standaard CE-bestandsnamen; `recover` of `restore` alleen bewijst geen corruptie. Het oude [door Bohemia bevestigde cheatCheck-probleem](https://feedback.bistudio.com/T189577) is een reden om de aanwezige ignorelijst te controleren; dit bewijst niet dat die op jouw huidige server fout staat. Voeg geen RaG-implementatieklassen of regels aan de ignorelijst toe als algemene verdwijnreparatie.

Alleen het eigen rapport wordt geschreven. Geen wereldherstel, instance-wissel, save-/profiel-/modwijziging of herstart. 08 zit ook in [update 0.18.3](https://github.com/henkdepotvis0180/Dayz-Servahz/releases/tag/v0.18.3); voor gewoon bijwerken gelden de normale stop-/backupstappen. Dat bijwerken is voor deze losse diagnose niet nodig. Geen losse extra release-asset: de release houdt het ene cumulatieve updatescript.

## Voorraadkisten zonder sleutels en meer MMG-vakjes (v0.18.0)

Download [update 0.18.0](https://github.com/henkdepotvis0180/Dayz-Servahz/releases/tag/v0.18.0). Deze bevat ook alle wijzigingen tot en met 0.17.0; tussenliggende versies hoef je niet apart uit te voeren.

1. Abonneer **host en alle spelers** op [MMG – Half Mega Inventory Size](https://steamcommunity.com/sharedfiles/filedetails/?id=2895332994) en [CJ187-LootChest](https://steamcommunity.com/sharedfiles/filedetails/?id=2345073965). Wacht totdat Steam beide volledig heeft gedownload. CF en MMG zelf zaten al in het pakket.
2. Stop de server en voer alleen `Servahz-Update-v0.18.0.cmd` uit naast `01-Instellen.cmd`. De updater controleert de downloads, maakt een backup en voert instellen/controleren uit. Je hoeft 04, 05 of 06 niet te starten.
3. Importeer de bijgewerkte `Mods.html` in de DayZ Launcher bij host en spelers: nu **17 mods**. Start met `02-Start-server.cmd`.
4. `03-Controleren.cmd` toont **CJ187 0.18**, het ingestelde aantal sleutelvrije kisten en het pad naar **`Servahz/Profiles/CJ_LootChests/Servahz-Lootkisten.csv`** onder je DayZ Server-map. Open die lijst in Kladblok of Excel: X en Z zijn de kaartcoördinaten. Hiermee kun je direct een voorraadpunt opzoeken.

**Wat zit erin?** Kisten met meerdere rollen uit voedsel-/drank-/medische-/tool-/bouwtabellen. Elke kist bevat voedsel en drank; militaire/politiekisten krijgen daarnaast één geselecteerd modwapen met bijpassend magazijn en passende losse munitie. De wapens wisselen tussen de bestaande gecontroleerde Expansion-/SNAFU-sets, zodat niet elke kist hetzelfde geweer krijgt. Geen kleding, sleutels, keycards of lege verpakkingen in deze tabellen. `keyclass` is leeg en `openable` staat op 2: gewoon openen, zonder sleutel, lockpick of breekgereedschap. Kisten krijgen hun inhoud bij een serverstart; volgens de CJ187-mod vullen geopende kisten niet tussendoor opnieuw.

**Waar staan ze?** Bij de eerste installatie worden bestaande vloerpunten van de lokale Steam-missie gebruikt, met minimaal 1 meter vrije spawnstraal en 1 meter hoogte, één gekozen gebouw per vak van 850 meter en minstens 350 meter tussen kisten. Gekantelde gebouwen worden overgeslagen. Winkels/horeca, medische en militaire/politieplekken krijgen voorrang, daarna werkplaatsen/schuren en huizen. Geen zelf verzonnen terreinhoogtes of gekopieerde privé-basecoördinaten. Maximaal 256 kisten. Een bestaande privé-basecirkel uit de lootverversing wordt bij deze eerste generatie overgeslagen; die privé-instellingen blijven ongewijzigd. Met de gecontroleerde officiële Chernarus-data zijn het **195** (84 Food, 74 Building, 26 Weapons, 6 Medical, 5 General). Jouw Steam-data kan een ander aantal geven. De fysieke plaatsing, bereikbaarheid en inhoud moeten nog in-game worden gecontroleerd.

**Meer dragen:** de Half Mega-uitbreiding vergroot bestaande MMG-rugzakken volgens de maker naar 250–500 vakjes en de ondersteunde MMG-shirts/broeken naar 250–300. De bestaande negen geselecteerde MMG-rugzakvarianten blijven vindbaar via dezelfde lootregels. Er worden geen extra kledingtypen of hogere kledingdoelen toegevoegd. Vanilla-kleding krijgt door deze mod geen extra vakjes; BetterVanillaClothing is niet toegevoegd.

**Behoud:** geen wipe, lootopruiming of herhaalde 05/06-actie. Bestaande saves, wachtwoorden, testinstellingen, basecirkel en losse spullen blijven behouden. De kisten hebben eigen CE-records met doel/minimum 0: alleen CJ187 plaatst ze, niet de gewone economie als lege kisten. Het native profiel **`Profiles/CJ_LootChests/LootChests_V106.json`** wordt één keer aangemaakt; daarna blijft het byte voor byte behouden en wordt het geback-upt. Een bestaand ongeldig of vergrendeld profiel wordt gemeld en niet vervangen. De CSV is een afgeleide locatielijst en wordt bij instellen opnieuw uit dat profiel gemaakt. Eigen kistposities/voorraad pas je in het native profiel aan; `config/loot-chests.json` is alleen het sjabloon voor de eerste generatie. Gebruik de voorraadkisten als lootbron, niet als eigen baseopslag.

**Controle in-game:** open een kist zonder hulpmiddelen, controleer voedsel en de juiste wapen/magazijn/munitie-combinatie, bekijk een ondersteunde MMG-rugzak en controleer na een normale serverherstart dat er geen dubbele kisten ontstaan. Dit pakket test de configuratie en updater; het bevat geen DayZ-engine- of mod-PBO-test. Modbestanden blijven via Steam gedownload; ze worden niet herverpakt. Bronnen: de hierboven gelinkte makerspagina’s, CJ187's V106-profielindeling en de lokale officiële `mapgrouppos.xml`/`mapgroupproto.xml`.

## Meer eten en minder herhaling (v0.17.0)

Gebruik [update 0.17.0](https://github.com/henkdepotvis0180/Dayz-Servahz/releases/tag/v0.17.0) als eten ondanks 0.15/0.16 schaars bleef. Stop de server, voer het ene updatescript uit en start weer. De bestaande lootverversing wordt niet opnieuw gestart en je base/opslag wordt niet opgeruimd.

- **Schappen voor eten:** de bestaande voedselschappen in winkels, horeca en huizen accepteren voortaan alleen voedsel. Tools/kleding/boeken kunnen er bij nieuwe spawns niet meer tussen komen. Voedsel mag ook op vloerplekken liggen. Er worden geen nieuwe coördinaten verzonnen.
- **Extra ruimte:** deze gebouwen krijgen waar bestaande punten dat toelaten maximaal 12 extra lootruimte in winkels/horeca of 3 in huizen, met een ruimere schaplimiet. Daardoor hoeft extra eten niet uitsluitend te wachten tot alle oude items verlopen. Dit garandeert nog geen eten in ieder gebouw.
- **Meer voorraad:** de 27 gekozen voedsel-/dranktypen gaan van 3× naar 8× bovenop je huidige lootfactor, met minimum 90% en restock 0. BakedBeansCan wordt bij de standaard 5× loot doel 600/minimum 540; bij 8× testloot doel 960/minimum 864.
- **Minder overdaad van dezelfde voorraad:** gewone munitie/magazijnen maximaal 90 doelen per type, of 180 met testvoorraad, maar met 80–100% inhoud bij losse spawns. Gewone vanilla-guns maximaal 12/24 per type. De 21 modwapens blijven op 30/60; er zijn geen extra mods of nieuwe wapentypen toegevoegd. Event-/crafted-/uitgeschakelde loot wordt niet als gewone loot aangezet.

Met officiële Chernarus-data en de testinstellingen veranderen de voedsel-/drankdoelen van **12.624 naar 33.664** en de munitie-/magazijndoelen van **65.024 naar 19.140**. Het totale beheerde lootdoel daalt van **276.940 naar 234.652**. Dit zijn doelen voor objecten/stapels op de hele kaart, geen daadwerkelijke aantallen of losse patronen. De verdeling verandert sterker zonder het totale itemdoel verder te vergroten.

`03-Controleren.cmd` moet **Lootbalans 0.17** tonen, met jouw gegenereerde doelen voor eten/drinken, munitie/magazijnen en wapens. De aantallen hangen van je lokale loot-/testinstellingen en Steam-missieversie af. Eventuele relevante RPT-waarschuwingen tonen alleen modklassennamen; daarmee kan ontbrekende modloot gericht worden onderzocht zonder volledige logs te delen.

Bestaande spullen blijven bestaan. Nieuwe voedselplekken worden geleidelijk gevuld; hogere doelen zijn geen bevestiging dat de engine alle doelen al heeft gehaald. Controleer verse winkels/huizen en geef bij aanhoudende problemen de nieuwe controle-uitvoer door. De oudere getallen en schappenindeling hieronder beschrijven hun eigen versies; deze sectie vervangt ze voor 0.17.0.

## Loot opnieuw verdelen met bescherming voor je base (v0.16.0)

Deze optionele actie ververst geselecteerde losse wapens, magazijnen, munitie en houdbare voeding buiten een beschermde cirkel. **De update installeren wist niets.** Alle doelitems binnen de cirkel worden overgeslagen, ongeacht hoogte of wie ze heeft neergelegd. Opslag (ook in attachments), baseonderdelen, voertuigen en inventarissen worden overal overgeslagen. De nieuwe lootbalans uit 0.15.0 zit ook in deze update.

1. Installeer de gewenste update vanaf basis 0.13.0. Stop de DayZ-server normaal.
2. Dubbelklik **`05-Loot-proefscan.cmd`**. Vul de basepositie in als `X Z`, in meters, gescheiden door een spatie. De cirkel heeft standaard 500 meter straal. Je coördinaten blijven lokaal in `.local/loot-refresh-settings.json` en de aanvraag/rapportage in je serverprofielen; ze worden niet op GitHub gepubliceerd.
3. Start met `02-Start-server.cmd`. **Laat iedereen uitgelogd.** De scan begint na twee minuten en loopt in kleine stappen; grote lootwerelden kunnen langer nodig hebben. Gebruik `03-Controleren.cmd` voor de voortgang.
4. Wacht op **`PreviewCompleted`** en **0 verwijderd**. Controleer de weergegeven X/Z, straal en voorbeelden van kandidaten buiten de cirkel. Het volledige rapport met maximaal 50 voorbeelden staat onder `<DayZServer>/Servahz/Profiles/Servahz/LootRefresh-report.json`.
5. Stop de server normaal. Dubbelklik **`06-Loot-verversen.cmd`**. Deze vereist de afgeronde proefscan met dezelfde selectie en cirkel en maakt opnieuw een volledige wereldbackup. Start de server weer en laat iedereen uitgelogd tot `03-Controleren.cmd` **`ApplyCompleted`** toont.

**Reikwijdte:** ook zelf gedropte doelitems buiten de cirkel kunnen verdwijnen. Binnen de cirkel raakt deze actie geen items aan. De normale DayZ-vervaltijd van losliggende spullen blijft echter gelden; bewaar belangrijke bouwvoorraad in opslag. De scanner werkt op door de server vindbare objecten. De economie vult vrijgekomen plekken vervolgens volgens de huidige balans; niet ieder gebouw is onmiddellijk opnieuw gevuld.

De aanvraag wordt vóór de eerste scan eenmalig vastgelegd. Een herstart voert dezelfde aanvraag niet nogmaals uit, ook niet na een onderbreking. Bij een verbonden speler stopt de scan. Voor een nieuwe poging begin je opnieuw met een proefscan. Verder installeren of toekomstige updates activeren de actie niet opnieuw.

**Backup en uitschakelen:** vóór elke ingeplande scan/uitvoering komt een wereld-/profiel-/configuratiebackup onder `.local/Backups/loot-refresh-...`. Deze bevat privéwachtwoorden. Stop de server en voer `05-Loot-proefscan.cmd -Disable` uit om de hook en de aanvraag te verwijderen, ook als de server door een scriptfout niet start. Dat herstelt geen verwijderde items; daarvoor heb je de wereldbackup nodig. Verwijder nooit `storage_1` om alleen loot te verversen.

De DayZ-missiecode kan hier niet in de echte game-engine worden uitgevoerd of gecompileerd. Daarom is de lokale proefscan verplicht voordat de uitvoering kan worden ingepland. Er zijn geen nieuwe Workshop-mods of clientupdates nodig. API-bron: [Bohemia GetObjectsAtPosition](https://github.com/BohemiaInteractive/DayZ-Script-Diff/blob/main/scripts/3_game/global/game.c) en [JsonFileLoader](https://github.com/BohemiaInteractive/DayZ-Script-Diff/blob/main/scripts/3_game/tools/jsonfileloader.c).

## Lootbalans (v0.15.0)

De nieuwste update maakt wapenloot bruikbaarder en voegt meer eten in winkels en huizen toe. **Geen nieuwe mods nodig.** Stop de server en gebruik [de gewenste update op GitHub](https://github.com/henkdepotvis0180/Dayz-Servahz/releases); vanaf basis 0.13.0 kun je direct naar 0.15.0.

- **Minder herhaling:** alle 21 modwapens doel 30/minimum 24, in testvoorraad 60/48. De vijf uitschieters worden verlaagd. Gewone actieve vanilla-vuurwapens hebben een maximum van 30 per type, of 60 met `TestSuppliesEverywhere`; eventloot en uitgeschakelde klassen worden niet aangezet.
- **Passende voorraad:** de 18 wapens met losse magazijnen krijgen 95% magazijnkans. Vijftien losse modmagazijnen doel 60/minimum 48, in testvoorraad 120/96. Bijbehorende munitie/magazijnen komen in dezelfde locatiecategorieën en tiers als hun wapen, met minstens tweemaal het individuele wapendoel en 80–100% hoeveelheid bij losse spawns. Dit garandeert geen complete set in ieder huis of een geladen wapen.
- **Meer voedsel:** 27 bestaande houdbare voedsel-/dranktypen krijgen 3× hun huidige doelen/minima en ook Town/Village, tiers 1–4. Bijvoorbeeld BakedBeansCan: bij de standaard 5× loot doel 225, bij 8× testloot 360. Uitgeschakeld, geopend, rauw en speciaal eventvoedsel wordt niet aangezet.
- **Voedselplekken:** winkels/horeca krijgen maximaal zes bestaande schapposities alleen voor eten; huizen maximaal twee. Andere spullen kunnen deze plekken niet innemen. De totale gebouwcapaciteit en de echte coördinaten blijven gelijk; kleine of volle gebouwen hoeven niet direct eten te bevatten.

De selectie van bijpassende klassen staat in `config/loot-balance.json`. Deze tabel helpt de belangrijkste SNAFU-wapens herkennen:

| Wapen | Geselecteerd magazijn | Losse munitie |
| --- | --- | --- |
| SCAR-H Black | Snafu_ScarH_25RND_Mag_BK | Ammo_308Win (.308 Winchester) |
| SR-25 | SNAFU_SR25_Mag | Ammo_308Win (.308 Winchester) |
| M110 Black | GCGN_M110_Mag | Ammo_308Win (.308 Winchester) |
| HK416 | GCGN_HK416_Mag | Ammo_556x45 (5.56×45) |
| M24 | SNAFUM24_Mag | SNAFU_Ammo_338 (.338) |
| T5000 | SNAFUT5000_Mag | SNAFU_Ammo_338 (.338) |
| Honey Badger Black | SNAFUHoneyBadger_30rdMag_Black | SNAFU_Ammo_300ACC (.300 AAC) |
| Vector .45 ACP | SNAFUVECTOR_45acp_Mag | Ammo_45ACP (.45 ACP) |

De eerdere losse `GCGN_Ammo_762x51` wordt niet meer gespawnd. SNAFU .338 en .300 AAC krijgen elk doel 100/minimum 80, in testvoorraad 200/160. De klasse blijft met doel 0 in de CE-configuratie staan; je bestaande spullen worden niet verwijderd. Er staan nog 67 extra CE-klassen geregistreerd, waarvan 66 actief.

Bronnen: de [SNAFU-compatibiliteitsinventaris](https://gist.github.com/KrisSeanMac/0b15c8463b8907d6e8691c469c976c08) noemt de ondersteunde munitie en magazijnen per klasse; voor Expansion onder andere de [Kedr-configuratie (.380)](https://github.com/salutesh/DayZ-Expansion-Scripts/blob/experimental/DayZExpansion/Objects/Weapons/Firearms/SMG/P99/config.cpp). Controleer de actuele Workshop-versies lokaal door te laden/schieten. De pakkettests starten geen echte DayZ-server.

**Bestaande wereld:** bestaande loot wordt niet gewist of direct omgezet. Laat de economie nieuwe items spawnen/bijvullen en beoordeel ook verse locaties. Bots, stamina, wachtwoorden, saves en je huidige test-/bijvulinstellingen blijven behouden. De oudere tabellen en updatebeschrijvingen hieronder beschrijven hun oorspronkelijke versies; bovenstaande balans vervangt de oude aantallen.

Een lokaal serverpakket voor **Windows 10/11 + Chernarus**, met DayZ Expansion AI, BaseBuilding en Navigation, plus RaG BaseBuilding, Building Fortifications, MMG en Expansion Weapons. Installeer de officiele game/server en Workshop-mods via Steam, voer de installer uit en start de server. Gamebestanden en mods worden niet meegeleverd.

**Getest:** installatie met testbestanden, configuratiegeneratie, behoud van saves, opnieuw instellen zonder 25× loot, modupdates, backups en het queryprotocol. **Nog lokaal te testen:** de echte Windows-server starten, verbinden, AI-gedrag en bouwen. De Linux-cloudomgeving kan deze Windows/Steam-speltest niet uitvoeren.

## SNAFU nu inbegrepen (v0.13.0)

[SNAFU Weapons](https://steamcommunity.com/sharedfiles/filedetails/?id=2443122116) is nu onderdeel van het complete pakket: **vijftien mods** op host en alle clients. Je Steam-abonnement downloadt de bestanden; de nieuwe modlijst, preset én lootregels hieronder zorgen voor de serverintegratie. De ZIP bevat alle voorgaande updates, inclusief GoreZ en BaseBuildingItemStackandRepair.

De lootselectie bevat acht SNAFU-wapens: **SCAR-H Black, HK416, SR-25, M110 Black, M24, T5000, Honey Badger Black en Vector .45 ACP**. Inclusief acht passende magazijnen, twee SNAFU-vizieren en drie extra losse munitietypen (`GCGN_Ammo_762x51`, `SNAFU_Ammo_338`, `SNAFU_Ammo_300ACC`). Voor 5.56 en .45 ACP blijft de bestaande vanilla-munitie beschikbaar. Geen volledige import van alle camo's, .50-wapens of machinegeweren.

Per nieuw SNAFU-wapen, magazijn en munitietype: doel **30**, minimum **24**; met `TestSuppliesEverywhere` doel **60**, minimum **48**, op alle 17 locatiecategorieën/tier 1–4. De twee vizieren krijgen elk doel 10/minimum 8, in de teststand 20/16. Alle acht wapens hebben bij nieuwe CE-spawns 80% kans op een passend magazijn. Hoeveelheden van nieuwe munitie/magazijnen staan op 80–100%. De werkelijke compatibiliteit van deze koppelingen moet nog in-game worden gecontroleerd.

**Begrensd wapenbudget:** de doelen van acht Expansion-wapens (M9, G36, MPX, MP5, MP5SD, Kedr, Vityaz en M16) gaan van 60 naar 30 per type. Daarmee blijft het totale pakketdoel voor vuurwapens **780 normaal / 1560 in de teststand**, nu verdeeld over 21 in plaats van 13 typen. De nieuwe magazijnen en munitie voegen samen 330 normale doelen / 660 testdoelen toe; de vizieren voegen nog 20 / 40 toe. Vanilla-loot, rugzakken, barricades, bots, stamina en de keuze voor snelle herstartaanvulling veranderen niet. Bestaande wapens worden niet uit je inventaris of wereld verwijderd; de economie past toekomstige spawns aan.

**Bijwerken:** stop de server en maak een wereldbackup. Vervang `scripts`, `config/mission`, `config/mods.json` en `Mods.html` in je bestaande pakketmap. Behoud `config/server.local.json`, profielen en saves. Host en alle spelers abonneren op SNAFU en wachten op Steam; importeer de nieuwe preset. Voer **`01-Instellen.cmd`** uit om jouw huidige loot-/testinstellingen te behouden en start met `02-Start-server.cmd`. `04-Teststand.cmd` alleen gebruiken als je bewust opnieuw alle testinstellingen, inclusief snelle herstartaanvulling, wilt aanzetten. `03-Controleren.cmd` moet nu **67 extra itemtypen** tonen.

Klassennamen zijn vergeleken met de [SNAFU-communityconfiguraties bij Expansion](https://github.com/ExpansionModTeam/DayZ-Expansion-Unofficial-Market-Settings/tree/main/Market/Snafu) en de [SNAFU-wapenconfiguratie](https://github.com/Speedou94/DayZ-ExpansionTrader-Snafu). Dit zijn brongegevens voor de selectie, geen garantie voor elke Workshop-versie. Controleer de echte guns, magazijnen en munitie lokaal en bekijk het RPT bij onbekende klassen. Geen modcode wordt herverdeeld.

## Bouwmaterialen stapelen (v0.12.0)

[BaseBuildingItemStackandRepair](https://steamcommunity.com/sharedfiles/filedetails/?id=1896597833) staat als onderdeel van de modlijst in `Mods.html`, vereist op host en alle clients. De maker beschrijft stapels van 20 boomstammen, 20 brandhout, 50 planken, 50 metaalplaten, 250 spijkers, 80 korte stokken en 20 lange stokken. Het is een stapel-/reparatiemod, geen rugdraagframe: sprinten met boomstammen wordt hiermee niet gegarandeerd mogelijk. Expansion-lumber is niet expliciet onderdeel van de gedocumenteerde vanilla-stapels.

**Belangrijk bij gebruik:** splits boomstammen vóór je ze aan een bouwkit toevoegt. De maker waarschuwt dat een volledige stapel anders kan worden verbruikt. Gereedschap kan ook stapelen; splits het vóór gebruik om schade aan de hele stapel te voorkomen. Test ook afzonderlijk met RaG- en Expansion-bouwdelen.

De mod verandert daarnaast reparaties: ducttape kan volgens de maker alle items repareren en heeft meer inhoud; epoxy kan onder andere bouwgereedschap repareren. Dat is inbegrepen gedrag van deze mod, geen eigen pakketinstelling.

**Alleen deze update toepassen:** stop de server, maak een wereldbackup en vervang `config/mods.json` en `Mods.html` in je bestaande pakketmap. Abonneer host en spelers op de nieuwe mod, wacht op Steam en importeer de preset. Voer **`01-Instellen.cmd`** uit om je huidige loot-/testinstellingen te behouden en start daarna met `02-Start-server.cmd`. De nieuwe ZIP bevat ook alle vorige updates; vanaf een oudere versie volg je daarnaast de complete bijwerkinstructies hieronder. Behoud je lokale configuratie en saves. Building Backpack is niet toegevoegd.

Pakkettests controleren de veertien modpaden, preset, sleutels en behoud van bestaande instellingen/saves. De echte stapel-, reparatie- en bouwinteracties en herstartpersistentie moeten lokaal op de huidige DayZ-versie worden getest.

## Eén compleet pakket (v0.11.0)

Deze ZIP bevat **alle wijzigingen uit 0.9.0 en 0.10.0, plus GoreZ**: barricades, MMG-rugzakken, Expansion-wapens met magazijnen/munitie, ruimere en sneller bijgevulde testloot, de bestaande RaG-bouwinstellingen en 43 ingestelde bots, én 75% minder stamina voor rechtop sprinten. Je hoeft geen oude ZIPs achtereenvolgens te installeren. Windstride en Survivor Missions zijn niet toegevoegd.

[GoreZ](https://steamcommunity.com/sharedfiles/filedetails/?id=1648967877) voegt bloedeffecten, bloedplassen/-sporen en vliegen bij lichamen toe. Host en alle spelers laden nu **vijftien mods** uit `Mods.html`. Installeer **geen aparte BleedTrail** naast GoreZ; die functionaliteit zit al in GoreZ. De modbestanden zelf worden via Steam geleverd, niet in deze ZIP.

**Bestaande installatie in één keer bijwerken:**

1. Stop de server en maak een wereldbackup met `scripts/Backup-World.ps1`.
2. Pak deze ZIP apart uit. Vervang in je bestaande pakketmap `scripts`, `config/mission`, `config/profiles`, `config/mods.json`, `Mods.html` en `04-Teststand.cmd`. Behoud **`config/server.local.json`**, je servermissie en alle saves/profielen.
3. Abonneer host en spelers via `Mods.html` op alle ontbrekende mods, wacht op Steam en importeer de nieuwe preset. Kom je van vóór 0.9.0, dan zijn ook Building Fortifications, MMG en Expansion Weapons nieuw.
4. Voer **`04-Teststand.cmd`** uit. Deze past de complete configuratie toe, inclusief sneller bijvullen en de stamina-aanpassing. Start met **`02-Start-server.cmd`** en controleer met **`03-Controleren.cmd`**.

Geen wipe nodig. Pakkettests controleren installatie, modpaden, loot- en stamina-instellingen en behoud van saves/wachtwoorden. GoreZ-effecten, samenwerking met de huidige DayZ-versie en je andere mods, prestaties en herstartpersistentie moeten lokaal in-game worden gecontroleerd.

## Snel beginnen

1. Pak dit pakket volledig uit op je Windows-pc, bijvoorbeeld naar `C:\DayZ-Servahz`. Bewaar deze map: de knoppen gebruiken de lokale configuratie hierin.
2. Installeer **Steam → Bibliotheek → Tools → DayZ Server**, app-ID **223350**. De host en spelers hebben ook DayZ nodig. Start DayZ eenmaal om launcher en BattlEye te laten installeren.
3. Open **[Mods.html](Mods.html)**. Abonneer je op alle **vijftien** mods en wacht tot Steam alle downloads heeft voltooid. Importeer dit bestand ook in de officiele DayZ Launcher via **Mods → Preset → Importeren**. Je vrienden gebruiken hetzelfde bestand.
4. Sluit een eventueel draaiende DayZ-server. Dubbelklik **`01-Instellen.cmd`**. De installer zoekt de Steam-bibliotheken en maakt `config/server.local.json` met jouw paden en een willekeurig adminwachtwoord.
5. Open `config/server.local.json` in Kladblok. Vul voor een prive-server `ServerPassword` in, sla op en voer **`01-Instellen.cmd`** nogmaals uit. Gebruik een ander wachtwoord dan `AdminPassword`. Dit lokale bestand wordt door Git genegeerd.
6. Dubbelklik **`02-Start-server.cmd`**. Laat het servervenster open en wacht enkele minuten. De eerste start maakt Expansion-profielen en de lootwereld aan. Voer **`03-Controleren.cmd`** uit voor configuratie- en querycontrole.
7. Open de DayZ Launcher met alle vijftien mods. Kies **Servers → Direct connect**: **`127.0.0.1`, poort `2302`**. Een andere pc in hetzelfde thuisnetwerk gebruikt het LAN-IP van de host, bijvoorbeeld `192.168.1.50`.

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

De nieuwe [Building Fortifications](https://steamcommunity.com/sharedfiles/filedetails/?id=2670506982), [MMG – Mightys Military Gear](https://steamcommunity.com/sharedfiles/filedetails/?id=2663169692) en [Expansion Weapons](https://steamcommunity.com/sharedfiles/filedetails/?id=2792985069) staan in `Mods.html`. Vanaf 0.18.0 laden host en alle spelers **zeventien mods**. CF, Dabs Framework en Expansion Core waren al aanwezig. Geen modcode of gamebestanden worden meegeleverd.

**Nieuwe lootselectie:**

| Voorraad | Gewone pakketdoelen per type | Teststand per type |
| --- | --- | --- |
| 8 Expansion-vuurwapens | doel 30 / minimum 23 | doel 60 / minimum 46 |
| 5 Expansion-vuurwapens | doel 60 / minimum 45 | doel 120 / minimum 90 |
| 8 SNAFU-vuurwapens | doel 30 / minimum 24 | doel 60 / minimum 48 |
| 7 Expansion-magazijnen | doel 120 / minimum 90 | doel 240 / minimum 180 |
| 8 SNAFU-magazijnen | doel 30 / minimum 24 | doel 60 / minimum 48 |
| 3 Expansion-munitietypen en 3 munitiedozen | doel 100 / minimum 80 | doel 200 / minimum 160 |
| 3 SNAFU-munitietypen | doel 30 / minimum 24 | doel 60 / minimum 48 |
| 2 SNAFU-vizieren | doel 10 / minimum 8 | doel 20 / minimum 16 |
| 7 vizieren/railadapters | doel 30 / minimum 20 | doel 60 / minimum 40 |
| 9 MMG-rugzakvarianten | doel 75 / minimum 60 | doel 150 / minimum 120 |
| 4 barricadekits | doel 40 / minimum 32 | doel 80 / minimum 64 |

Dit zijn vaste pakketdoelen in `servahz_ce/extra_types.xml`, geen extra vermenigvuldiging met `LootMultiplier`. `TestSuppliesEverywhere` verdubbelt deze doelen en opent alle 17 usages/tier 1–4. Wapen- en itemcategorieën, tags en echte lootposities blijven gelden. De teststand heeft daarnaast nog de bestaande vanilla-, RaG- en Expansion-bouwloot.

Wapens: **M9, G36, MPX, MP5, MP5SD, MP7, Kedr, Vityaz, M16, DT11, Benelli M4, AWM en Kar98**. De zeven aparte Expansion-magazijnen staan in de loot; MP5 en M16 gebruiken ook vanilla-magazijnen die al in de economie zitten. De 18 wapens met losse magazijnen hebben **80% kans op een passend magazijn** bij nieuwe CE-spawns. Losse munitie en magazijnen hebben een ingestelde hoeveelheid van 80–100%; munitiedozen blijven gewone dozen. Dit is geen garantie op een volledig geladen wapen. Er zijn geen RPG's, LAW's of granaatwerpers aan de gewone pakketloot toegevoegd.

Rugzakken: zwarte **Assault Pack, Carrier Backpack, Camelback, Supplybag en MMPS**, plus groene en tan Supplybag/MMPS. Volgens de MMG-beschrijving lopen deze modellen van 80 tot 150 slots. Andere MMG-kleding en pantser worden met de mod geladen, maar zijn niet in deze gerichte lootselectie opgenomen.

Barricades: **kleine en middelgrote raamkit, deurkit en dubbele deurkit**. Plaats de juiste kit bij een bestaand raam of deur en voeg de materialen toe die de bouwactie vraagt. Building Fortifications behoudt zijn eigen standaardbouwkosten; de eenvoudige RaG-kosten gelden hier niet. De vier geplaatste barricadeklassen hebben `nominal=0`, `crafted=1` en een CE-levensduur van 45 dagen. Dat is geen onbeperkte levensduur of raidbescherming; onderhoud en herstartpersistentie lokaal controleren.

**Waarom hogere aantallen niet altijd volle huizen geven:** vroeger wijzigde de teststand vooral doelen en locaties. Gebouwcapaciteit, bijvulbudgetten, wachttijden en afstand tot spelers bleven beperkt. Het nieuwe `TestFastRestock: true` doet daarnaast:

- Verdubbelt positieve `lootmax`-waarden uit de Steam-standaardmissie in de eigen `mapgroupproto.xml`. Nul blijft nul; posities, tags en categorieën worden niet gewijzigd. Meer capaciteit maakt geen nieuwe fysieke posities.
- Zet `RestartSpawn=50`: vraagt bij een herstart aanvulling richting de nominale doelen (50% volgens de Bohemia-configuratiereferentie), met behoud van de bestaande opgeslagen wereld.
- Zet `RespawnTypes=30`, `RespawnLimit=50` en `RespawnAttempt=4`, zodat meer typen/items per ronde kunnen worden bijgevuld.
- Verkleint `LootSpawnAvoidance` van de Chernarus-standaard 100 naar **50 meter**. Loop bij een leeg gebouw meer dan 50 meter weg en kom later terug; naast het lootpunt blijven staan kan het spawnen blokkeren.
- Zet `restock=0` voor actieve, gewone vanilla-loot: geen extra wachttijd per type. Crafted en speciale eventloot behouden hun regels.

**Update:** stop de server en maak een wereldbackup. Abonneer host en spelers op de drie nieuwe mods, wacht op Steam en vervang `scripts`, `config/mission`, `config/profiles`, `config/mods.json` en `Mods.html`. Behoud `config/server.local.json`, je missie en saves. Voer **`04-Teststand.cmd`** uit, importeer de nieuwe preset, start met `02-Start-server.cmd` en laat de server laden. Een wereldwipe is niet nodig. Starten/bijvullen kan meer CPU en tijd kosten.

`03-Controleren.cmd` controleert dat de nieuwe CE-bestanden zijn gekoppeld en dat de snelle bijvulwaarden zijn toegepast. In de console moet de extra modloot als **67 itemtypen** worden geteld. Controleer bij ontbrekende items ook het nieuwste RPT op onbekende klassen of modfouten; pakkettests starten geen echte DayZ-server.

**Terugzetten:** server stoppen, `TestFastRestock` op `false` zetten en `01-Instellen.cmd` uitvoeren. De vijf bijvulglobals, normale `restock`-waarden en gebouwcapaciteit worden dan uit de Steam-standaardmissie hersteld; andere globals blijven staan. `LootMultiplier`, andere testvelden en reeds bestaande loot blijven behouden. Zet voor herstel van de originele locaties ook `TestMilitaryEverywhere` en `TestSuppliesEverywhere` uit. De installer leest telkens de standaardmissie: herhaald instellen stapelt de capaciteitsfactor niet. `mapgroupproto.xml` is nu een beheerd bestand; bewerk de Steam-standaardmissie niet.

Bronnen: [Bohemia CE-configuratie](https://community.bistudio.com/wiki/DayZ:Central_Economy_Configuration), [officiële Expansion CE-data](https://github.com/ExpansionModTeam/DayZ-Expansion-Missions/tree/248dd215738550bff9cc3b5a0c84c5e895074712/Template/Chernarus/expansion_ce), [MMG-klassennamen in de community-marktconfiguratie van Expansion](https://github.com/ExpansionModTeam/DayZ-Expansion-Unofficial-Market-Settings/blob/fdf7815b1a97f9ae717e2022199102af8c3945c7/Market/MMG%20Gear/MMG_Gear.json) en [de oorspronkelijke barricadeconfiguratie](https://github.com/Dumpgrah/Public-BuildingFortification/blob/c14eee2927eb3f387ed95166fdf846cece07782a/BuildingFortifications/scripts/config.cpp). Modbestanden worden via Steam geladen; controleer daadwerkelijk spawnen, compatibiliteit en performance in-game.

## Kaart en minimap

[DayZ-Expansion-Navigation](https://steamcommunity.com/sharedfiles/filedetails/?id=2792984722) is de zevende mod, vereist op server en clients. De afhankelijkheden CF, Dabs Framework en Expansion Core waren al aanwezig.

- **M** opent de grote Expansion-kaart met je eigen positie.
- **Houd N ingedrukt** om de GPS/minimap rechtsonder te tonen of verbergen. **Druk kort op N** om tussen kaart- en GPS-informatie te wisselen.
- Een fysiek kaart-, GPS- of kompasitem is niet vereist. Persoonlijke markers en het HUD-kompas zijn ingeschakeld.
- Controleer bij toetsconflicten **Options → Controls → Expansion**. Bestaande client-keybindings kunnen afwijken van de standaard.
- Groepsgenoten en bots worden niet automatisch op de kaart getoond; deze configuratie levert geen groepsmod of radar.

**Bestaande installatie bijwerken:** stop de server, abonneer je op Navigation en wacht op Steam. Kopieer uit de nieuwste pakketversie de mappen `scripts` en `config/mission`, plus `config/mods.json` en `Mods.html`, naar je bestaande pakketmap. Behoud `config/server.local.json`. Voer `01-Instellen.cmd` uit en start opnieuw. Importeer de nieuwe `Mods.html` in de clientlauncher; ook vrienden laden alle vijftien mods. Dit vergt geen wereldwipe. Controleer lokaal M en N na het inloggen; pakkettests bewijzen geen werkende in-game HUD.

## Makkelijker bouwen met RaG (v0.8.0)

**Nieuw:** [RaG_Core](https://steamcommunity.com/sharedfiles/filedetails/?id=3556131153) en [RaG_BaseBuilding](https://steamcommunity.com/sharedfiles/filedetails/?id=3157695626). Server en alle spelers laden nu **vijftien mods** uit `Mods.html`. Expansion blijft aanwezig voor je bestaande gebouwen, codesloten, safes en andere functies. Er wordt geen modcode meegeleverd: abonneer je via Steam.

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

4. Vrienden importeren `Mods.html`, laden de vijftien mods en verbinden met **jouw publieke IPv4-adres**, gamepoort **2302** en het serverwachtwoord. De host gebruikt zelf het LAN-adres of `127.0.0.1`.
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
| Ontbrekende PBO, verkeerde versie/signature | Alle vijftien mods bijwerken; opnieuw instellen; geen Bundle erbij laden |
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
- Je kunt met alle vijftien mods inloggen, bewegen en loot oprapen.
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
