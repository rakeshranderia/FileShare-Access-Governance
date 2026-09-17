# Implementation Runbook

## Prerequisites
- Windows PowerShell 5.1 or PowerShell 7 on a Windows management host.
- RSAT Active Directory module.
- Read access to NTFS security descriptors for every in-scope path.
- AD read permissions for users/groups and configured ownership attributes.
- A service identity appropriate to the organisation's security model; no Domain Admin requirement is intended.

## Deployment
1. Copy `Settings.example.json` to `Settings.json` outside source control if it contains environment details.
2. Copy `FileServers.example.csv` to `FileServers.csv` and define only approved shares.
3. Start with one representative share and `Recurse=false` to validate output.
4. Run Discovery and remediate obvious ownership/resolution errors.
5. Expand scope gradually and establish a baseline register.
6. Schedule OwnershipCheck overnight using Task Scheduler or an enterprise scheduler.
7. Generate quarterly review packages only after ownership exceptions are at an acceptable level.

## Suggested schedules
- Discovery: weekly/monthly depending on ACL change rate, plus before each quarterly review.
- OwnershipCheck: daily overnight. It validates known groups; it does not recursively rescan all file shares.
- QuarterlyReview: once per certification cycle after a fresh discovery.

## Security
Keep output in an access-controlled location because it contains permission and identity metadata. Treat review exports as governance evidence under the organisation's retention requirements. Do not place live `Settings.json`, output files or production server inventories in a public repository.

## Rollback
The discovery and validation components are read-only. Remediation is deliberately not automated in v1.0: owner decisions are implemented through the organisation's approved IAM/IT change process.
