# Security Policy

## Supported Versions

We actively maintain and provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0.0 | :x:                |

---

## Reporting a Vulnerability

The Recall maintainers take security seriously. If you discover a security vulnerability or sensitive information exposure:

1. **Do NOT create a public GitHub issue.**
2. Please privately disclose the issue by sending an email to `security@recall.app` or opening a **Private Security Advisory** on GitHub.
3. Include detailed steps to reproduce the vulnerability, including platform, OS version, and sample inputs.

### What to Expect
- **Response**: We will acknowledge receipt of your vulnerability report within 48 hours.
- **Resolution**: We will provide a timeline for investigation and patch release.
- **Credit**: Once resolved, we will gladly credit you in the security advisory and release notes.

---

## Best Practices for Contributors
- **Never commit API keys or private tokens** to version control.
- All secrets must be provided via runtime environment variables (`--dart-define`) or user secure storage.
- Do not log sensitive user data or API keys in production builds.
