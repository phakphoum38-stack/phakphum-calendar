# Plugin SDK v3 Foundation

Plugins may extend schedule rules, import formats, reports and notification adapters without changing the core domain.

Each plugin declares:

- a globally unique plugin ID;
- semantic version;
- minimum platform version;
- capability set;
- publisher identity;
- tenant-specific configuration.

Production marketplace requirements include signed packages, publisher verification, automated security scanning, explicit capability approval and rollback support.
