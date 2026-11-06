# Package Overlay Specification

## ADDED Requirements

### Requirement: Penpot uses its upstream-supported runtime cohort

r[onixpkgs.penpot.cohort] The overlay MUST expose a reproducibly pinned Penpot Desktop 1.0.1 package using its upstream-supported Electron 45 cohort and MUST NOT require an insecure-package exception. Its newer package set MUST be scoped to Penpot rather than changing unrelated package bases.

#### Scenario: Package is selected by a creative workstation

- GIVEN an onix-core workstation selects `pkgs.penpot-desktop`
- WHEN the overlay is applied
- THEN the package uses the reviewed source/npm hashes and Electron 45.2.1
- AND the build retains the upstream runtime-major compatibility guard

### Requirement: The installed desktop application runs

r[onixpkgs.penpot.runtime] The package MUST install the actual application assets, a runnable desktop launcher, its icon, and its license. Package building MUST NOT publish releases. Verification MUST exercise the installed application using an isolated profile rather than only checking source text or wrapper forwarding.

#### Scenario: Application startup is exercised

- GIVEN the package has realized
- WHEN the installed launcher opens with an isolated application profile
- THEN an actual application surface is observed without an Electron runtime incompatibility
- AND no user account, existing application profile, or deployed system is changed

### Requirement: Consumer adoption is evaluated before publication

r[onixpkgs.penpot.adoption] Package publication MUST retain concrete package and consuming-workstation verification results and native lifecycle gates. It MUST NOT include unrelated pending changes or claim deployment from evaluation.

#### Scenario: Package-only publication is prepared

- GIVEN unrelated work exists in the primary package checkout
- WHEN the approved Penpot change is prepared for publication
- THEN only the package, its scoped cohort wiring, and directly related documentation/lifecycle artifacts are committed
- AND the consuming aspen3 and britton-desktop system derivations evaluate without the former EOL Electron error
