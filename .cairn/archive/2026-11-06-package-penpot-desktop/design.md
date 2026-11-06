# Design: Package Penpot Desktop with its supported Electron cohort

## Context

nixpkgs packages Penpot 0.23.2 with Electron 42 and rejects that end-of-life runtime in the refreshed consumer. Upstream's immutable v1.0.1 release requires Electron ^45.2.0. The consumer-reviewed nixpkgs revision provides Electron 45.2.1 without an insecure marking. This package repository's shared base predates Electron 45 and must not be advanced incidentally for every other package.

## Decisions

- Follow the maintained upstream buildNpmPackage recipe and existing local npm-package conventions. Pin both source and npm dependency NAR hashes obtained from native prefetch commands.
- Add a dedicated immutable `nixpkgs-penpot` input and select its callPackage through the overlay's existing `callers` mechanism. This isolates the complete application build/runtime cohort without compatibility fallbacks or changing unrelated package bases.
- Keep the runtime-major guard against upstream package.json. Build the unpacked application with the packaged Electron distribution and `--publish=never`, then install its real ASAR/resources, desktop entry, icon, and license.
- Advance the application source and its Electron cohort together during future maintenance. Do not exempt end-of-life Electron from nixpkgs security checks.
- Preserve the original checkout's pending changes by preparing a detached clean worktree from the shared GitHub/Radicle main revision. Publication is explicitly authorized to both configured main remotes.

## Verification

The standalone package build succeeded at `/nix/store/7nkn6c3zl5yk6xdl39hsxilgghmw0yxm-penpot-desktop-1.0.1`, using Electron 45.2.1. The actual installed launcher opened its packaged local application and rendered the Penpot login view in an isolated Xvfb/D-Bus session with a fresh profile, no credentials, and its sandbox enabled. Native computer capture reported no backend/display, so the actual Electron renderer supplied the retained `evidence/penpot-startup.png` screenshot through loopback CDP. No login, cookie-consent, account, or deployment action was taken. Both consuming workstation derivations evaluated successfully against the candidate; cached/offline evaluation avoided irrelevant expired Radicle HEAD lookups. The original shared inputs remain byte-identical. No claim is made that unrelated packages or deployed systems were exercised.

The repository formatting derivation succeeded at `/nix/store/8fkbjf37gffarz559sxvspvq5wzcqxql-treefmt-check`, checking 107 files without changes. The changed Nix files passed nixfmt, deadnix, and statix. Native proposal/design gates and repository validation passed with the authenticated policy. Linux export evaluation selects 1.0.1 for x86_64 and aarch64 and excludes Darwin; the aarch64 package itself was not built.
