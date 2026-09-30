## Why

OnixOS and Kiln need reusable JSONL derivation discovery from source-owned jobsets evaluated with Onix's `builtins.wasm` Nickel plugin. Their stock Nix 2.31/2.35 evaluator cohorts cannot evaluate that builtin. The pinned Onix Nix 2.36 fork changes C++ derivation and flake APIs, so a nix-eval-jobs source override without a reviewed adapter does not compile. The package owner must pin and build one compatible cohort without taking ownership of either consumer's jobset or service policy.

## What Changes

- Export `pkgs.nix-eval-jobs` on x86_64-linux, pin NixOS/nix-eval-jobs `9f1553afabd95f9f59951f5c946e86005af7196a` and Onix Nix `f93f28ad9dce007baae13aa461c16abf656d1171`, and carry exact-fork C++ patches beside the derivation.
- Reject wrong fork and CLI versions; check dependent derivation JSONL and per-job errors alongside wrong-fork and stock-linkage selection. Preserve the consumer's immutable Nickel jobset and plugin as consumer data, not onixpkgs inputs.
- Import and verify Cairn's exact policy closure from `007ba5193dd8fec9067a1c0e0f8ef487807af872` to restore native onixpkgs lifecycle gates without authoring new policy; test both a valid profile and removal of the required outcome-machine profile.

## Impact

- **Files**: `flake.nix`, `flake.lock`, `overlay.nix`, `pkgs/nix-eval-jobs/`, `cairn-policy/`, `.cairn/changes/add-onix-nix-eval-jobs/`, `README.md`.
- **Testing**: build evaluator and upstream unit tests, package JSONL check, actual local immutable OnixOS Nickel snapshot JSONL, no-WASM rejection, `ldd` closure inspection, formatting, Cairn policy freshness, validation and strict proposal/design/tasks gates with a negative missing-outcome-machine policy fixture. An unpublished dirty source snapshot is not a published immutable Git pin; onixpkgs does not claim OnixOS host or release authority.
