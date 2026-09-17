[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Discovery','OwnershipCheck','QuarterlyReview')][string]$Mode='Discovery',
    [string]$ServerCsv="$PSScriptRoot\..\config\FileServers.csv",
    [string]$SettingsPath="$PSScriptRoot\..\config\Settings.json",
    [string]$ReviewPeriod,
    [string]$DueDate
)
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
Import-Module ActiveDirectory -ErrorAction Stop
Get-ChildItem "$PSScriptRoot\modules\*.ps1" | ForEach-Object {. $_.FullName}
if(-not(Test-Path $SettingsPath)){throw "Settings file not found: $SettingsPath"}
$settings=Get-Content -LiteralPath $SettingsPath -Raw | ConvertFrom-Json
$outputPath=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot $settings.Output.Path)); New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
$logPath=Join-Path $outputPath 'AccessGovernance.log'
function Write-AgLog([string]$Message,[string]$Level='INFO'){"$(Get-Date -Format s) [$Level] $Message" | Tee-Object -FilePath $logPath -Append | Write-Verbose}
function Get-LatestRegister { $x=Get-ChildItem $outputPath -Filter 'AccessRegister-*.csv' | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if(-not$x){throw 'No prior discovery register found. Run Discovery first.'}; $x }
function Get-GroupObject([string]$Identity){$leaf=($Identity -split '\\')[-1]; try{$props=@('ManagedBy','Description'); if($settings.Ownership.ExtensionAttribute){$props+=$settings.Ownership.ExtensionAttribute}; Get-ADGroup -Identity $leaf -Properties $props -ErrorAction Stop}catch{$null}}

