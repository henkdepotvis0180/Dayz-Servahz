# Wijzigingen per versie

Elke versie beschrijft het pakket op dat moment. Instellingen in latere versies kunnen eerdere waarden vervangen. De datums hieronder zijn lokale datums voor Nederland.

**Bestaande installatie:** stop de server en behoud `config/server.local.json` en je wereldsave. Maak een wereldbackup voordat je bijwerkt. De hieronder genoemde bestanden vervang je in de uitgepakte pakketmap, naast `01-Instellen.cmd`.

## [0.18.7] — 2026-10-30

### Zeldzamere modwapens vaker en op militaire locaties in alle tiers

- Geeft twaalf geselecteerde wapenklassen driemaal het oude doel: Expansion G36, M16, MP7 en AWM; HK416, Vector, SCAR-H, SR-25, M110, M24, T-5000 en Honey Badger. Gewoon **90/81 doel/minimum per type**, met testvoorraad **180/162**. Wereldwijd doel voor deze selectie: 1080 of 2160. De eerdere gewone modwapens en vanilla-cap blijven behouden.
- Breidt de geselecteerde wapens uit naar Tier1–4 met behoud van hun bestaande usages, waaronder Military. Sommige Expansion-geweren waren buiten de teststand alleen in hogere tiers beschikbaar. De bestaande teststand blijft zijn bredere locatiecategorieën gebruiken; lokale testvlaggen worden niet gewijzigd.
- Past de boost vóór het koppelen van munitie/magazijnen toe. Passende voorraad blijft op minimaal tweemaal het wapendoel, met 80–100% inhoud; ook die voorraad krijgt `restock=0`. Deze doelvloer kan de algemene voorraadcap overschrijden. De wapentimer stond al op nul: de verbetering komt van hogere doelen, de eerdere bijvulgrens van 90% en ruimere tiers. CE-budget, vrije posities en spelerafstand blijven de feitelijke spawns bepalen.
- Verandert geen levensduren, telvlaggen, vanilla-specialevents, bestaande items of saves. Uitgeschakelde, crafted- en event-only modwapens worden door de gerichte boost overgeslagen. Vanaf 0.18.6 blijven bestaande CJ187-profielen en locaties bytegelijk; de kistreparatie uit die versie komt cumulatief mee voor oudere installaties.
- 03 valideert de nieuwe doelen/tiers en toont **Zeldzame wapens 0.18.7** met configuratiedoelen. Dit is geen actuele wereldtelling of garantie op loot op één vliegveld.

**Bijwerken:** sluit normaal af met `#shutdown`, wacht tot het serverproces uit is en voer **`Servahz-Update-v0.18.7.cmd`** uit naast 01. De update bevat ook 0.18.6, persoonlijke respawn en eerdere wijzigingen vanaf de vaste basis; vereiste mods staan in `Mods.html`. Start met 02 en controleer 03 plus verse/vrije militaire lootplekken. Geen wipe, 04, 05/06 of codeslotlevering nodig. Bestaande spullen blijven liggen; CE vult beschikbare plekken geleidelijk aan. Saves, wachtwoorden, lokale testinstellingen, privé-basecirkel, RaG-/CJ187-profielen en de missiehooks blijven behouden; de updater maakt eerst een wereld-/profielbackup.

**Controle:** gerichte tests voor gewone/testdoelen, 90%-grens, alle tiers, passende magazijnen/munitie en hun timer, behoud van lifetimes/telvlaggen, eigen personage/gear/profielen/wachtwoorden en herhaalbaarheid. Weigeren van een ontbrekende tier in de alleen-lezen controle; disabled/crafted/event-only modtypes blijven onaangeroerd. Volledige regressiesuite, officiële CE-data, cumulatieve 0.18.6→0.18.7-updater en ontbrekende-mod-foutpad; Windows PowerShell 5.1 vóór publicatie. Geen DayZ-engine uitgevoerd: aanwezigheid en compatibiliteit van de modklassen, daadwerkelijke spawns en de vulsnelheid op het vliegveld moeten in-game worden bevestigd.

## [0.18.6] — 2026-10-29

### Expliciete wapenroutes en minder algemene spullen in groene kisten

- Groene militaire/politiekisten gebruiken nu per bestaande wapenset een native `LC_Table_Weapons_Servahz_...`-tabel. De tabel staat vóór de passende extra magazijn-/munitievoorraad en algemene spullen in de vullijst. De oude directe `LC_predefined_...`-verwijzing achter zeven algemene keuzes vervalt. Het V106-voorbeeld en de makersdocumentatie gebruiken de speciale wapentabelprefix.
- Daarna volgen één voedsel-, één drank- en één medische keuze, zonder de algemene toolkeuze. Bruine voedsel-/bouw-/medische kisten veranderen niet. De bestaande 18 gecontroleerde wapencombinaties blijven behouden. Geen nieuwe mods of nieuwe wapentypen toegevoegd.
- Migreert bij instellen ook bestaande groene `Servahz_Weapons_...`-pakketlocaties, alleen als hun vullijst exact overeenkomt met de oude pakketversie en de wapen/magazijn-combinatie herkend wordt. Behoudt posities, aantallen, sleutelvrije toegang, wapendefinities/attachments, andere kisten en onbekende velden. Eigen aangepaste inhoud en botsende eigen tabelnamen blijven ongemoeid. Oorspronkelijk CJ187-profiel wordt vóór schrijven geback-upt; geen nieuwe locatiegeneratie of savewijziging. Herhaald instellen verandert een bijgewerkt profiel niet opnieuw.
- Valideert ook wapensetverwijzingen binnen tabellen en dubbele tabel-/wapensetnamen vóór live wijzigingen. 03 toont aantallen groene locaties met wapentabel of losse oude verwijzing. Een privacyveilige samenvatting telt ruimte-/formaat- en ontbrekende-klasse-signalen in maximaal drie recente CJ187-logstaarten van elk 200 regels. Geen ruwe logregels, spelersgegevens, codes of coördinaten.
- Dit verbetert de configuratieroute en geeft wapens voorrang op algemene voorraad. Zonder het actieve serverprofiel, modlog en enginecontrole is niet bewezen waarom op de gemelde server alleen algemene spullen zichtbaar waren. CJ187 meldt zelf dat wapens kunnen ontbreken door te weinig ruimte of te grote SNAFU-modellen. De update claimt geen enginegarantie voor ieder wapen.

