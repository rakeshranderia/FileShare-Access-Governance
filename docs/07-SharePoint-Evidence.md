# SharePoint / Evidence Register

SharePoint is an optional workflow and evidence destination, **not an access target** in v1.0.

Suggested fields include:
- ReviewPeriod
- Server / Share / Directory
- Principal / PrincipalType
- Permission / AccessType / Inherited
- Owner / OwnerUPN / OwnerSource / OwnershipStatus
- Decision
- Reviewer / ReviewDate / Comments
- RemediationRequired / RemediationStatus / RemediationDate
- FirstDetected / ExceptionAge
- EvidenceID

An implementation can publish via Microsoft Graph/Power Automate according to organisational standards. The repository should not embed tenant-specific URLs, secrets or credentials.
