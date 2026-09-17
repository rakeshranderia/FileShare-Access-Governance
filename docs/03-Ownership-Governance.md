# Ownership Governance

## Principle
Ownership is a control object, not free-form reporting metadata.

## Preferred source: `managedBy`
Active Directory's `managedBy` attribute provides a directory reference and avoids the inconsistency of free-text usernames. The solution resolves the referenced object and validates it before accepting it as an owner.

## Fallbacks
A configurable extension attribute or structured Description field can support legacy environments. Description parsing should require a consistent marker such as `Owner: jane.smith@company.example`; free-form names should not be treated as authoritative without successful directory resolution.

## Validation rules
A valid owner should:
- resolve to an existing AD object;
- be an allowed owner object type (v1 defaults to User);
- be enabled;
- have a usable UPN/email where workflow requires it;
- not conflict with higher-priority ownership data.

## Exception states
`OWNER_MISSING`, `OWNER_NOT_FOUND`, `OWNER_DISABLED`, `OWNER_INVALID_OBJECT_TYPE`, `OWNER_NO_EMAIL`, `OWNER_CONFLICT`.

## Owner change control
Organisations should define who may change `managedBy`. The toolkit detects ownership health; it does not by itself establish organisational authority to appoint owners.
