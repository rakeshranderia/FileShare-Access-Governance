function New-OwnershipExceptionEmail {
    [CmdletBinding()]
    param([Parameter(Mandatory)][array]$Exceptions,[array]$Resolved=@(),[Parameter(Mandatory)][string]$TemplatePath)
    $template=Get-Content -LiteralPath $TemplatePath -Raw
    $rows=if($Exceptions.Count){($Exceptions | ForEach-Object {"<tr><td>$([System.Net.WebUtility]::HtmlEncode($_.Group))</td><td>$([System.Net.WebUtility]::HtmlEncode($_.Owner))</td><td>$($_.OwnershipStatus)</td><td>$($_.FirstDetected)</td><td>$($_.AgeDays)</td><td>$([System.Net.WebUtility]::HtmlEncode($_.Detail))</td></tr>"}) -join "`n"}else{'<tr><td colspan="6">No current ownership exceptions.</td></tr>'}
    $resolvedRows=if($Resolved.Count){($Resolved | ForEach-Object {"<li>$([System.Net.WebUtility]::HtmlEncode($_.Group)) - $($_.OwnershipStatus)</li>"}) -join "`n"}else{'<li>None</li>'}
    $template.Replace('{{GeneratedDate}}',(Get-Date).ToString('yyyy-MM-dd HH:mm')).Replace('{{ExceptionCount}}',[string]$Exceptions.Count).Replace('{{ExceptionRows}}',$rows).Replace('{{ResolvedRows}}',$resolvedRows)
}
