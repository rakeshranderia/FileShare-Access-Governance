function Update-ExceptionHistory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][array]$CurrentExceptions,[Parameter(Mandatory)][string]$HistoryPath)
    $now=Get-Date
    $previous=@{}
    if(Test-Path $HistoryPath){Import-Csv $HistoryPath | ForEach-Object {$previous[$_.ExceptionKey]=$_}}
    $rows=foreach($e in $CurrentExceptions){
        $key=if($e.ExceptionKey){$e.ExceptionKey}else{"$($e.Group)|$($e.OwnershipStatus)"}
        $first=if($previous.ContainsKey($key)){[datetime]$previous[$key].FirstDetected}else{$now}
        [pscustomobject]@{ExceptionKey=$key;Group=$e.Group;Owner=$e.Owner;OwnerUPN=$e.OwnerUPN;OwnerSource=$e.OwnerSource;OwnershipStatus=$e.OwnershipStatus;Detail=$e.Detail;FirstDetected=$first.ToString('s');LastDetected=$now.ToString('s');AgeDays=[math]::Floor(($now-$first).TotalDays);State=if($previous.ContainsKey($key)){'Outstanding'}else{'New'}}
    }
    $currentKeys=@($rows.ExceptionKey)
    $resolved=foreach($p in $previous.Values){if($p.ExceptionKey -notin $currentKeys){$p | Add-Member NoteProperty State 'Resolved' -Force; $p}}
    @($rows) | Export-Csv $HistoryPath -NoTypeInformation -Encoding UTF8
    [pscustomobject]@{Current=@($rows);Resolved=@($resolved)}
}
