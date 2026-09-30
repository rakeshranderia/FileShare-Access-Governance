# Contributing

Contributions, bug reports and improvement suggestions are welcome.

## Reporting issues

For bugs, unexpected behaviour or enhancement suggestions, use the repository's GitHub Issues page.

Do not include production server names, permission exports, credentials, access-review evidence or other sensitive organisational information in public issues.

Security vulnerabilities should be reported privately using GitHub Private Vulnerability Reporting as described in [SECURITY.md](SECURITY.md).

## Contributing changes

Before submitting a pull request:

1. Keep changes within the repository's defined Windows/NTFS file-share governance scope.
2. Avoid introducing production-specific configuration, credentials or sensitive data.
3. Follow the existing PowerShell structure and naming conventions.
4. Add or update Pester tests where behaviour changes.
5. Update relevant documentation when configuration, outputs or operating behaviour changes.
6. Confirm the PowerShell test workflow completes successfully.

## Development approach

The implementation should remain safe by default. Discovery and governance functions should not silently modify NTFS permissions, Active Directory group membership or ownership.

Prefer readable PowerShell, explicit error handling and clear operational output over unnecessary abstraction.

## Pull requests

Keep pull requests focused on one logical change where practical and describe:

- the problem or improvement;
- the change made;
- how it was tested;
- any operational or security implications.
