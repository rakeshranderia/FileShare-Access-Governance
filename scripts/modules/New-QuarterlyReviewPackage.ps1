function New-QuarterlyReviewPackage {
    [CmdletBinding()]
    param([Parameter(Mandatory)][array]$Records,[Parameter(Mandatory)][string]$OutputPath,[Parameter(Mandatory)][string]$ReviewPeriod,[Parameter(Mandatory)][string]$TemplatePath,[string]$DueDate)
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    $template=Get-Content -LiteralPath $TemplatePath -Raw
    foreach($ownerGroup in ($Records | Where-Object {$_.OwnershipStatus -eq 'OWNER_VERIFIED' -and $_.OwnerUPN} | Group-Object OwnerUPN)){
        $ownerRecords=@($ownerGroup.Group); $owner=$ownerRecords[0].Owner; $safe=($ownerGroup.Name -replace '[^A-Za-z0-9._-]','_')
        $csv=Join-Path $OutputPath "$ReviewPeriod-$safe.csv"
        $ownerRecords | Select-Object Server,Share,Directory,Principal,PrincipalType,Permission,AccessType,Inherited,Owner,OwnerUPN,@{n='ReviewPeriod';e={$ReviewPeriod}},@{n='Decision';e={''}},@{n='Reviewer';e={''}},@{n='ReviewDate';e={''}},@{n='Comments';e={''}},@{n='RemediationRequired';e={''}},@{n='RemediationStatus';e={''}} | Export-Csv $csv -NoTypeInformation -Encoding UTF8
        $areas=($ownerRecords | Group-Object Server,Share | ForEach-Object {"<li>$([System.Net.WebUtility]::HtmlEncode($_.Name)) - $($_.Count) ACL records</li>"}) -join "`n"
        $body=$template.Replace('{{OwnerName}}',[string]$owner).Replace('{{ReviewPeriod}}',$ReviewPeriod).Replace('{{DueDate}}',[string]$DueDate).Replace('{{ReviewAreas}}',$areas).Replace('{{ReviewFile}}',[IO.Path]::GetFileName($csv))
        Set-Content -LiteralPath (Join-Path $OutputPath "$ReviewPeriod-$safe.html") -Value $body -Encoding UTF8
    }
}
