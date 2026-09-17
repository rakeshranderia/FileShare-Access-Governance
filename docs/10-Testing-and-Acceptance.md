# Testing and Acceptance

Use a controlled test share containing inherited and explicit ACLs, an AD group with a valid `managedBy` owner, an ownerless group, a group owned by a disabled account, a direct-user ACE and (where practical) an unresolved SID.

Acceptance criteria:
- Discovery records each directory/ACE without changing permissions.
- Inherited status and allow/deny access type are retained.
- AD groups and users are distinguished; unresolved principals are visible.
- `managedBy` takes precedence over configured fallback ownership sources.
- Missing, disabled, invalid and conflicting ownership is not reported as verified.
- Direct-user permissions are flagged when configured.
- Daily checks use the last discovery register and retain FirstDetected/AgeDays.
- Quarterly packages are generated only for verified owners; unresolved ownership goes to the governance exception file.
- No function automatically changes ACLs, AD group membership or AD ownership.

Because the repository is cross-environment publication code, test against the organisation's naming, trusts, DFS topology, large-directory behaviour and mail/workflow service before production use.
