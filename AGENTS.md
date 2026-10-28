# Onderhoud van dit serverpakket

- Werk bij iedere zichtbare functionele update `CHANGELOG.md` bij. Vermeld het gedrag, de lokaal te vervangen bestanden/opdrachten, uitgevoerde controles en wat nog in-game moet worden gecontroleerd.
- Geef nieuwe functionele releases een volgende versie met een eigen changelogsectie. De workflow `release.yml` publiceert de bijbehorende notes wanneer een `vMAJOR.MINOR.PATCH`-tag wordt gepusht. Publiceer alleen binnen de door de gebruiker gevraagde scope.
- Bewaar lokale configuratie, wachtwoorden, `.local`, wereldsaves en gedeelde serverlogs buiten commits en releases.

- Vaste basis: v0.13.0. Nieuwe releases publiceren één `Servahz-Update-vX.Y.Z.cmd` met `.github/scripts/build_update.py`; geen volledige Windows-ZIP toevoegen. De update bevat wijzigingen sinds de basis en moet save-/wachtwoord-/instellingenbehoud en foutpaden testen. Nieuwe bestandverwijderingen vragen om een expliciete migratie.
