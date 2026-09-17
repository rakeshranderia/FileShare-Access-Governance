# Solution Overview

## Problem
Traditional Windows file shares frequently retain access structures long after the original business context has changed. Permission visibility alone does not answer the governance questions: **who is accountable, is that owner still valid, and has access been periodically certified?**

## Control objective
Maintain a reliable relationship between Windows file-share ACLs, AD identities/security groups and an accountable business/data owner, then use that relationship for continuous ownership hygiene and periodic owner-led access certification.

## Roles
- **Business/Data Owner:** accountable for determining whether access remains appropriate.
- **IAM/IT:** administers permissions, operates discovery/validation, implements approved remediation.
- **Information Security/Governance:** oversees exceptions, completion and evidence where applicable.

## Control cycles
### Daily ownership assurance
Validate the ownership metadata for known access groups. Report missing, disabled, unresolved or otherwise invalid owners without waiting for the quarterly review.

### Quarterly access certification
Send verified owners a scoped review of access under their ownership. Record Keep / Remove / Investigate decisions and track remediation.

### JML integration
When an account is disabled/offboarded, check whether that identity owns access groups and require reassignment. The daily process remains a safety net for changes outside the normal JML workflow.

## Scope boundary
Access targets are Windows file shares and NTFS ACLs. SharePoint may host workflow data/evidence but SharePoint permissions are not scanned or governed by v1.0.
