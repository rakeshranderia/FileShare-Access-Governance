# JML / Offboarding Integration

A departing user may be the registered owner of one or more access groups. The offboarding workflow should check group ownership before completion and require reassignment or create an exception.

```powershell
Get-ADGroup -Filter * -Properties ManagedBy |
    Where-Object { $_.ManagedBy -eq $DepartingUser.DistinguishedName }
```

This is an early-warning control. Daily ownership assurance remains the independent safety net for accounts disabled outside the standard JML process.
