[CmdletBinding()]
param(
    [ValidateSet('Discovery','OwnershipCheck','QuarterlyReview')]
    [string] $Mode = 'Discovery',
    [string] $ServerCsv = "$PSScriptRoot\..\config\FileServers.csv",
    [string] $SettingsPath = "$PSScriptRoot\..\config\Settings.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module ActiveDirectory -ErrorAction Stop
. "$PSScriptRoot\modules\Get-AccessGroupOwner.ps1"
. "$PSScriptRoot\modules\Get-FileShareAclRecord.ps1"

if (-not (Test-Path $SettingsPath)) { throw "Settings file not found: $SettingsPath" }
$settings = Get-Content -LiteralPath $SettingsPath -Raw | ConvertFrom-Json
$outputPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot $settings.Output.Path))
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

function Get-PrincipalAdObject {
    param([string]$Identity)
    if (-not $Identity) { return $null }
    $leaf = ($Identity -split '\\')[-1]
    try { Get-ADGroup -Identity $leaf -Properties ManagedBy,Description,$settings.Ownership.ExtensionAttribute -ErrorAction Stop }
    catch {
        try { Get-ADUser -Identity $leaf -Properties Enabled,UserPrincipalName,Mail -ErrorAction Stop }
        catch { $null }
    }
}

switch ($Mode) {
    'Discovery' {
        if (-not (Test-Path $ServerCsv)) { throw "Server inventory not found: $ServerCsv" }
        $inventory = Import-Csv -LiteralPath $ServerCsv | Where-Object { $_.Enabled -match '^(?i:true|1|yes)$' }
        $records = [System.Collections.Generic.List[object]]::new()

        foreach ($item in $inventory) {
            $root = "\\$($item.Server)\$($item.Share)"
            Write-Host "Scanning $root"
            $recurse = $item.Recurse -match '^(?i:true|1|yes)$'
            foreach ($acl in Get-FileShareAclRecord -Path $root -Recurse:$recurse -IncludeInherited:([bool]$settings.Discovery.IncludeInherited)) {
                $principalType = 'Unresolved'
                $owner = $null
                $adObject = Get-PrincipalAdObject -Identity $acl.Principal
                if ($adObject -is [Microsoft.ActiveDirectory.Management.ADGroup]) {
                    $principalType = 'Group'
                    $owner = Get-AccessGroupOwner -Group $adObject -ExtensionAttribute $settings.Ownership.ExtensionAttribute -DescriptionOwnerPattern $settings.Ownership.DescriptionOwnerPattern -RequireEmail:([bool]$settings.Ownership.RequireOwnerEmail)
                } elseif ($adObject -is [Microsoft.ActiveDirectory.Management.ADUser]) {
                    $principalType = 'User'
                }

                $records.Add([pscustomobject]@{
                    Server=$item.Server; Share=$item.Share; Directory=$acl.Directory; Principal=$acl.Principal
                    PrincipalType=$principalType; Permission=$acl.Permission; AccessType=$acl.AccessType; Inherited=$acl.Inherited
                    Owner=$owner.Owner; OwnerUPN=$owner.OwnerUPN; OwnerSource=$owner.OwnerSource; OwnershipStatus=$owner.OwnershipStatus
                    Detail=$owner.Detail; ScanError=$acl.Error
                })
            }
        }
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $records | Export-Csv (Join-Path $outputPath "AccessRegister-$stamp.csv") -NoTypeInformation -Encoding UTF8
        $records | Where-Object { $_.PrincipalType -eq 'Group' -and $_.OwnershipStatus -ne 'OWNER_VERIFIED' } |
            Export-Csv (Join-Path $outputPath "OwnershipExceptions-$stamp.csv") -NoTypeInformation -Encoding UTF8
        Write-Host "Discovery complete: $outputPath"
    }

    'OwnershipCheck' {
        $latest = Get-ChildItem $outputPath -Filter 'AccessRegister-*.csv' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $latest) { throw 'No prior discovery register found. Run Discovery first.' }
        $groups = Import-Csv $latest.FullName | Where-Object PrincipalType -eq 'Group' | Select-Object Principal -Unique
        $results = foreach ($g in $groups) {
            $obj = Get-PrincipalAdObject $g.Principal
            if (-not $obj) { [pscustomobject]@{ Group=$g.Principal; Owner=$null; OwnerUPN=$null; OwnerSource=$null; OwnershipStatus='GROUP_NOT_FOUND'; Detail='Group cannot be resolved' }; continue }
            $o = Get-AccessGroupOwner -Group $obj -ExtensionAttribute $settings.Ownership.ExtensionAttribute -DescriptionOwnerPattern $settings.Ownership.DescriptionOwnerPattern -RequireEmail:([bool]$settings.Ownership.RequireOwnerEmail)
            [pscustomobject]@{ Group=$g.Principal; Owner=$o.Owner; OwnerUPN=$o.OwnerUPN; OwnerSource=$o.OwnerSource; OwnershipStatus=$o.OwnershipStatus; Detail=$o.Detail }
        }
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $exceptions = @($results | Where-Object OwnershipStatus -ne 'OWNER_VERIFIED')
        $exceptions | Export-Csv (Join-Path $outputPath "DailyOwnershipExceptions-$stamp.csv") -NoTypeInformation -Encoding UTF8
        Write-Host "Ownership check complete. Exceptions: $($exceptions.Count)"
        # Notification transport is intentionally left environment-specific in the publication baseline.
    }

    'QuarterlyReview' {
        $latest = Get-ChildItem $outputPath -Filter 'AccessRegister-*.csv' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $latest) { throw 'No prior discovery register found. Run Discovery first.' }
        $period = "{0}-Q{1}" -f (Get-Date).Year, [math]::Ceiling((Get-Date).Month / 3)
        Import-Csv $latest.FullName | Where-Object OwnershipStatus -eq 'OWNER_VERIFIED' | ForEach-Object {
            $_ | Add-Member NoteProperty ReviewPeriod $period -Force
            $_ | Add-Member NoteProperty Decision '' -Force
            $_ | Add-Member NoteProperty Reviewer '' -Force
            $_ | Add-Member NoteProperty ReviewDate '' -Force
            $_ | Add-Member NoteProperty Comments '' -Force
            $_
        } | Export-Csv (Join-Path $outputPath "QuarterlyReview-$period.csv") -NoTypeInformation -Encoding UTF8
        Write-Host "Quarterly review dataset created for $period"
    }
}
