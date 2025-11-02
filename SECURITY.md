# Security Policy

## Supported Versions

🔴 **Please note: until the semver for a container reaches at least 1.0.0 there is NO supported version, regardless of channel
  labels attached to them as indicated below**

All use of pre-1.0.0 versions of components is entirely at your own risk

All container images carry a semantic version tag, and optionally a `latest` or `stable` channel tag. You should always install 
  either `latest` or `stable` and not one of the numeric semver tags unless you've been advised to do so - for example
  to temporarily deal with some regression issue or incompatibility in the most recent channel version.
  
| Container Version | Supported          |
| ----------- | ------------------ |
| semver < 1.0.0     | 🔴
| `latest` (semver >= 1.0.0)     | 🟢 |
| `stable` (semver >= 1.0.0)      | 🟢 |
| (any other) | 🔴             |

## Reporting a Vulnerability

Please report a known or suspected vulnerability directly to one of the project maintainers and not by raising an issue in the
  project tracker. Someone will respond at the earliest opportunity and confirmed security issues are prioritised over all
  other project work.