Write-AgLog "Starting mode=$Mode"
switch($Mode){
'Discovery'{
 if(-not(Test-Path $ServerCsv)){throw "Server inventory not found: $ServerCsv"}
 $inventory=Import-Csv $ServerCsv | Where-Object {$_.Enabled -match '^(?i:true|1|yes)$'}; $records=[System.Collections.Generic.List[object]]::new()
 foreach($item in $inventory){
  $root="\\$($item.Server)\$($item.Share)"; Write-AgLog "Scanning $root"; $recurse=$item.Recurse -match '^(?i:true|1|yes)$'
  foreach($acl in Get-FileShareAclRecord -Path $root -Recurse:$recurse -IncludeInherited:([bool]$settings.Discovery.IncludeInherited)){
   if(-not $acl.Principal){$records.Add([pscustomobject]@{Server=$item.Server;Share=$item.Share;Directory=$acl.Directory;ObjectOwner=$acl.ObjectOwner;Principal=$null;Sid=$null;PrincipalType='Unresolved';Permission=$null;AccessType=$null;Inherited=$null;ResolutionStatus='SCAN_ERROR';DirectUserPermission=$false;Owner=$null;OwnerUPN=$null;OwnerSource=$null;OwnershipStatus='NOT_APPLICABLE';Detail=$null;ScanStatus=$acl.ScanStatus;ScanError=$acl.ScanError});continue}
   $p=Resolve-AccessPrincipal $acl.Principal; $o=$null
   if($p.PrincipalType -eq 'Group'){$g=Get-GroupObject $acl.Principal; if($g){$o=Get-AccessGroupOwner -Group $g -ExtensionAttribute $settings.Ownership.ExtensionAttribute -DescriptionOwnerPattern $settings.Ownership.DescriptionOwnerPattern -RequireEmail:([bool]$settings.Ownership.RequireOwnerEmail)}}
   $status=if($p.PrincipalType -eq 'Group'){$o.OwnershipStatus}else{'NOT_APPLICABLE'}
   $records.Add([pscustomobject]@{Server=$item.Server;Share=$item.Share;Directory=$acl.Directory;ObjectOwner=$acl.ObjectOwner;Principal=$acl.Principal;Sid=$p.Sid;PrincipalType=$p.PrincipalType;Permission=$acl.Permission;AccessType=$acl.AccessType;Inherited=$acl.Inherited;ResolutionStatus=$p.ResolutionStatus;DirectUserPermission=($p.PrincipalType -eq 'User');Owner=$o.Owner;OwnerUPN=$o.OwnerUPN;OwnerSource=$o.OwnerSource;OwnershipStatus=$status;Detail=if($o){$o.Detail}else{$p.Detail};ScanStatus=$acl.ScanStatus;ScanError=$acl.ScanError})
  }
 }
 $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $register=Join-Path $outputPath "AccessRegister-$stamp.csv"; $records | Export-Csv $register -NoTypeInformation -Encoding UTF8
 $records | Where-Object {($_.PrincipalType -eq 'Group' -and $_.OwnershipStatus -ne 'OWNER_VERIFIED') -or $_.ResolutionStatus -ne 'RESOLVED' -or ($settings.Discovery.FlagDirectUserPermissions -and $_.DirectUserPermission)} | Export-Csv (Join-Path $outputPath "AccessExceptions-$stamp.csv") -NoTypeInformation -Encoding UTF8
 Write-AgLog "Discovery complete. Records=$($records.Count)"
}
'OwnershipCheck'{
 $latest=Get-LatestRegister; $groups=Import-Csv $latest.FullName | Where-Object PrincipalType -eq 'Group' | Select-Object Principal -Unique
 $results=@(foreach($g in $groups){$obj=Get-GroupObject $g.Principal; if(-not$obj){[pscustomobject]@{ExceptionKey="$($g.Principal)|GROUP_NOT_FOUND";Group=$g.Principal;Owner=$null;OwnerUPN=$null;OwnerSource=$null;OwnershipStatus='GROUP_NOT_FOUND';Detail='Group cannot be resolved'};continue}; $o=Get-AccessGroupOwner -Group $obj -ExtensionAttribute $settings.Ownership.ExtensionAttribute -DescriptionOwnerPattern $settings.Ownership.DescriptionOwnerPattern -RequireEmail:([bool]$settings.Ownership.RequireOwnerEmail); if($o.OwnershipStatus -ne 'OWNER_VERIFIED'){[pscustomobject]@{ExceptionKey="$($g.Principal)|$($o.OwnershipStatus)";Group=$g.Principal;Owner=$o.Owner;OwnerUPN=$o.OwnerUPN;OwnerSource=$o.OwnerSource;OwnershipStatus=$o.OwnershipStatus;Detail=$o.Detail}}})
 $history=Update-ExceptionHistory -CurrentExceptions $results -HistoryPath (Join-Path $outputPath 'OwnershipExceptionHistory.csv'); $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $history.Current | Export-Csv (Join-Path $outputPath "DailyOwnershipExceptions-$stamp.csv") -NoTypeInformation -Encoding UTF8
 if($history.Current.Count -gt 0 -and $settings.Notifications.GenerateHtml){$html=New-OwnershipExceptionEmail -Exceptions $history.Current -Resolved $history.Resolved -TemplatePath (Join-Path $PSScriptRoot '..\templates\Daily-Ownership-Exception-Email.html'); Set-Content (Join-Path $outputPath "DailyOwnershipExceptions-$stamp.html") $html -Encoding UTF8}
 Write-AgLog "Ownership check complete. Current=$($history.Current.Count); Resolved=$($history.Resolved.Count)"
}
'QuarterlyReview'{
 $latest=Get-LatestRegister; if(-not$ReviewPeriod){$ReviewPeriod="{0}-Q{1}" -f (Get-Date).Year,[math]::Ceiling((Get-Date).Month/3)}; if(-not$DueDate){$DueDate=(Get-Date).AddDays(14).ToString('yyyy-MM-dd')}
 $records=@(Import-Csv $latest.FullName); $dir=Join-Path $outputPath "Quarterly-$ReviewPeriod"; New-QuarterlyReviewPackage -Records $records -OutputPath $dir -ReviewPeriod $ReviewPeriod -DueDate $DueDate -TemplatePath (Join-Path $PSScriptRoot '..\templates\Quarterly-Owner-Review-Email.html')
 $records | Where-Object {$_.PrincipalType -eq 'Group' -and $_.OwnershipStatus -ne 'OWNER_VERIFIED'} | Export-Csv (Join-Path $dir 'GovernanceExceptions.csv') -NoTypeInformation -Encoding UTF8
 Write-AgLog "Quarterly package created: $dir"
}}