**Bijwerken:** stop normaal met `#shutdown` en wacht tot het proces uit is. Voer **`Servahz-Update-v0.18.6.cmd`** uit naast 01 en start met 02. Dit ene cumulatieve bestand bevat ook persoonlijke territoryrespawn en alle eerdere updates sinds basis 0.13.0; de vereiste mods staan in `Mods.html`. De updater maakt eerst een volledige wereld-/profielbackup; het oorspronkelijke kistprofiel staat ook onder `Servahz/Backups/config-.../Profiles/CJ_LootChests`. Geen wipe, 04, 05/06 of nieuwe codeslotlevering nodig. Gebruik CJ187-lootkisten niet als eigen opslag: de mod vult ze bij een herstart. Wacht na starten ongeveer een minuut op CJ187-initialisatie en controleer een verse groene kist plus 03.

**Controle:** gerichte regressies voor wapentabelroutes, volgorde en passende munitie; exacte oude-profielmigratie, backup, herhalen, behoud van eigen posities/inhoud/velden en saves/wachtwoorden/init; weigeren van ontbrekende wapensetverwijzingen en behoud bij eigen tabelnaamconflict; privacy en alleen-lezen logcontrole. Cumulatieve 0.18.5→0.18.6-update met officiële CE-data en ontbrekende-mod-foutpad. Volledige regressiesuite en Windows PowerShell 5.1 vóór publicatie. Geen DayZ-engine uitgevoerd: feitelijke wapenvulling, cargo-afmetingen, modklasseregistratie en vullen na herstart moeten lokaal in-game worden bevestigd.

## [0.18.5] — 2026-10-29

### Persoonlijke respawn bij je eigen territory

- Voegt **DayZ-Expansion-Spawn-Selection**, Workshop **2804241648**, toe aan de modlijst en launcher-preset: nu 18 mods. De vereiste CF/Dabs/Expansion Core en BaseBuilding zijn al aanwezig. Geen bed-/slaapzakmod nodig voor deze persoonlijke respawnoptie.
- Schakelt `EnableSpawnSelection` en `SpawnOnTerritory` in. Expansion maakt per speler een lijst van territories waarvan die eigenaar/lid is. Spelers met een eigen territory krijgen elk hun eigen base-optie; leden van een gedeeld territory kunnen dezelfde base kiezen. De mod plaatst de respawn naast de vlag. Een vlag zonder gekoppeld Expansion-territory/lidmaatschap is niet voldoende.
- De nieuwe schema-7-beginconfiguratie biedt daarnaast **Normale kustspawn** met `0 0 0`: de native mod gebruikt daarvoor de oorspronkelijke DayZ-spawnpositie. Geen privécoördinaten of Steam-ID's in de configuratie. Wachttijden en multispawnstraf staan standaard uit; de bestaande missie verzorgt kleding/uitrusting, geen extra Expansion-loadout.
- `config/expansion/SpawnSettings.json` staat buiten de map die telkens over de missie wordt gekopieerd. Een bestaande volledige actieve configuratie behoudt locaties, uitrusting, wachttijden en onbekende velden; alleen de twee gevraagde inschakelopties worden aangepast en het oude bestand wordt eerst geback-upt. Een al ingeschakelde configuratie blijft bytegelijk. Ongeldige/onbekende schema's of een oude profielconfiguratie worden vóór live wijzigingen geweigerd.
- 03 toont de ingestelde respawnopties zonder spelersgegevens of spawncoördinaten. De controle bewijst geen engineacceptatie of territorylidmaatschap. De bestaande `init.c`, codeslotlevering en lootverversingshooks blijven behouden. Alleen na overlijden/nieuw personage verschijnt de selectie; een bestaand levend personage wordt niet gereset of verplaatst door de pakketupdate.

