# Package Overlay Specification

## Purpose

Defines the `package-overlay` capability.

## Requirements

### Requirement: Fork-bound JSONL evaluator package

r[onixpkgs.eval_jobs.fork_abi] The x86_64-linux overlay MUST expose a distinct `nix-eval-jobs-onix` attribute from an immutable upstream source revision, built against exact Onix Nix fork 2.36.0 components, and MUST leave the generic `nix-eval-jobs` attribute available for independently fork-bound consumers. The distinct package MUST reject a different fork revision or CLI version and MUST NOT silently fall back to stock Nix. Its source patches MUST remain in the package directory.

#### Scenario: Pinned fork links

- GIVEN the pinned Onix Nix fork revision and the pinned nix-eval-jobs upstream source
- WHEN `nix build .#nix-eval-jobs-onix` realizes on x86_64-linux
- THEN the executable MUST link Nix 2.36.0 component libraries from the selected fork cohort, without a stock libnix component

#### Scenario: Existing independent evaluator consumer

- GIVEN an onix-core machine that overlays onixpkgs before independently overriding generic `nix-eval-jobs` against its own pinned Nix fork
- WHEN the machine evaluates with this overlay candidate
- THEN the generic override MUST remain instantiable without selecting or modifying `nix-eval-jobs-onix`

#### Scenario: Wrong cohort selected

- GIVEN an override selecting a different fork revision or the stock Nix CLI
- WHEN the evaluator derivation is instantiated
- THEN package evaluation MUST fail before any executable can be selected from the wrong cohort

### Requirement: Stream jobset derivations independently

r[onixpkgs.eval_jobs.jsonl] The evaluator MUST emit JSONL derivation records with attribute identity, derivation path, output paths and direct input derivations for a supplied derivation jobset. One failing job MUST be reported as an error instead of misreported as a successful derivation.

#### Scenario: Dependent jobs and failing job

- GIVEN a local jobset with a base derivation, a dependent derivation and a deliberately failing job
- WHEN the built evaluator runs with `--show-input-drvs`
- THEN both successful derivations MUST have distinct JSONL records, the dependent record MUST contain the base input derivation, and the failing record MUST carry an error without a derivation path

#### Scenario: Consumer Nickel fixture

- GIVEN a consumer-owned immutable source snapshot whose jobset uses the Onix Nickel WASM plugin
- WHEN the evaluator runs with `wasm-builtin` enabled
- THEN successful JSONL records MUST expose the consumer's actual derivation and output identities; disabling `wasm-builtin` MUST NOT produce successful derivation records

### Requirement: Native lifecycle policy from authenticated source

r[onixpkgs.eval_jobs.cairn_policy] The package owner MUST retain an authenticated Cairn policy source closure and deterministically export its generated policy JSON. The policy MUST include the required `outcome-machine` profile. The owner MUST NOT hand-edit generated policy output or conflate structural gate acceptance with package or host correctness.

#### Scenario: Authentic policy admitted

- GIVEN exact imported Nickel source files and their authenticated revision/NAR identity
- WHEN the Cairn policy is exported, checked and lifecycle gates run
- THEN policy freshness and native proposal/design/tasks gates MUST succeed for a substantive spec-driven package change

#### Scenario: Outcome-machine absent

- GIVEN a policy fixture with its `outcome-machine` workflow profile removed
- WHEN the Cairn gate runs against that policy
- THEN the policy MUST be rejected before returning a successful gate receipt

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

