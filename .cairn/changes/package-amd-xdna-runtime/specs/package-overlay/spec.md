## ADDED Requirements

### Requirement: Matched NPU userspace

r[onixpkgs.amd_xdna_runtime.components] The package MUST build official XRT base/NPU tools and the matching AMD XDNA userspace plugin from xdna-driver stable 2.21.75 and its XRT submodule gitlink. It MUST retain runtime-discovered module and plugin layout, and MUST NOT install kernel modules, firmware, Ubuntu installers, or global environment policy.

#### Scenario: Local CLI loading

- GIVEN a supported x86_64-linux local builder without NPU access
- WHEN the package is built and xrt-smi version/help are invoked
- THEN the real tools load from their Nix closure without a distro setup script
- AND no hardware functionality is inferred

### Requirement: Explicit functional-data boundary

r[onixpkgs.amd_xdna_runtime.validation] Default output MUST contain only free userspace, with no VTD reference in its closure. An explicit withValidationData override MAY supply the official unmodified Strix validation archive and MUST mark its binary-only redistributable licensing and retain its license. Documentation MUST identify the finite workload, device mutation, power-mode effect and kernel/firmware compatibility boundary.

#### Scenario: Optional data

- GIVEN a consumer that has reviewed and authorized VTD licensing
- WHEN it enables withValidationData and allows that package under its Nix license policy
- THEN the original official archive and its redistribution license are installed under the runtime prefix
- AND hardware execution remains a separate authorized consumer action
