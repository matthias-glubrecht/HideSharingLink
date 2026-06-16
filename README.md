# HideSharingLink

SPFx-Lösung für SharePoint 2019, die den "Teilen"/"Share"-Button in Dokumentbibliotheken ausblendet.

**Aktuelle Version:** 1.2.1

## Funktionsweise

Die Lösung besteht aus zwei Komponenten:

- **ListViewCommandSet** (`HideLinksCommandSet`) — SPFx-Erweiterung, die per CSS den "Share"-Button in der Kommandoleiste und im Kontextmenü moderner Dokumentbibliotheken versteckt.
- **ScriptLink** (`HideGetSharingLink.js`) — JavaScript-Datei, die den "Get a link"-Button auf klassischen Seiten ausblendet.

Beide Komponenten injizieren ein `<style>`-Tag in den `<head>`. Damit das Tag bei mehrfachem Laden (mehrere WebParts/Frames, Doppelregistrierung in Site- und Web-Scope) nur **einmal** angelegt wird, schützt sich jede Komponente über eine eindeutige `STYLE_ID` und einen `document.getElementById`-Check.

## Voraussetzungen

- SharePoint Server 2019
- Node.js 8.17 (kompatible Version für SPFx 1.4.1)
- App-Katalog auf der SharePoint-Farm
- `DenyPermissionsMask` darf `AddAndCustomizePages` **nicht** enthalten (siehe Abschnitt Berechtigungen)

## Erstellen und Paketieren

```bash
gulp bundle --ship
gulp package-solution --ship
```

Das Paket wird unter `sharepoint/solution/hide-sharing-link.sppkg` erstellt.

### Wie kommt die JS-Datei in `ClientSideAssets/`?

Das ist auch für andere SPFx-Projekte interessant, die zusätzlich zur kompilierten Bundle-Ausgabe noch statische Assets (z.B. ein klassisches `ScriptLink`-Skript) im selben `.sppkg` ausliefern wollen. Die Pipeline hat drei kooperierende Bestandteile:

1. **`gulpfile.js`** definiert einen Post-Build-Subtask `copy-extra-assets`, der die Quelldatei nach `temp/deploy/` kopiert:

   ```js
   const copyExtraAssets = build.subTask('copy-extra-assets', function (gulp, buildOptions, done) {
     return gulp.src(path.resolve(__dirname, 'sharepoint/assets/HideGetSharingLink.js'))
       .pipe(gulp.dest(path.resolve(__dirname, 'temp/deploy')));
   });
   build.rig.addPostBuildTask(copyExtraAssets);
   ```

2. **`config/copy-assets.json`** zeigt mit `deployCdnPath` auf genau diesen Ordner — alles, was dort liegt, wird beim Packaging als CDN-Asset behandelt:

   ```json
   { "deployCdnPath": "temp/deploy" }
   ```

3. **`config/package-solution.json`** schaltet `includeClientSideAssets: true`. Dadurch nimmt `gulp package-solution --ship` den Inhalt von `temp/deploy/` mit ins `.sppkg` und legt ihn nach dem Upload in den App-Katalog unter `ClientSideAssets/<solution-id>/` ab.

   Erreichbar ist die Datei dann unter:

   ```
   <appCatalogUrl>/ClientSideAssets/<solution-id>/HideGetSharingLink.js
   ```

   Genau diese URL setzt das Install-Skript als `ScriptSrc` der UserCustomAction.

So lassen sich beliebige zusätzliche Dateien (JS, CSS, Bilder) im selben Paket ausliefern, ohne sie manuell in eine Bibliothek hochzuladen.

## Deployment

### 1. App-Katalog

Die `.sppkg`-Datei in den App-Katalog hochladen. Die Lösung nutzt `skipFeatureDeployment: true` und sollte mandantenweit bereitgestellt werden. Sonst müsste man die Lösung jeder Websitesammlung einzeln hinzufügen. Aber keine Sorge: ohne Registrierung wird die Lösung nirgends aktiviert!

### 2. UserCustomActions registrieren

Die Registrierung erfolgt über PowerShell-Skripte im Ordner `src/Powershell/`:

```powershell
.\install-hideSharingLinks.ps1 `
    -siteCollectionUrl "https://sharepoint.contoso.local/sites/meineSite" `
    -appCatalogUrl "https://sharepoint.contoso.local/sites/appcatalog"
```

Dieses Skript registriert automatisch:
- Einen **ScriptLink** für `HideGetSharingLink.js` (klassische Seiten)
- Einen **ListViewCommandSet** für Dokumentbibliotheken (moderne Seiten)

### Deinstallation

Mit `remove-hideSharingLinks.ps1` können alle CustomActions wieder entfernt werden:

```powershell
.\remove-hideSharingLinks.ps1 `
    -siteCollectionUrl "https://sharepoint.contoso.local/sites/meineSite" `
    -appCatalogUrl "https://sharepoint.contoso.local/sites/appcatalog"
```

## Berechtigungen

Zum Registrieren der UserCustomActions muss `AddAndCustomizePages` erlaubt sein. Falls die Websitesammlung dies sperrt, muss auf dem SharePoint-Server Folgendes ausgeführt werden:

```powershell
$site = Get-SPSite "https://sharepoint.contoso.local/sites/meineSite"
$site.DenyPermissionsMask = $site.DenyPermissionsMask -band (-bnot [Microsoft.SharePoint.SPBasePermissions]::AddAndCustomizePages)
```

## Projektstruktur

| Pfad | Beschreibung |
|---|---|
| `src/extensions/hideLinks/` | SPFx ListViewCommandSet (TypeScript) |
| `sharepoint/assets/HideGetSharingLink.js` | ScriptLink für klassische Seiten |
| `src/Powershell/` | Installations- und Verwaltungsskripte |
| `config/package-solution.json` | SPFx-Paketkonfiguration |

## Versionsverlauf

| Version | Datum | Beschreibung |
|---|---|---|
| 1.2.1 | 2026-06-16 | PowerShell-Skripte: `credentials`-Parameter auf Typ `ICredentials` umgestellt — ohne Angabe greift nun die integrierte Authentifizierung des angemeldeten Windows-Benutzers; Parameterdokumentation ergänzt. Kleinere CSS-Formatierung im ScriptLink-Asset. |
| 1.2.0 | 2026-05-07 | Schutz gegen doppelte CSS-Injection im klassischen ScriptLink-Asset (`HideGetSharingLink.js`) |
| 1.1.1 | 2026-04-01 | Fix: Style-Tag wurde mehrfach injiziert |
| 1.1.0 | 2026-04-01 | Versionsanhebung auf 1.1.0 |
| 1.0.0 | — | Erstveröffentlichung |
