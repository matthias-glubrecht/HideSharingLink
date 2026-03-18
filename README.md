# HideSharingLink

SPFx-Lösung für SharePoint 2019, die den "Teilen"/"Share"-Button in Dokumentbibliotheken ausblendet.

## Funktionsweise

Die Lösung besteht aus zwei Komponenten:

- **ListViewCommandSet** (`HideLinksCommandSet`) — SPFx-Erweiterung, die per CSS den "Share"-Button in der Kommandoleiste und im Kontextmenü moderner Dokumentbibliotheken versteckt.
- **ScriptLink** (`HideGetSharingLink.js`) — JavaScript-Datei, die den "Get a link"-Button auf klassischen Seiten ausblendet.

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
