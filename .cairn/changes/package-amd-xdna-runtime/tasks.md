## Phase 1: Package matched components

- [x] [serial] Pin the official stable xdna-driver/XRT pair and build the NPU tools and matching plugin without kernel, firmware or global environment policy. r[onixpkgs.amd_xdna_runtime.components]
- [x] [serial] Build the free default and exercise real CLI version/help with no distro setup environment. r[onixpkgs.amd_xdna_runtime.components]

## Phase 2: Make optional workload data explicit

- [x] [serial] Preserve the official optional archive and license, mark its unfree-redistributable boundary, build the authorized variant and use XRT's actual share/xrt discovery layout. r[onixpkgs.amd_xdna_runtime.validation]
- [x] [serial] Document memory-lock requirements, benchmark-only debug-buffer support, ordinary unmodified arithmetic verification and the absence of a golden-result claim. r[onixpkgs.amd_xdna_runtime.validation]

## Phase 3: Verify isolated canonical integration

- [x] [serial] Verify the isolated release export and native lifecycle artifacts without including unrelated work or publishing before explicit approval. r[onixpkgs.amd_xdna_runtime.components] r[onixpkgs.amd_xdna_runtime.validation]
