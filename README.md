# Servahz — DayZ voor Windows, AI, 5× loot en makkelijk bouwen

Een lokaal serverpakket voor **Windows 10/11 + Chernarus**, met DayZ Expansion AI en BaseBuilding. Installeer de officiele game/server en Workshop-mods via Steam, voer de installer uit en start de server. Gamebestanden en mods worden niet meegeleverd.

**Getest:** installatie met testbestanden, configuratiegeneratie, behoud van saves, opnieuw instellen zonder 25× loot, modupdates, backups en het queryprotocol. **Nog lokaal te testen:** de echte Windows-server starten, verbinden, AI-gedrag en bouwen. De Linux-cloudomgeving kan deze Windows/Steam-speltest niet uitvoeren.

## Snel beginnen

1. Pak dit pakket volledig uit op je Windows-pc, bijvoorbeeld naar `C:\DayZ-Servahz`. Bewaar deze map: de knoppen gebruiken de lokale configuratie hierin.
2. Installeer **Steam → Bibliotheek → Tools → DayZ Server**, app-ID **223350**. De host en spelers hebben ook DayZ nodig. Start DayZ eenmaal om launcher en BattlEye te laten installeren.
3. Open **[Mods.html](Mods.html)**. Abonneer je op alle **zes** mods en wacht tot Steam alle downloads heeft voltooid. Importeer dit bestand ook in de officiele DayZ Launcher via **Mods → Preset → Importeren**. Je vrienden gebruiken hetzelfde bestand.
4. Sluit een eventueel draaiende DayZ-server. Dubbelklik **`01-Instellen.cmd`**. De installer zoekt de Steam-bibliotheken en maakt `config/server.local.json` met jouw paden en een willekeurig adminwachtwoord.
5. Open `config/server.local.json` in Kladblok. Vul voor een prive-server `ServerPassword` in, sla op en voer **`01-Instellen.cmd`** nogmaals uit. Gebruik een ander wachtwoord dan `AdminPassword`. Dit lokale bestand wordt door Git genegeerd.
6. Dubbelklik **`02-Start-server.cmd`**. Laat het servervenster open en wacht enkele minuten. De eerste start maakt Expansion-profielen en de lootwereld aan. Voer **`03-Controleren.cmd`** uit voor configuratie- en querycontrole.
7. Open de DayZ Launcher met alle zes mods. Kies **Servers → Direct connect**: **`127.0.0.1`, poort `2302`**. Een andere pc in hetzelfde thuisnetwerk gebruikt het LAN-IP van de host, bijvoorbeeld `192.168.1.50`.

Windows kan gedownloade scripts blokkeren. Gebruik zo nodig **Eigenschappen → Blokkering opheffen** op de ZIP en pak opnieuw uit. De `.cmd`-knoppen gebruiken alleen voor hun eigen PowerShell-proces `ExecutionPolicy Bypass`; ze veranderen geen permanente Windows-instelling. Instellen vereist normaal geen administratorrechten als de Steam-map beschrijfbaar is.

