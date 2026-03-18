<#
.SYNOPSIS
    Erstellt oder entfernt eine UserCustomAction auf einer SharePoint-Websitesammlung.

.DESCRIPTION
    Dieses Skript verwaltet UserCustomActions auf einer SharePoint 2019-Websitesammlung.
    Es unterstützt zwei Typen von Custom Actions:
    - ScriptLink: Lädt eine JavaScript-Datei auf jeder Seite.
    - ListViewCommandSet: Registriert eine SPFx ListViewCommandSet-Erweiterung für Dokumentbibliotheken.

.PARAMETER siteCollectionUrl
    Die URL der Ziel-Websitesammlung.

.PARAMETER action
    Die auszuführende Aktion: 'Add' zum Erstellen, 'Remove' zum Löschen der Custom Action.

.PARAMETER scriptSrc
    Die URL der zu ladenden JavaScript-Datei (ScriptLink-Parameterset).
    Beispiel: "~site/SiteAssets/HideGetSharingLink.js"

.PARAMETER clientSideComponentId
    Die GUID der SPFx ListViewCommandSet-Komponente (ListViewCommandSet-Parameterset).

.PARAMETER registrationId
    Die RegistrationId für die ListViewCommandSet Custom Action (z.B. "101" für Dokumentbibliotheken, "100" für benutzerdefinierte Listen).

.PARAMETER registrationType
    Der RegistrationType für die ListViewCommandSet Custom Action (z.B. "List", "ContentType", "ProgId", "FileExtension").

.EXAMPLE
    .\handle-userCustomAction.ps1 -siteCollectionUrl "https://sharepoint.contoso.local" -action Add -scriptSrc "~site/SiteAssets/HideGetSharingLink.js"

.EXAMPLE
    .\handle-userCustomAction.ps1 -siteCollectionUrl "https://sharepoint.contoso.local" -action Remove -scriptSrc "~site/SiteAssets/HideGetSharingLink.js"

.EXAMPLE
    .\handle-userCustomAction.ps1 -siteCollectionUrl "https://sharepoint.contoso.local" -action Add -clientSideComponentId "ae7dba38-6364-4819-8f47-774599e3cee9"

.EXAMPLE
    .\handle-userCustomAction.ps1 -siteCollectionUrl "https://sharepoint.contoso.local" -action Remove -clientSideComponentId "ae7dba38-6364-4819-8f47-774599e3cee9"
#>

[CmdletBinding(DefaultParameterSetName = 'ScriptLink')]
param (
    [Parameter(Mandatory)]
    [string]$siteCollectionUrl,

    [Parameter(Mandatory)]
    [ValidateSet('Add', 'Remove')]
    [string]$action,

    [Parameter(Mandatory, ParameterSetName = 'ScriptLink')]
    [string]$scriptSrc,

    [Parameter(Mandatory, ParameterSetName = 'ListViewCommandSet')]
    [string]$clientSideComponentId,

    [Parameter(Mandatory, ParameterSetName = 'ListViewCommandSet')]
    [string]$registrationId ,

    [Parameter(Mandatory, ParameterSetName = 'ListViewCommandSet')]
    [ValidateSet('List', 'ContentType', 'ProgId', 'FileExtension')]
    [string]$registrationType
)

try
{
    Add-Type -Path "C:\program files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
    Add-Type -Path "C:\program files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
}
catch
{
    try
    {
        Add-Type -Path "C:\program files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
        Add-Type -Path "C:\program files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
    }
    catch
    {
        try
        {
            Add-Type -Path "$PSScriptRoot\Microsoft.SharePoint.Client.dll"
            Add-Type -Path "$PSScriptRoot\Microsoft.SharePoint.Client.Runtime.dll"
        }
        catch
        {
            Write-Host "Die SharePoint-Client-DLLs wurden nciht gefunden." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red;
            return;
        }
    }
}

# This may be necessary if you use self signed certificates in your SharePoint farm
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

function Get-UserCustomActions(
    [Parameter(Mandatory)]
    [Microsoft.SharePoint.Client.ClientContext]$ctx,

    [Parameter(Mandatory)]
    [ValidateSet('site', 'web')]
    [string]$scope
)
{
    if ($scope -eq "web") {
        $userCustomActions = $ctx.Web.UserCustomActions
    }
    else {
        $userCustomActions = $ctx.Site.UserCustomActions
    }
    $ctx.Load($userCustomActions)
    $ctx.ExecuteQuery()
    return ,$userCustomActions
}

function Find-UserCustomAction(
    [Parameter(Mandatory)]
    [Microsoft.SharePoint.Client.ClientContext]$ctx,

    [Parameter(Mandatory)]
    [ValidateSet('site', 'web')]
    [string]$scope,

    [Parameter(Mandatory)]
    [string]$location,

    [string]$clientSideComponentId,
    [string]$scriptSrc
)
{
    $userCustomActions = Get-UserCustomActions -ctx $ctx -scope $scope
    foreach ($uca in $userCustomActions) {
        if ($uca.Location -eq $location) {
            if ($location -eq "ScriptLink" -and $uca.ScriptSrc -eq $scriptSrc) {
                return $uca
            }
            elseif ($location -eq "ClientSideExtension.ListViewCommandSet" -and $uca.ClientSideComponentId -eq $clientSideComponentId) {
                return $uca
            }
        }
    }
    return $null
}

