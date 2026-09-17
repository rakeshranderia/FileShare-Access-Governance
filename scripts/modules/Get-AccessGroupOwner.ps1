function Resolve-OwnerCandidate {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Candidate,[switch]$RequireEmail)
    $value=[string]$Candidate.Value
    try {
        $obj=Get-ADObject -Identity $value -Properties objectClass -ErrorAction Stop
        if ($obj.ObjectClass -ne 'user') { return [pscustomobject]@{Candidate=$Candidate;Status='OWNER_INVALID_OBJECT_TYPE';Object=$obj;Email=$null;Detail="Owner resolves to $($obj.ObjectClass)"} }
        $user=Get-ADUser -Identity $obj.DistinguishedName -Properties DisplayName,UserPrincipalName,Mail,Enabled -ErrorAction Stop
    } catch {
        try {
            $safe=$value.Replace("'","''")
            $user=Get-ADUser -Filter "UserPrincipalName -eq '$safe' -or SamAccountName -eq '$safe'" -Properties DisplayName,UserPrincipalName,Mail,Enabled -ErrorAction Stop | Select-Object -First 1
            if (-not $user) { throw 'No matching user' }
        } catch { return [pscustomobject]@{Candidate=$Candidate;Status='OWNER_NOT_FOUND';Object=$null;Email=$null;Detail=$_.Exception.Message} }
    }
    $email=if($user.Mail){$user.Mail}else{$user.UserPrincipalName}
    $status=if(-not $user.Enabled){'OWNER_DISABLED'}elseif($RequireEmail -and -not $email){'OWNER_NO_EMAIL'}else{'OWNER_VERIFIED'}
    [pscustomobject]@{Candidate=$Candidate;Status=$status;Object=$user;Email=$email;Detail=$null}
}

function Get-AccessGroupOwner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Group,
        [string]$ExtensionAttribute,
        [string]$DescriptionOwnerPattern='(?im)(?:^|[;|\r\n])\s*Owner\s*:\s*([^;|\r\n]+)',
        [switch]$RequireEmail
    )
    $candidates=[System.Collections.Generic.List[object]]::new()
    if($Group.ManagedBy){$candidates.Add([pscustomobject]@{Source='managedBy';Value=$Group.ManagedBy;Priority=1})}
    if($ExtensionAttribute -and $Group.PSObject.Properties.Name -contains $ExtensionAttribute -and $Group.$ExtensionAttribute){$candidates.Add([pscustomobject]@{Source=$ExtensionAttribute;Value=$Group.$ExtensionAttribute;Priority=2})}
    if($Group.Description -and $Group.Description -match $DescriptionOwnerPattern){$candidates.Add([pscustomobject]@{Source='Description';Value=$Matches[1].Trim();Priority=3})}
    if(-not $candidates.Count){return [pscustomobject]@{Owner=$null;OwnerUPN=$null;OwnerDN=$null;OwnerSource=$null;OwnershipStatus='OWNER_MISSING';Detail='No owner metadata found'}}

    $resolved=@($candidates | Sort-Object Priority | ForEach-Object { Resolve-OwnerCandidate -Candidate $_ -RequireEmail:$RequireEmail })
    $best=$resolved | Sort-Object {$_.Candidate.Priority} | Select-Object -First 1
    $verified=@($resolved | Where-Object Status -eq 'OWNER_VERIFIED')
    if($verified.Count -gt 1){
        $dns=@($verified | ForEach-Object {$_.Object.DistinguishedName} | Select-Object -Unique)
        if($dns.Count -gt 1){return [pscustomobject]@{Owner=$best.Object.DisplayName;OwnerUPN=$best.Email;OwnerDN=$best.Object.DistinguishedName;OwnerSource=$best.Candidate.Source;OwnershipStatus='OWNER_CONFLICT';Detail='Ownership sources resolve to different enabled users'}}
    }
    [pscustomobject]@{Owner=$best.Object.DisplayName;OwnerUPN=$best.Email;OwnerDN=$best.Object.DistinguishedName;OwnerSource=$best.Candidate.Source;OwnershipStatus=$best.Status;Detail=$best.Detail}
}
