## Why

The consuming onix-core dependency refresh cannot evaluate its creative workstations because nixpkgs Penpot Desktop 0.23.2 requires end-of-life Electron 42.11.18. The operator explicitly approved packaging and verifying upstream Penpot Desktop 1.0.1 with supported Electron 45, publishing the package-only change, and refreshing the consumer input instead of accepting the insecure runtime.

## What Changes

- Export `penpot-desktop` through the existing directory-driven overlay and package outputs.
- Pin the real v1.0.1 source and npm lock dependency hashes and use Electron 45.2.1 from the consumer-reviewed nixpkgs revision.
- Scope the newer package set to Penpot; preserve every other package's existing base and input locks.
- Keep the source/runtime-major build guard, packaged application assets, desktop entry, icon, and license; prohibit release publishing during package builds.
- Record a real application smoke and evaluate both consuming workstation configurations before publication.

## Impact

Package definition, its explicit runtime cohort, package documentation, and native Cairn records only. No service modules, machine data, secrets, deployments, global insecure-package exceptions, or unrelated pending work.

## Affected Specs

- `package-overlay`: version-matched Penpot Desktop packaging and consumer adoption.
