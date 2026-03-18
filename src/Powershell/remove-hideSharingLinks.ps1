<#
.SYNOPSIS
    Entfernt die HideSharingLinks-Lösung von einer SharePoint-Websitesammlung.

.DESCRIPTION
    Dieses Skript entfernt die UserCustomActions der HideSharingLinks-Lösung:
    - Den ScriptLink für die JavaScript-Datei HideGetSharingLink.js.
    - Den ListViewCommandSet für Dokumentbibliotheken.

.PARAMETER siteCollectionUrl
    Die URL der Ziel-Websitesammlung, von der die Lösung entfernt werden soll.

.PARAMETER appCatalogUrl
    Die URL des App-Katalogs, aus dem die ClientSideAssets geladen wurden.

.EXAMPLE
    .\remove-hideSharingLinks.ps1 -siteCollectionUrl "https://sharepoint.contoso.local/sites/test" -appCatalogUrl "https://sharepoint.contoso.local/sites/appcatalog"
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
    -action "Remove" `
    -scriptSrc $scriptSrc

& "$PSScriptRoot\handle-userCustomAction.ps1" `
    -siteCollectionUrl $siteCollectionUrl `
    -action "Remove" `
    -clientSideComponentId "ae7dba38-6364-4819-8f47-774599e3cee9" `
    -registrationId "101" `
    -registrationType "List"