function Add-ScriptLinkCustomAction(
    [Parameter(Mandatory)]
    [Microsoft.SharePoint.Client.ClientContext]$ctx,

    [Parameter(Mandatory)]
    [ValidateSet('site', 'web')]
    [string]$scope,

    [Parameter(Mandatory)]
    [string]$scriptSrc,

    [int]$sequence = 1
)
{
    $existing = Find-UserCustomAction -ctx $ctx -scope $scope -location "ScriptLink" -scriptSrc $scriptSrc
    if ($existing) {
        Write-Host "ScriptLink UserCustomAction für '$scriptSrc' ist bereits vorhanden." -ForegroundColor Yellow
        return
    }

    $userCustomActions = Get-UserCustomActions -ctx $ctx -scope $scope
    $uca = $userCustomActions.Add()
    $uca.Location = "ScriptLink"
    $uca.ScriptSrc = $scriptSrc
    $uca.Sequence = $sequence
    $uca.Update()
    Write-Host "Speichere ScriptLink UserCustomAction..." -NoNewline
    try {
        $ctx.ExecuteQuery()
        Write-Host " Erfolg!" -ForegroundColor Green
    }
    catch {
        Write-Host " Fehlgeschlagen!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

function Remove-ScriptLinkCustomAction(
    [Parameter(Mandatory)]
    [Microsoft.SharePoint.Client.ClientContext]$ctx,

    [Parameter(Mandatory)]
    [ValidateSet('site', 'web')]
    [string]$scope,

    [Parameter(Mandatory)]
    [string]$scriptSrc
)
{
    $uca = Find-UserCustomAction -ctx $ctx -scope $scope -location "ScriptLink" -scriptSrc $scriptSrc
    if ($uca) {
        $uca.DeleteObject()
        try {
            $ctx.ExecuteQuery()
            Write-Host "ScriptLink UserCustomAction für '$scriptSrc' wurde gelöscht." -ForegroundColor Green
        }
        catch {
            Write-Host "Löschen fehlgeschlagen!" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
    else {
        Write-Host "ScriptLink UserCustomAction für '$scriptSrc' nicht gefunden." -ForegroundColor Yellow
    }
}

function Add-ListViewCommandSetCustomAction(
    [Parameter(Mandatory)]
    [Microsoft.SharePoint.Client.ClientContext]$ctx,

    [Parameter(Mandatory)]
    [ValidateSet('site', 'web')]
    [string]$scope,

    [Parameter(Mandatory)]
    [string]$clientSideComponentId,

    [Parameter(Mandatory)]
    [string]$registrationId,

    [Parameter(Mandatory)]
    [ValidateSet('List', 'ContentType', 'ProgId', 'FileExtension')]
    [string]$registrationType,

    [string]$clientSideComponentProperties = "{}"
)
{
    $existing = Find-UserCustomAction -ctx $ctx -scope $scope -location "ClientSideExtension.ListViewCommandSet" -clientSideComponentId $clientSideComponentId
    if ($existing) {
        Write-Host "ListViewCommandSet UserCustomAction für '$clientSideComponentId' ist bereits vorhanden." -ForegroundColor Yellow
        return
    }

    $userCustomActions = Get-UserCustomActions -ctx $ctx -scope $scope
    $uca = $userCustomActions.Add()
    $uca.Location = "ClientSideExtension.ListViewCommandSet"
    $uca.ClientSideComponentId = $clientSideComponentId
    $uca.ClientSideComponentProperties = $clientSideComponentProperties
    $uca.RegistrationId = $registrationId
    $uca.RegistrationType = [Microsoft.SharePoint.Client.UserCustomActionRegistrationType]::$registrationType
    $uca.Update()
    Write-Host "Speichere ListViewCommandSet UserCustomAction..." -NoNewline
    try {
        $ctx.ExecuteQuery()
        Write-Host " Erfolg!" -ForegroundColor Green
    }
    catch {
        Write-Host " Fehlgeschlagen!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

function Remove-ListViewCommandSetCustomAction(
    [Parameter(Mandatory)]
    [Microsoft.SharePoint.Client.ClientContext]$ctx,

    [Parameter(Mandatory)]
    [ValidateSet('site', 'web')]
    [string]$scope,

    [Parameter(Mandatory)]
    [string]$clientSideComponentId
)
{
    $uca = Find-UserCustomAction -ctx $ctx -scope $scope -location "ClientSideExtension.ListViewCommandSet" -clientSideComponentId $clientSideComponentId
    if ($uca) {
        $uca.DeleteObject()
        try {
            $ctx.ExecuteQuery()
            Write-Host "ListViewCommandSet UserCustomAction für '$clientSideComponentId' wurde gelöscht." -ForegroundColor Green
        }
        catch {
            Write-Host "Löschen fehlgeschlagen!" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
    else {
        Write-Host "ListViewCommandSet UserCustomAction für '$clientSideComponentId' nicht gefunden." -ForegroundColor Yellow
    }
}

$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteCollectionUrl)
$ctx.Credentials = [System.Net.CredentialCache]::DefaultCredentials

switch ($PSCmdlet.ParameterSetName) {
    'ScriptLink' {
        if ($action -eq "Add") {
            Add-ScriptLinkCustomAction -ctx $ctx -scope "site" -scriptSrc $scriptSrc
        }
        else {
            Remove-ScriptLinkCustomAction -ctx $ctx -scope "site" -scriptSrc $scriptSrc
        }
    }
    'ListViewCommandSet' {
        if ($action -eq "Add") {
            Add-ListViewCommandSetCustomAction -ctx $ctx -scope "site" -clientSideComponentId $clientSideComponentId -registrationId $registrationId -registrationType $registrationType
        }
        else {
            Remove-ListViewCommandSetCustomAction -ctx $ctx -scope "site" -clientSideComponentId $clientSideComponentId
        }
    }
}