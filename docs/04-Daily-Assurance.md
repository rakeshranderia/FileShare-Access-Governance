# Daily Ownership Assurance

The overnight process is intentionally lightweight. It revalidates known access groups and owners rather than recursively scanning every directory each night.

```mermaid
flowchart TD
    R[Known ACL Groups] --> G{Group exists?}
    G -->|No| GN[GROUP_NOT_FOUND]
    G -->|Yes| M{managedBy present?}
    M -->|Yes| U[Resolve owner object]
    M -->|No| F[Try configured fallback]
    F -->|None| OM[OWNER_MISSING]
    F --> U
    U --> T{Allowed object type?}
    T -->|No| IT[OWNER_INVALID_OBJECT_TYPE]
    T -->|Yes| EN{Enabled?}
    EN -->|No| OD[OWNER_DISABLED]
    EN -->|Yes| EM{Usable email/UPN?}
    EM -->|No| NE[OWNER_NO_EMAIL]
    EM -->|Yes| OK[OWNER_VERIFIED]
    GN --> X[Exception Register]
    OM --> X
    IT --> X
    OD --> X
    NE --> X
    OK --> H[Healthy Register]
    X --> MAIL[Daily exception email]
```

Track first detected, last detected, age and resolution so the daily report can distinguish new, outstanding and resolved exceptions.
