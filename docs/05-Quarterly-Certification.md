# Quarterly Owner Certification

Only verified owners should receive access-certification requests. Ownership exceptions are routed to governance/IAM for correction first.

```mermaid
flowchart TD
    A[Current ACL Dataset] --> V{Owner verified?}
    V -->|No| X[Ownership Exception Queue]
    V -->|Yes| B[Group records by Owner]
    B --> E[Quarterly Review Email]
    E --> O[Business/Data Owner]
    O --> D{Decision}
    D -->|Keep| K[Record Certification]
    D -->|Remove| R[IAM/IT Remediation]
    D -->|Investigate| I[Investigation / Clarification]
    R --> C[Record Completion]
    I --> C
    K --> EV[Retain Evidence]
    C --> EV
```

The review register should capture period, reviewer, date, decision, comments, remediation requirement/status and evidence ID.
