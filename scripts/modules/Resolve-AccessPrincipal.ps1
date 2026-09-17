function Resolve-AccessPrincipal {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Identity)

    $result = [ordered]@{ Identity=$Identity; Name=$null; Sid=$null; PrincipalType='Unresolved'; AdObject=$null; ResolutionStatus='UNRESOLVED_SID'; Detail=$null }
    if ([string]::IsNullOrWhiteSpace($Identity)) { $result.Detail='Identity was empty'; return [pscustomobject]$result }
    $leaf = ($Identity -split '\\')[-1]
    try {
        $nt = [System.Security.Principal.NTAccount]$Identity
        $result.Sid = $nt.Translate([System.Security.Principal.SecurityIdentifier]).Value
    } catch { }
    try {
        $group = Get-ADGroup -Identity $leaf -Properties ManagedBy,Description -ErrorAction Stop
        $result.Name=$group.SamAccountName; $result.PrincipalType='Group'; $result.AdObject=$group; $result.ResolutionStatus='RESOLVED'; return [pscustomobject]$result
    } catch { }
    try {
        $user = Get-ADUser -Identity $leaf -Properties Enabled,UserPrincipalName,Mail,DisplayName -ErrorAction Stop
        $result.Name=$user.SamAccountName; $result.PrincipalType='User'; $result.AdObject=$user; $result.ResolutionStatus='RESOLVED'; return [pscustomobject]$result
    } catch {
        $result.Detail=$_.Exception.Message
        return [pscustomobject]$result
    }
}