**Andere Steam-schijf of verkeerde automatische detectie?** Open PowerShell in de pakketmap:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-Server.ps1 -ServerPath "D:\SteamLibrary\steamapps\common\DayZServer" -WorkshopPath "D:\SteamLibrary\steamapps\workshop\content\221100"
```

`ServerPath` bevat `DayZServer_x64.exe`. `WorkshopPath` bevat de genummerde modmappen, niet `!Workshop` en niet de DayZ-gamemap. Steam kan game, server en Workshop over verschillende bibliotheken verdelen.

## Inhoud en spelregels

| Onderdeel | Instelling |
| --- | --- |
| Map / spelers | Chernarus, 12 slots, eerste en derde persoon |
| Loot | Vanilla `nominal` en `min` ×5, vanaf de geinstalleerde standaardmissie |
| AI | Zes routes; maximaal vier actieve groepen, samen hoogstens 12 bots |
| Moeilijkheid | Nauwkeurigheid 0,15–0,35, 65% uitgaande schade, normale gezondheid; bots zijn lootbaar |
| AI-spawning | Spelers circa 250–900 m van de patrouille; despawn buiten 1100 m |
| AI-herhaling | Respawninstelling 20 minuten; despawnvertraging 5 minuten |
| Bouwen | Expansion-muren, vloeren, trappen, ramps, codesloten, safes; vanilla bouwen blijft mogelijk |
| Bouwgemak | Geen verplicht territory, soepelere plaatsingschecks, eenvoudige vlag en snapping |
| Bouwloot | Kits en codesloten in industrie/boerderijen, safes bij industrie/steden/militair |
| Tijd | Dag 6× versneld, nacht extra 4× versneld |
| Integriteit | BattlEye standaard actief, `verifySignatures=2`, gelijke gamebuild verplicht |

Patrouilles liggen rond **Balota, Zelenogorsk, Stary Sobor, NWAF, Tisy en Krasnostav airfield**. Ze gebruiken de vijandige `West`-faction en de door Expansion aangemaakte `WestLoadout`. Ze verschijnen niet allemaal permanent. Dit zijn eigen beginroutes: loop ze lokaal na op obstakels. Waypoint-hoogte 0 wordt door Expansion op het terrein geplaatst.

**5× loot is vijfmaal de economiedoelen, geen garantie op vijfmaal zoveel spullen per huis.** Spawnposities, tiers, events en CE-limieten blijven gelden. `nominal=0`, voertuigevents, zombies en dieren worden niet vervijfvoudigd. De eigen Expansion-bouwloot heeft vaste ruime aantallen in `building_types.xml` en wordt niet nogmaals vermenigvuldigd. Op bestaande werelden vult de economie geleidelijk bij; de installer verwijdert je wereld nooit om dit te versnellen.

Traders, geld, helicopters, quests en oneindige stamina zijn geen onderdeel van deze configuratie. Laad niet tegelijk de Expansion Bundle: die bevat dezelfde modules.

## Bouwen in de game

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

4. Vrienden importeren `Mods.html`, laden de zes mods en verbinden met **jouw publieke IPv4-adres**, gamepoort **2302** en het serverwachtwoord. De host gebruikt zelf het LAN-adres of `127.0.0.1`.
5. Laat iemand buiten je LAN testen: sommige routers ondersteunen geen NAT-loopback. Een TCP-poortchecker test deze UDP-server niet.

LAN werkt, internet niet? Vergelijk het WAN-adres van je router met je publieke IPv4. **CGNAT**, bijvoorbeeld een WAN-adres in `100.64.0.0/10`, of dubbele NAT kan inkomende verbindingen blokkeren. Vraag je provider om publiek IPv4 of configureer beide routers/bridge mode. Een mesh-VPN zoals Tailscale is een alternatief; host en vrienden moeten dat zelf installeren, dit pakket configureert het niet.

De Friends-firewallregel accepteert gameverkeer van alle bronadressen, uitsluitend op het particuliere netwerkprofiel. Deel je serverwachtwoord alleen met vrienden. Verwijderen:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Set-Firewall.ps1 -Remove
```

## Aanpassen en bijwerken

**Stop normaal met Ctrl+C in het DayZ-servervenster** en wacht tot het proces weg is. Instellen en backups weigeren zolang een `DayZServer_x64`-proces draait. Gebruik dit pakket niet gelijktijdig met een andere serverinstantie.

Pas bronbestanden hieronder aan en voer `01-Instellen.cmd` opnieuw uit:

| Bestand | Aanpassing |
| --- | --- |
| `config/server.local.json` | Naam, wachtwoorden, slots, paden, poorten, lootfactor en tijd |
| `config/mission/expansion/settings/AIPatrolSettings.json` | Bots, routes, faction, accuratesse, afstanden en groepsbudget |
| `config/mission/expansion/settings/BaseBuildingSettings.json` | Bouwregels, territories en codesloten |
| `config/mission/servahz_ce/building_types.xml` | Bouwloot en levensduur gebouwde onderdelen |

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
| Ontbrekende PBO, verkeerde versie/signature | Alle zes mods bijwerken; opnieuw instellen; geen Bundle erbij laden |
| `Unknown type ViewController` | Dabs Framework ontbreekt, is oud of wordt niet geladen |
| Installer vindt mods niet | Downloads afwachten; juiste Workshop-map onder app `221100` gebruiken |
| Oude Steam-schijf ontbreekt | De installer slaat onbereikbare Steam-bibliotheken over. Controleer bij een expliciet pad `ServerPath`/`WorkshopPath` of de schijf is aangesloten |
| Querycontrole faalt | Server laten laden; querypoort en logs controleren; eerst lokaal proberen |
| Query werkt, verbinden niet | Gamepoort, clientmods, BattlEye en gamebuild controleren |
| Geen bots | Nader een patrouillegebied vanaf meer dan 250 m en wacht; controleer loadouts en logs |
| JSON-fout | Bronconfig repareren, opnieuw instellen; versievelden niet willekeurig aanpassen |
| Hoge CPU/RAM-belasting | Minder actieve AI, lagere lootfactor en/of minder spelers |

Begin voor een kleine groep met een recente CPU, SSD en ongeveer **16 GB RAM in de host-pc**; meer als je op dezelfde pc speelt. Werkelijk gebruik hangt af van bots, loot, bases en spelers.

## Lokale acceptatiecontrole

- `03-Controleren.cmd` slaagt: configuratie/modbestanden kloppen en de verwachte servernaam antwoordt op A2S_INFO. Dat bewijst nog geen speelbaarheid.
- Je kunt met alle zes mods inloggen, bewegen en loot oprapen.
- AI verschijnt bij Balota/Stary/NWAF; bewegen, vechten en looten werken. Controleer routes op obstakels.
- Een Expansion-kit plaatsen, bouwen en een codeslot gebruiken werkt.
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