**Bijwerken:** abonneer host en spelers op [Expansion Spawn Selection](https://steamcommunity.com/sharedfiles/filedetails/?id=2804241648) en wacht op de download. Sluit de server normaal af met `#shutdown`. Voer **`Servahz-Update-v0.18.5.cmd`** uit naast 01, importeer de bijgewerkte `Mods.html` bij iedereen en start met 02. Dit ene cumulatieve updatescript bevat ook 0.18.4 en eerdere wijzigingen vanaf de vaste basis. Saves, wachtwoorden en lokale instellingen/profielen blijven bewaard; de updater maakt eerst een wereld-/profielbackup. Geen wipe, 04, 05, 06 of nieuwe 09-actie nodig. Controleer je eigenaarschap/lidmaatschap bij je bestaande Expansion-territory en laat naast de vlag ruimte vrij. De eerstvolgende keer dat je echt respawnt kun je je territory kiezen.

**Controle:** pakkettests voor nieuw instellen en herhalen, alleen inschakelopties aanpassen met backup van eigen respawninstellingen, ongeldige/oude instellingen vooraf weigeren, ontbrekende Workshop-download zonder live wijzigingen, behoud van wereld/personage, wachtwoorden, profielen en bestaande missie-/leveringshooks. Cumulatieve 0.18.4→0.18.5-updater met officiële CE-data getest op save-/configuratiebehoud en foutpaden; volledige regressiesuite en Windows PowerShell 5.1-controle vóór publicatie. De stabiele Expansion-broncode ondersteunt schema 7, territorylidmaatschap en de nulvector-fallback. Geen DayZ-engine uitgevoerd: modladen, spawnmenu, daadwerkelijke respawn naast de vlag, onafhankelijke keuzes voor twee spelers en beginuitrusting moeten lokaal in-game worden bevestigd.

## [0.18.4] — 2026-10-29

### Eenmalig een digitaal codeslot aan je eigen personage geven

- Nieuwe **`09-Codeslot-geven.cmd`**: plant met de server gestopt een levering van precies **1 vanilla `DigitalCodeLock` met toetsenpaneel** aan een opgegeven Steam64-ID in. RaG Core ondersteunt dit slot al via `Att_CodeLock_RaG`; geen nieuwe Workshop-mod of extra algemene loot toegevoegd. Geen combinatieslot met cijferwieltjes of Expansion Code Lock.
- Installeert alleen bij de expliciete 09-actie een bekende missiehook. De gewone update/01 start geen levering en stelt geen pincode in. Bij inloggen maakt de missie het slot in de inventaris van het exact overeenkomende, levende personage; andere spelers krijgen niets. Probeert een `Battery9V` aan het nieuwe slot te bevestigen. Geen bestaande items, deuren, slotcodes of profielinstellingen aangepast.
- Maakt vóór inplannen een volledige wereld-/profiel-/configuratiebackup onder `.local/Backups/codelock-<verzoeknummer>`. Steam64-ID staat alleen in het lokale `Profiles/Servahz/CodeLockDelivery-request.json`, niet in publieke missiecode, commits, release of controle-uitvoer.
- Een `.started`-claim wordt vóór itemcreatie geschreven. Na ontvangst of een onderbreking wordt niet automatisch een extra slot aangemaakt. Bij een expliciet ontvangstbewijs `NoInventorySpace` kan 09 met gestopte server een nieuw verzoek maken nadat inventarisruimte is vrijgemaakt. Een crash tussen claim, creatie en volgende wereldsave kan een onzekere levering achterlaten; die wordt bewust niet blind herhaald. `09-Codeslot-geven.cmd -Disable` annuleert een nog niet uitgevoerde levering en verwijdert geen geleverd item.
- Weigert ongeldige ID's, afwijkende/onvolledige missiehooks, afwijkende leveringscode en een nog niet uitgevoerde loot-proefscan/verversing. De leveringsmissie erft de bestaande refresher; een eerder voltooide proefscan/verversing wordt niet opnieuw gestart. 05/06 blijven met de bekende leveringshook werken zonder dubbele includes. De oorspronkelijke lootverversingscode/-policy blijven ongewijzigd.
- `03-Controleren.cmd` toont een vaste, privacyveilige leveringsstatus: ingepland, geleverd, geen inventarisruimte, ontbrekende itemklasse of geclaimd/onzeker. Geen Steam64-ID, PIN of willekeurige receipt-inhoud in de statusuitvoer.

**Bijwerken/gebruiken:** sluit normaal af met `#shutdown` en wacht tot het serverproces uit is. Voer `Servahz-Update-v0.18.4.cmd` uit naast 01; de bestaande updater behoudt saves, wachtwoorden, lokale instellingen en RaG-/CJ187-profielen. Dubbelklik daarna op 09 en vul je Steam64-ID van 17 cijfers in, of gebruik `09-Codeslot-geven.cmd -SteamId <je-id>`. Start met 02, log met dat account in en houd een paar inventarisvakjes vrij. Bekijk bij geen ontvangst 03. Na ontvangst normaal afsluiten zodat de huidige wereld kan worden opgeslagen. De update alleen levert niets; 04/05/06 zijn voor deze levering niet nodig.

**Gebruik van het slot:** verwijder eerst het losse oude combinatieslot uit een eventuele deur-slotpositie. Bevestig de nieuwe `DigitalCodeLock` aan een volledig gebouwde, gesloten RaG-deur en stel via het toetsenpaneel zelf tweemaal een PIN in. Bij RaG-standaardinstellingen wordt de eerste insteller eigenaar en wordt toegang onthouden. Bestaande afwijkende Core-instellingen worden behouden; de levering wijzigt die niet. Test openen/sluiten zolang je nog toegang tot binnen hebt.

**Controle:** integratietests voor backup-/save-/profiel-/initbehoud, exacte ID-validatie, herhaald inplannen zonder extra levering, ontbrekende ruimte, weigeren van eigen missiecode en nog openstaande cleanup, compatibiliteit met een voltooide lootverversing, privacyveilige status en de echte CMD-knop op Windows PowerShell 5.1. De werkelijke leveringspredicate wordt objectvrij als C++ uitgevoerd met alle combinaties van ontvanger-/schema-/claim-/levendestatus; dit is geen DayZ-enginecompile. Volledige regressiesuite. De daadwerkelijke inventory-creatie, batterij en RaG-PIN-interface moeten bij de eerste lokale levering in-game worden bevestigd; hier is geen DayZ-engine uitgevoerd. Geen bewezen reparatie voor het oude cijferwieltjesprobleem.

## [0.18.3] — 2026-10-29

### Correcte opslagcontrole en meer detail bij herstelmeldingen

- Corrigeert een fout in de nieuwe diagnose: DayZ leest **`db/economy.xml`**, niet `economy.xml` in de missieroot. De oude melding "economy.xml ontbreekt of ongeldig" bewees daardoor geen ontbrekend serverbestand. De nieuwe controle toont `load`/`save` vanaf het officiële databasepad en valt niet terug op een gelijknamig bestand buiten `db`.
- De testmissies gebruiken nu ook dat officiële pad; een regressietest met een misleidend rootbestand voorkomt herhaling. Geen wijziging aan het echte economiebestand of de opslagvlaggen.
- Opslagmeldingen tonen nu lognummer en vaste trefwoorden zoals `recover`, `corrupt`, `restore`, `fail`, `backup`, bekende CE-tags, eventueel `valid:yes/no`, geselecteerde publieke RaG-/slotfunctienamen en uitsluitend standaard CE-opslagbestandsnamen. Geen volledige regels, willekeurige bestandsnamen/paden, spelersnamen, codes of wachtwoorden. Ook `Restoring` en beschadigde inventaris-/stream-/scriptgegevens zonder CE-tag worden herkend. Trefwoorden alleen bewijzen geen corruptie: normaal laden of een onschuldige herstelvermelding kan ook matchen.
- Dezelfde Windows-installatie met andere hoofdletters wordt niet meer tweemaal onderzocht. Inactieve standaardmissies krijgen geen meldingen over ontbrekende RaG-economiekoppelingen; de verwachte missie en expliciete `-mission`-override worden inhoudelijk gecontroleerd. Opslagmetadata van andere gevonden missies blijft beschikbaar.
- De server uit het aangeleverde rapport gebruikt de verwachte executable/configuratie/profielen en heeft een recente schrijftijd. De RaG-kitkoppeling bestaat eenmaal, beide onderzochte XML-bestanden zijn leesbaar en er zijn geen onderzochte bouw-/`cheatCheck`-regels in de ignorelijst. Dit bewijst niet dat ieder bouwdeel goed wordt opgeslagen. De gemelde kit-levensduur van vier uur is geen bewezen levensduur van een geplaatste muur. Geen RaG-implementatieklassen, CE-koppelingen of levensduren toegevoegd op basis van algemene adviezen.

**Direct gebruiken:** vervang alleen de losse [08-Opslagdiagnose.cmd](https://raw.githubusercontent.com/henkdepotvis0180/Dayz-Servahz/v0.18.3/08-Opslagdiagnose.cmd) naast 01. Laat een draaiende server voor deze leescontrole draaien; update, installatie en herstart zijn niet nodig. Deel het nieuwe tekstbestand uit `.local/StorageDiagnostics`. Als de server al gestopt is, kan deze controle ook gestopt worden uitgevoerd; bestaande logs en databasebestanden blijven leesbaar en procesinformatie is dan niet beschikbaar. Pas het voorgestelde Google-XML-fragment niet toe: de pakketkoppeling is al aanwezig en DayZ gebruikt `ce folder` met onderliggende `file`-elementen.

**Gewoon bijwerken:** de cumulatieve `Servahz-Update-v0.18.3.cmd` blijft het enige releasebestand. Gebruik voor deze updater de normale stop-/backupstappen. Geen wereldherstel, writes naar saves/profielen/economie of automatische materiaalteruggave. Dit verbetert de diagnose en is geen bevestigde reparatie voor verdwenen bouwdelen.

**Controle:** gerichte regressies voor het echte databasepad, ontbrekend databasebestand zonder rootfallback, hoofdlettervarianten van Windows-paden en privacyveilige details van herstelmeldingen. Bestaande read-only-/savebehoudtests, de echte Windows-CMD-knop en de volledige Windows PowerShell 5.1-suite. Geen DayZ-engine uitgevoerd; de echte herstelmeldingen moeten met het nieuwe lokale rapport worden beoordeeld.

## [0.18.2] — 2026-10-29

### Opslagdiagnose bij verdwijnende bouwdelen

- Nieuwe zelfstandige **`08-Opslagdiagnose.cmd`** voor gebruik terwijl de bestaande DayZ-server draait. Kan zonder update/installatie naast 01 worden neergezet; zo hoeft een verdachte startopdracht niet eerst door een herstart verloren te gaan. Ook opgenomen in de gewone cumulatieve update. Geen extra release-asset of volledig pakket.
- Vergelijkt met Windows CIM de executable, absolute config-/profielpaden en spelpoort van maximaal vier draaiende DayZ-serverprocessen met de pakketinstellingen. Meldt dubbele, relatieve, onleesbare of ontbrekende argumenten zonder er een actieve wereld uit af te leiden. Signaleert expliciete `-mission`- en `-storage`-overrides en meerdere processen. Toont geen startopdrachten, padnamen of argumentwaarden.
- Leest uitsluitend geselecteerde numerieke `instanceId`-/`storageAutoFix`-instellingen, of de missienaam met het pakket overeenkomt, en bestand-/procesdatums. Configuratie-inspectie betreft huidige tekstbestanden, niet noodzakelijk de instellingen die een eerder gestart proces heeft geladen. Verandert geen instanceId, missie, opslaglocatie of opslagherstelbeleid.
- Toont metadata van de verwachte `storage_1`, gevonden `storage_<nummer>`-mappen onder maximaal 32 missies per gevonden installatie en absolute lokale missie-/opslag-overrides. Geen schijfbrede zoekactie, uitlezen van save-inhoud, schrijftest of rechtenwijziging. Relatieve paden worden niet tegen een gegokte werkmap opgelost; UNC-paden worden niet gevolgd.
- Controleert bovendien XML-leesbaarheid van hoofdtypes en de RaG-economiekoppeling, geselecteerde kit-levensduren, de `load`/`save`-vlaggen in `economy.xml` en aantallen bouw-/`cheatCheck`-regels in `cfgIgnoreList.xml`. Externe XML-entiteiten/DTD's worden geweigerd. Geen wijziging van deze bestanden en geen aanname dat tekstinspectie daadwerkelijke engineacceptatie bewijst. Bohemia [waarschuwde bij 1.27](https://feedback.bistudio.com/T189577) voor het oude `cheatCheck`-probleem; dit is een gerichte controle, geen vastgestelde oorzaak op de huidige server.
- Zoekt in maximaal acht recente logstaarten per gevonden lokaal profiel naar opslag-/schrijf-/corruptiemeldingen. Alleen vaste categorieën en kloktijden, geen volledige logregels, bestandsnamen, spelersgegevens, codes of wachtwoorden. Een signaal of recente opslagmap is een aanwijzing en bewijst niet waar een speler verbonden is of dat een bouwdeel verwijderd is.
- Schrijft uitsluitend een privérapport onder **`.local/StorageDiagnostics`**. Geen wipe, herstel, serverstop/start, profielwijziging, modwijziging, materiaalteruggave of lootverversing. Geen bewezen reparatie voor verdwenen RaG-bouwdelen; de oudere diagnose controleerde alleen de vaste pakketopslag.

**Direct onderzoeken zonder de server te stoppen:** download [08-Opslagdiagnose.cmd van tag v0.18.2](https://raw.githubusercontent.com/henkdepotvis0180/Dayz-Servahz/v0.18.2/08-Opslagdiagnose.cmd), sla op naast `01-Instellen.cmd` en voer uit terwijl de bestaande server draait. Controleer dat de extensie `.cmd` blijft. Deel alleen het gemaakte tekstbestand. Voor deze zelfstandige controle zijn geen update, 01, 04, 05 of 06 nodig. Bij voorkeur geen nieuwe bouwmaterialen besteden totdat de actieve opslag is opgehelderd.

**Gewoon bijwerken:** stop de server normaal en voer `Servahz-Update-v0.18.2.cmd` uit naast 01. Behoudt saves, wachtwoorden, lokale instellingen en profielen; de gebruikelijke updater maakt een backup. Voer 08 na starten uit. Als juist de bestaande startopdracht onderzocht moet worden, gebruik eerst de zelfstandige knop hierboven; een herstart kan dat bewijs veranderen.

**Controle:** tests met geciteerde paden met spaties, gelijke en afwijkende startselecties, andere opslaginstanties, meerdere processen, dubbele/relatieve argumenten, ontbrekende procesinformatie, CE-koppelingen, ignore-/save-vlaggen, verboden externe XML-entiteiten en privacyfilters bij opslagfouten; wereld-/configuratie-/profielbehoud. Volledige regressiesuite en de echte CMD-knop op Windows PowerShell 5.1. Geen DayZ-engine uitgevoerd; actieve live opslag en de oorzaak van het verlies worden pas met het lokale rapport beoordeeld.

## [0.18.1] — 2026-10-28

### Alleen-lezen diagnose bij RaG-deuren en combinatiesloten

- Nieuwe knop **`07-Bouwdiagnose.cmd`**. Leest de bestaande installatie en schrijft alleen een afgeschermde samenvatting onder `.local/BuildDiagnostics`. Start/stopt geen server en wijzigt geen wereldbestanden, deuren, slotcodes, actieve instellingen of profielen.
- Vergelijkt SHA-256 van alle RaG Core- en RaG BaseBuilding-PBO's in de serverkopie met de lokale Workshop-download, inclusief ontbrekende en achtergebleven bestanden. De bestaande 03-controle controleerde aanwezigheid en sleutels, niet die inhoud. Gelijke bestanden bewijzen geen actuele Steam-download of overeenkomst met de mods op de computers van spelers.
- Toont uitsluitend geselecteerde numerieke RaG-instellingen en kosten van deurstappen, de beschikbare DayZ Server-bestandsversie, wereldopslagmetadata en datums van maximaal vijf aanwezige wereldbackupmappen. Leest geen wereldinventaris en voert geen herstel uit; een aanwezige backup is niet automatisch een gecontroleerde herstelbackup.
- Zoekt in de staarten van maximaal acht recente RPT-/script-/ADM-logs naar bouw-/slotfouten en bouw-/afbraakmeldingen. Toont maximaal dertig samenvattingen met alleen tijd, vaste categorie en toegestane publieke klasse-/functienamen. Geen volledige logregels, spelersnamen, adressen, PIN's, basecoördinaten of wachtwoorden. Foutsignalen bewijzen op zichzelf geen verwijdering van een specifieke deur.
- Geen wijziging aan de RaG-economie of levensduur. Het ontbreken van geplaatste RaG-klassen in `types.xml` bewijst geen oorzaak: de makersdocumentatie adviseert kits/het boek voor de economie en waarschuwt tegen het toevoegen van de implementatieklassen. `BaseInfiniteLifetime` is volgens RaG 45 dagen na opslag laden, geen onbeperkte bescherming.
- Dit is een diagnosehulpmiddel, **geen bevestigde reparatie** voor verkeerde cijferwieltjes of een verdwenen deur. Geen nieuwe mods, lootverversing, wipe, automatische terugzetactie of wijziging aan bestaande CJ187-profielen.

**Bijwerken/gebruiken:** stop de server en voer `Servahz-Update-v0.18.1.cmd` uit naast `01-Instellen.cmd`; de gewone updater maakt eerst een wereld-/profielbackup en behoudt saves, wachtwoorden en actieve instellingen. Dubbelklik daarna op `07-Bouwdiagnose.cmd`. De diagnose werkt ook met de server gestopt en installeert zelf niets. Deel alleen het resulterende diagnoserapport. Bewaar de huidige wereld apart voordat een herstelkeuze wordt gemaakt; een volledige oude wereld terugzetten kan recente bouw- en spelersvoortgang vervangen. Voor het verzamelen van dit rapport zijn starten, 04, 05 of 06 niet nodig.

**Controle:** tests voor ongewijzigde wereld/profielen/instellingen/logs, privacyfilters bij meerdere regels tellende scriptfouten en afbraakmeldingen, afwijkende/ontbrekende RaG-PBO's, ongeldige profielen zonder vervanging, scriptsyntaxis en het updaterpad. Volledige regressiesuite en Windows PowerShell 5.1. De werkelijke lokale modversies, serverlogsignalen en status van de verdwenen deur kunnen pas met het rapport/in-game worden beoordeeld; hier is geen DayZ-engine uitgevoerd.

## [0.18.0] — 2026-10-28

### Sleutelvrije CJ187-voorraadkisten en MMG Half Mega Inventory

- Twee Workshop-mods toegevoegd: **CJ187-LootChest (2345073965)** en **MMG – Half Mega Inventory Size (2895332994)**. Manifest, launcher-preset en vereisten bevatten nu 17 mods. De MMG-uitbreiding laadt na MMG zelf; CF was al aanwezig.
- Eenmalige generatie van het native `Profiles/CJ_LootChests/LootChests_V106.json`: alle kisten met lege `keyclass` en `openable=2`, dus geen sleutel, lockpick of gereedschap nodig. Geen sleutels/keycards aan de economie toegevoegd.
- Voorraad met eten, drinken, medicijnen, reparatie/tools en bouwmateriaal. Militaire/politiekisten krijgen bovendien een geselecteerd modwapen met passend magazijn en losse munitie. Alle kisten bevatten meerdere voedsel-/drankrollen. Geen kleding in de nieuwe kisttabellen en geen hogere kledingdoelen of nieuwe kledingtypen in de CE.
- Gebruikt bestaande ruime vloerpunten van de lokale Steam-missie en hun werkelijke gebouwpositie/rotatie; geen verdeelde derdepartij-mapconfig of modcode. Eén gekozen gebouw per vak van 850 meter, minstens 350 meter tussen kisten, gekantelde gebouwen overgeslagen, maximaal 256. Een bestaande privé-basecirkel uit de lootverversing wordt bij deze eerste generatie overgeslagen; die privé-instellingen blijven ongewijzigd. Officiële Chernarus-controle: 195 kisten, waarvan 84 bij winkels/horeca, 74 bouw/werkplaatsen, 26 militair/politie, 6 medisch en 5 huizen. Dit zijn configuratielocaties, geen bevestigde live spawns.
- De twee kistklassen hebben een eigen CE-koppeling met doel/minimum 0 en opslaglevensduur; er spawnen via de normale economie geen extra lege kisten. CJ187 verzorgt plaatsing/vulling bij een serverstart. CSV met X/Z-posities onder `Profiles/CJ_LootChests/Servahz-Lootkisten.csv`; `03-Controleren.cmd` toont expliciet CJ187 0.18, het ingestelde aantal en het pad.
- Bestaand CJ187-profiel blijft byte voor byte behouden en wordt met de beheerde configuratie geback-upt; de afgeleide CSV wordt opnieuw gemaakt. Ongeldige/vergrendelde profielen stoppen het instellen vóór wijziging van live missie/mods en worden niet stil vervangen. Coördinaten gebruiken ook op Nederlandse Windows decimalen met punten.
- MMG Half Mega vergroot de ondersteunde bestaande uitrusting; de geselecteerde negen rugzakvarianten behouden hun lootregels. Geen BetterVanillaClothing toegevoegd. Bestaande voedselbalans 0.17, stamina, AI, saves, wachtwoorden, lokale instellingen en basebescherming blijven behouden. Geen wipe of automatische lootverversing.

**Bijwerken:** abonneer host en spelers op beide nieuwe Workshop-mods en wacht op Steam. Stop de server en voer alleen `Servahz-Update-v0.18.0.cmd` uit naast `01-Instellen.cmd`. Deze bevat alle wijzigingen vanaf basis 0.13.0, inclusief 0.17.0; geen volledig pakket nodig. Importeer de bijgewerkte `Mods.html`, start met 02 en controleer met 03. Gebruik de CSV om een voorraadpunt op te zoeken. Start 04/05/06 niet voor deze update. Backups blijven privé onder `.local/Backups` en `Servahz/Backups`.

**Controle:** PowerShell-integratietests voor sleutelvrije voorraad, plaatsing/rotatie en minimale afstand, Nederlandse getalnotatie, CE-records zonder losse kistspawns, passende wapensets, profiel-/wereld-/instellingenbehoud en foutpaden; officiële Chernarus-data en de volledige regressiesuite. Windows controleert ook PowerShell 5.1 en de echte cmd-updater. Nog in-game: CJ187-profielacceptatie door de huidige Workshop-versie, bereikbaarheid/inhoud/openen zonder hulpmiddelen, MMG-vakjes en geen dubbele kisten na herstart. Er is hier geen DayZ-engine of Workshop-PBO uitgevoerd.

## [0.17.0] — 2026-10-28

### Voedselschappen, minder munitie-overdaad en meer ruimte voor modwapens

- De vorige balans liet nog veel hogere munitie-/magazijndoelen dan voedseldoelen toe. Met de officiële Chernarus-data en de 8×/3× testinstellingen: eten/drinken van 12.624 naar 33.664 objectdoelen, munitie/magazijnen van 65.024 naar 19.140. Het totale doel over de beheerde CE-bestanden daalt van 276.940 naar 234.652. Dit zijn configuratiedoelen, geen gemeten aantallen in een draaiende wereld.
- De 27 gekozen houdbare voedsel-/dranktypen krijgen 8× in plaats van 3× bovenop de ingestelde lootfactor, minimum minstens 90% van hun doel en restock 0. Ze mogen ook op vloerposities spawnen. Uitgeschakelde, crafted en eventtypen blijven ongemoeid.
- Winkels, horeca en huizen gebruiken hun oorspronkelijke schapcontainers en coördinaten. De schappen die voedsel toelaten worden volledig food-only; geen tools/kleding/boeken meer op nieuwe spawns van die schappen. Vloercontainers laten ook voedsel toe. De oude twee-/zes-puntenverdeling in een extra ServahzFood-container vervalt.
- Bij deze gebouwen komt maximaal 12 extra lootruimte in winkels/horeca en 3 in huizen, waar bestaande fysieke posities dat toelaten. Ook de schaplimiet krijgt extra ruimte. Nul-capaciteit blijft uit, oorspronkelijke coördinaten blijven gelijk en opnieuw instellen telt de verhoging niet op.
- Gewone vanilla-vuurwapens maximaal 12 per type, of 24 met testvoorraad. De 21 geselecteerde modwapens behouden hun 30/60 doelen, zodat veelvoorkomende vanilla-guns minder overheersen. Geen nieuwe mods of itemtypen toegevoegd.
- Gewone munitie-/magazijndoelen maximaal 90 per type, of 180 met testvoorraad. Wapenaccessoires maximaal 60/120. Bestaande event-/crafted-regels blijven behouden. Losse gewone munitie/magazijnen krijgen 80–100% hoeveelheid; de passende voorraad blijft minstens tweemaal het individuele modwapendoel.
- `03-Controleren.cmd` toont expliciet Lootbalans 0.17 en de daadwerkelijk gegenereerde voedsel-, munitie- en wapendoelen. Eventuele RPT-waarschuwingen met SNAFU/GCGN/Expansion-klassen worden als alleen klassennamen getoond, zonder de volledige logregels of spelersgegevens.
- Geen automatische opruiming of nieuwe lootverversing. Bestaande items, opslag, saves, wachtwoorden en privé-basecirkel blijven behouden. De normale economie vult vrije plekken; oude spullen verdwijnen niet onmiddellijk door lagere doelen.

**Bijwerken:** stop de server en voer `Servahz-Update-v0.17.0.cmd` uit naast `01-Instellen.cmd`. De updater behoudt actieve instellingen en het eigen voorbeeldbestand en maakt een backup. Start met `02-Start-server.cmd`; controleer met `03-Controleren.cmd` dat Lootbalans 0.17 en de nieuwe doelen worden getoond. Controleer ook verse winkels/huizen buiten de beschermde basecirkel. Geen nieuwe Workshop-downloads, wipe of herhaling van 05/06 nodig voor deze configuratie-update.

**Controle:** regressietests en officiële Chernarus-CE-data voor food-only schappen, vloerselectie, voedselminima, caps/compatibele voorraad, behoud van coördinaten en uitgeschakelde loot, idempotentie, saves/instellingen en de privacyveilige RPT-uitvoer. De Windows-suite controleert de echte updater-launcher. De uiteindelijke spawns en verdeling moeten in-game worden beoordeeld; de controle telt configuratiedoelen en leest geen live wereldinventaris.

## [0.16.2] — 2026-10-28

### Aangepast voorbeeldbestand blokkeert geen bestaande installatie

- Het aangeleverde diagnostiekbestand wees uitsluitend naar `config/server.example.json`. Dat bestand is alleen een sjabloon voor de eerste installatie; een bestaande server gebruikt `config/server.local.json`.
- Na validatie van de verplichte lokale serverinstellingen wordt het voorbeeldbestand niet meer als voorwaarde voor een update gecontroleerd. Een afwijkend of ontbrekend voorbeeld is dan toegestaan.
- Het voorbeeldbestand blijft bij bestaande installaties byte voor byte behouden, ook als een toekomstige update een nieuw standaardsjabloon in de payload zou bevatten. De updater kopieert of logt de mogelijke privé-inhoud niet.
- De bescherming van onbekende wijzigingen in scripts en andere beheerde configuratiebestanden blijft actief. Een ontbrekende `server.local.json` of ongeldige actieve instellingen blijven een fout. Geen wijziging aan loot, missiecode, saves, wachtwoorden, profielen of privé-basecoördinaten.

**Bijwerken:** stop de server en voer `Servahz-Update-v0.16.2.cmd` uit in dezelfde bestaande pakketmap. Direct vanaf 0.14.0 mogelijk; eerdere mislukte updates hoeven niet eerst te worden hersteld. Laat zowel `server.example.json` als `server.local.json` staan en deel hun inhoud niet. De knoppen voor proefscan/lootverversing komen met de update mee; installeren plant geen opruiming in.

**Controle:** integratietests met een afwijkend, mogelijk privé voorbeeldbestand en een gewijzigde voorbeeldversie in de payload, ongewijzigde actieve instellingen, geen privé-inhoud in uitvoer, herhaald bijwerken zonder extra backup, ontbrekend ongebruikt voorbeeld en blijvende bescherming van ontbrekende basis-/gewijzigde scriptbestanden. Windows voert ook de echte cmd-launcher uit. De lokale DayZ-proefscan uit 0.16.0 blijft nodig vóór de optionele lootverversing.

## [0.16.1] — 2026-10-28

### Updater herkent gemengde officiële bestanden en Windows-regeleinden

- De oude controle vereiste één exact overeenkomende pakketversie. Nu wordt ieder beheerd bestand apart vergeleken met de gepubliceerde versies vanaf 0.13.0. Een mix na eerdere handmatige of gedeeltelijke updates wordt daardoor geaccepteerd en tot de gekozen versie bijgewerkt.
- Naast de oorspronkelijke bytehash worden UTF-8-teksthashes gebruikt. Windows-/Unix-regeleinden, een UTF-8-BOM en extra laatste regeleinden blokkeren de update niet. Code- en configuratiewijzigingen worden hiermee niet genegeerd.
- Oude, aangepaste of ontbrekende README/CHANGELOG/AGENTS-documentatie geldt niet meer als ongeldige serverbasis. Bestaande documentatie wordt vóór vervanging geback-upt. Ontbrekende bestanden die al in de update zitten, worden opnieuw geplaatst; ontbrekende ongewijzigde basisbestanden blijven een fout.
- Onbekende inhoud in beheerde scripts/configuraties wordt niet overschreven. De melding noemt voortaan alle afwijkende bestandsnamen. Een diagnostiekbestand onder `.local/UpdateDiagnostics` bevat alleen relatieve bestandsnamen en redenen, geen bestandsinhoud, wachtwoorden of saves.
- Saves, lokale serverinstellingen, privé-basecoördinaten, profielen en de optionele proefscan/lootverversing veranderen niet. De complete update bevat de eerdere uitbreidingen; installeren plant nog steeds geen lootverversing in.

**Bijwerken:** gebruik `Servahz-Update-v0.16.1.cmd` in je bestaande pakketmap, naast `01-Instellen.cmd`, met de server gestopt. Je hoeft 0.16.0 niet eerst werkend te krijgen. De wereld- en pakketbackup en de installatie-/statische controles blijven verplicht onderdeel van het script. Als nog een conflict wordt gemeld, deel alleen de genoemde bestandsnamen/diagnostiek, niet `server.local.json`.

**Controle:** integratietests voor een gemengde gedeeltelijke update, UTF-8-BOM/CRLF/laatste regeleinden, oude eigen documentatie en de backup daarvan, herstel van ontbrekende payloadbestanden, weigering van echte wijzigingen en ontbrekende basisbestanden, concrete diagnostiek en behoud van saves/instellingen. De Windows-suite voert de echte cmd-launcher uit. Er is geen wijziging aan de DayZ-missiecode; de proefscan uit 0.16.0 blijft de vereiste lokale controle vóór lootverversing.

## [0.16.0] — 2026-10-28

### Eenmalige lootverversing met beschermde basecirkel

- Optionele missiecode voor een proefscan en daarna een eenmalige verversing van geselecteerde losse wapens, magazijnen, munitie en houdbare voeding op Chernarus. Installeren van de update alleen verwijdert niets en plant geen opruiming in.
- Beschermde cirkel met minimaal 500 meter straal, op lokale X/Z-coördinaten; hoogte telt niet mee. Alle doelitems in die cirkel worden door deze actie overgeslagen. Coördinaten worden alleen lokaal opgeslagen, niet als publieke pakketinstelling.
- Buiten de cirkel alleen expliciete doelklassen op de grond, zonder inventarisouder of cargo/opslag, ook niet in hun attachments. Gebouwen, baseonderdelen, voertuigen, opslag en gedragen items vallen buiten de selectie. Ook zelf gedropte doelitems buiten de cirkel kunnen worden verwijderd.
- `05-Loot-proefscan.cmd`: vraagt eenmalig om de basecoördinaten, maakt een wereldbackup en plant een scan zonder verwijdering. `03-Controleren.cmd` toont cirkel, voortgang, aantallen en voorbeelden. `06-Loot-verversen.cmd`: vereist een afgeronde proefscan met dezelfde cirkel en selectie, maakt opnieuw een wereldbackup en plant de echte uitvoering.
- Beide acties starten twee minuten na de volgende serverstart en lopen in 225 kleine scanvakken. Echte spelers moeten uitgelogd blijven; bij een verbonden speler stopt de actie. AI-inventarissen blijven via hun inventarisouder beschermd.
- Iedere aanvraag wordt vóór de eerste actie eenmalig gemarkeerd. Een afgeronde, onderbroken of mislukte aanvraag wordt na herstart niet automatisch herhaald. Nieuwe loot komt vervolgens via de gewone economie; geen belofte van directe herbezetting van alle plekken.
- De normale vervaltijd van los gedropte spullen blijft gelden, ook binnen de beschermde cirkel. De bescherming geldt voor deze verversing, niet als permanente anti-despawnzone.

**Bijwerken:** gebruik het enkele bestand `Servahz-Update-v0.16.0.cmd` vanaf basis 0.13.0 of een latere ondersteunde update. Daarna is niets gewist. Stop de server, start `05-Loot-proefscan.cmd`, vul `X Z` in, start de server en laat iedereen uitgelogd. Wacht tot `03-Controleren.cmd` `PreviewCompleted` en nul verwijderingen meldt. Controleer de cirkel en voorbeelden. Stop de server normaal; start daarna `06-Loot-verversen.cmd` en opnieuw de server, zonder spelers. Wacht op `ApplyCompleted` voordat je gaat spelen. Backups staan privé onder `.local/Backups/loot-refresh-...`.

**Uitschakelen:** stop de server en voer `05-Loot-proefscan.cmd -Disable` uit. Dit verwijdert de missiehook en de ingeplande aanvraag; het herstelt geen items. Voor herstel gebruik je de wereldbackup, met bijbehorende missie/profielen/configuratie. Gebruik geen opslagbestandenwipe.

**Controle:** PowerShell-integratietests voor coördinaten/radius, proefscanvereiste, dezelfde selectie bij uitvoering, wereldbackup, behoud van saves/wachtwoorden, herhaald instellen en uitschakelen. De objectvrije selectievoorwaarde wordt rechtstreeks uit de Enforce-bron met een C++-compiler getest op cirkelgrenzen, verschillende hoogtes, inventarissen en opslag. Dit is geen DayZ-engine- of compilatietest. De nieuwe missiecode en werkelijke objectselectie moeten eerst met de niet-destructieve proefscan op de lokale server worden gecontroleerd; bij een scriptfout de hook uitschakelen.

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
