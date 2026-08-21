# Changelog

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-08-21

Initial release of HelloID-Conn-SA-Full-Exchange-On-Premises-Distribution-Group-Update.

### Added

- Initial release for updating Exchange On-Premises Distribution Groups
- Search and select distribution groups by Name, Alias, SamAccountName, or PrimarySmtpAddress
- Update distribution group DisplayName and Name
- Update distribution group Alias
- Add new email addresses (primary or secondary) to distribution groups
- Validation datasources for:
  - DisplayName uniqueness in Active Directory
  - Alias uniqueness in Exchange
  - Email address uniqueness in Exchange
- Retrieve all accepted mail domains for email address configuration
- Intelligent email address management that preserves existing proxy addresses
- Automatic conversion of existing primary SMTP to secondary when setting a new primary address
- Duplicate email address prevention
- Email Address Policy explicitly disabled during updates
- All-in-one setup script for quick deployment

### Changed

### Deprecated

### Removed

### Fixed
