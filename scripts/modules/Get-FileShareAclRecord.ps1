function Get-FileShareAclRecord {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path,[switch]$Recurse,[switch]$IncludeInherited)
    $targets=[System.Collections.Generic.List[string]]::new(); $targets.Add($Path)
    if($Recurse){
        Get-ChildItem -LiteralPath $Path -Directory -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {$targets.Add($_.FullName)}
    }
    foreach($target in $targets){
        try {
            $acl=Get-Acl -LiteralPath $target -ErrorAction Stop
            foreach($ace in $acl.Access){
                if(-not $IncludeInherited -and $ace.IsInherited){continue}
                [pscustomobject]@{Directory=$target;ObjectOwner=$acl.Owner;Principal=$ace.IdentityReference.Value;Permission=$ace.FileSystemRights.ToString();AccessType=$ace.AccessControlType.ToString();Inherited=[bool]$ace.IsInherited;InheritanceFlags=$ace.InheritanceFlags.ToString();PropagationFlags=$ace.PropagationFlags.ToString();ScanStatus='OK';ScanError=$null}
            }
        } catch {
            [pscustomobject]@{Directory=$target;ObjectOwner=$null;Principal=$null;Permission=$null;AccessType=$null;Inherited=$null;InheritanceFlags=$null;PropagationFlags=$null;ScanStatus='ERROR';ScanError=$_.Exception.Message}
        }
    }
}
