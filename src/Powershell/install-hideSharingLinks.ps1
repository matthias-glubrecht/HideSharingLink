<#
.SYNOPSIS
    Installiert die HideSharingLinks-Lösung auf einer SharePoint-Websitesammlung.

.DESCRIPTION
    Dieses Skript registriert die benötigten UserCustomActions für die HideSharingLinks-Lösung:
    - Ein ScriptLink, das die JavaScript-Datei HideGetSharingLink.js aus den ClientSideAssets lädt.
    - Ein ListViewCommandSet, das die SPFx-Erweiterung für Dokumentbibliotheken registriert.

.PARAMETER siteCollectionUrl
    Die URL der Ziel-Websitesammlung, auf der die Lösung installiert werden soll.

.PARAMETER appCatalogUrl
    Die URL des App-Katalogs, aus dem die ClientSideAssets geladen werden.

.EXAMPLE
    .\install-hideSharingLinks.ps1 -siteCollectionUrl "https://sharepoint.contoso.local/sites/test" -appCatalogUrl "https://sharepoint.contoso.local/sites/appcatalog"
#>

param
(
    [Parameter(Mandatory=$true)]
    [string]$siteCollectionUrl,
    [Parameter(Mandatory=$true)]
    [string]$appCatalogUrl
)

$scriptSrc = "$appCatalogUrl/ClientSideAssets/c959a247-1ad1-4d31-ac20-b9957ac8cb47/HideGetSharingLink.js"

& "$PSScriptRoot\handle-userCustomAction.ps1" `
    -siteCollectionUrl $siteCollectionUrl `
    -action "Add" `
    -scriptSrc $scriptSrc

& "$PSScriptRoot\handle-userCustomAction.ps1" `
    -siteCollectionUrl $siteCollectionUrl `
    -action "Add" `
    -clientSideComponentId "ae7dba38-6364-4819-8f47-774599e3cee9" `
    -registrationId "101" `
    -registrationType "List"
