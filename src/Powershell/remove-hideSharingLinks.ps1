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

.PARAMETER credentials
    Die Anmeldeinformationen für die Verbindung zur Ziel-Websitesammlung (Typ System.Net.ICredentials).
    Akzeptiert ein PSCredential (z. B. das Ergebnis von (Get-Credential)), das PowerShell automatisch
    in ein System.Net.NetworkCredential umwandelt, oder ein beliebiges ICredentials-Objekt.
    Wird der Parameter weggelassen, kommen über den Standardwert
    [System.Net.CredentialCache]::DefaultCredentials die Anmeldeinformationen des aktuell
    angemeldeten Windows-Benutzers zum Einsatz (integrierte Authentifizierung).
    Der Wert wird unverändert an handle-userCustomAction.ps1 weitergereicht.

.EXAMPLE
    .\remove-hideSharingLinks.ps1 -siteCollectionUrl "https://sharepoint.contoso.local/sites/test" -appCatalogUrl "https://sharepoint.contoso.local/sites/appcatalog" -credentials (Get-Credential)
#>

param
(
    [Parameter(Mandatory=$true)]
    [string]$siteCollectionUrl,
    [Parameter(Mandatory=$true)]
    [string]$appCatalogUrl,
    [System.Net.ICredentials]$credentials = [System.Net.CredentialCache]::DefaultCredentials
)

$scriptSrc = "$appCatalogUrl/ClientSideAssets/c959a247-1ad1-4d31-ac20-b9957ac8cb47/HideGetSharingLink.js"

& "$PSScriptRoot\handle-userCustomAction.ps1" `
    -siteCollectionUrl $siteCollectionUrl `
    -action "Remove" `
    -scriptSrc $scriptSrc `
    -credentials $credentials

& "$PSScriptRoot\handle-userCustomAction.ps1" `
    -siteCollectionUrl $siteCollectionUrl `
    -action "Remove" `
    -clientSideComponentId "ae7dba38-6364-4819-8f47-774599e3cee9" `
    -registrationId "101" `
    -registrationType "List"`
    -credentials $credentials
