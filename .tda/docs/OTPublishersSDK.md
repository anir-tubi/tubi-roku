# OTPublishersSDK

## Purpose

Contains the OneTrust Publishers SDK for Roku, which provides privacy consent management (GDPR, CCPA) functionality. This third-party SDK handles displaying consent dialogs, managing user privacy preferences, and providing consent status to the main app for compliance with privacy regulations.

## Structure

- `OTconfig.json` - OneTrust SDK configuration file
- `OTExternalPackages/` - External package dependencies for the OneTrust SDK
- `components/` - SceneGraph components implementing the consent UI and logic (10 subdirectories with consent dialogs, preference centers, banners, etc.)
- `images/` - OneTrust UI image assets

## Architecture

- **Component Library Integration**: The OneTrust SDK is loaded as a component library at runtime via `oneTrustComponentsUrl` in the config. The main channel's `ConsentScreen` and `RokuCWConsentScreen` integrate with these components.
- **Third-Party SDK**: This is a vendor-provided SDK — modifications should be minimal and coordinated with OneTrust.

## Dependencies

**Internal:**

- Loaded by the main channel as a component library
- Integrated via `ConsentScreenHelpers.brs` and `RokuCWConsentScreenHelpers.brs` in ContentController

**External:**

- OneTrust privacy platform

## Working with this Code

### Things to Watch Out For

- This is a third-party SDK — avoid modifying its internals unless necessary for critical bug fixes.
- Updates come from OneTrust; the CDN pull request workflow (`.github/workflows/deploy-component-lib.yml`) handles deployment.
- The `one_trust_library_manifest` in `config/default.yml` defines the manifest for this library.
