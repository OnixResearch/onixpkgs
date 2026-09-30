## Context

onixpkgs already exports packages from `pkgs/<name>` through `final.callPackage`, with input-specific arguments passed by `overlay.nix`. The authoritative main revision had native `.cairn/` change artifacts but no Cairn policy source or generated JSON. OnixOS owns the Nickel jobset and plugin and provides a local immutable Nix store snapshot for cross-repo smoke; it has not published that snapshot as a Git source pin.

## Decisions

### Decision: Bind evaluator to one reviewed fork ABI

**Choice:** Pin upstream nix-eval-jobs `9f1553afabd95f9f59951f5c946e86005af7196a` and the `nix-onix` flake revision `f93f28ad9dce007baae13aa461c16abf656d1171`. Pass that flake's 2.36.0 Nix components through overlay callArgs, reject a wrong revision/CLI version, and apply package-local derivation and logging/flake API patches. Do not substitute stock Nix or bake consumer fixtures into the package.

**Rationale:** Newer upstream nix-eval-jobs 2.35.4 still refers to `Derivation.inputDrvs`, member output methods and pre-2.36 logger/flake signatures. The fork provides `inputs.drvs` and free output functions. Building against the fork's own component packages gives exact linked ABI; 2.36 version names alone do not prove identical store closures across independent nixpkgs pins.

### Decision: Import Cairn policy without changing its semantics

**Choice:** Copy exactly Cairn's `default.ncl`, `contracts.ncl`, `lifecycle-store-contracts.ncl` and `nominal-evidence-identities.ncl` at authenticated revision `007ba5193dd8fec9067a1c0e0f8ef487807af872` and source NAR `sha256-Kgx8JgsC/+26ETbL3lRaxXAYfzv2cmtG/i9OywPOz0c=`. Export generated JSON with Cairn, and reject a fixture that removes the policy-required outcome-machine profile. No previous onixpkgs policy existed to overlay.

**Rationale:** The native Cairn gate requires a generated policy and the exact transitive Nickel imports. Reusing the authenticated policy leaves its workflow and evidence boundaries intact; a local policy invention or hand-edited generated JSON would not justify release.

## Risks / Trade-offs

- The source/ABI pins need an explicit review for future upgrades; the evaluator's own binary closure differs from OnixOS's separately built fork CLI closure. Confirm behavior against immutable consumer snapshots, but do not assert host, plugin correctness, or deployment authority from the build.
- Full `nix flake check` builds unrelated ROCm and large model conversion packages; scoped package, formatting and lifecycle gates prove only this package candidate. A dirty local OnixOS Nix store snapshot is not an immutable published source revision.
