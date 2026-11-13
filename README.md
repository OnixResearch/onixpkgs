# onixpkgs

onixpkgs publishes Onix's custom packages as one overlay over nixpkgs. A repository in the stack applies the overlay and uses `pkgs.<name>` instead of carrying its own copy of the package.

## Use

Add the flake input and let it follow your nixpkgs:

```nix
inputs.onixpkgs = {
  url = "git+ssh://git@github.com/OnixResearch/onixpkgs.git";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Apply the overlay wherever you instantiate nixpkgs:

```nix
# NixOS, nix-darwin, or Home Manager without useGlobalPkgs
nixpkgs.overlays = [ inputs.onixpkgs.overlays.default ];

# Flake code
pkgs = import nixpkgs {
  inherit system;
  overlays = [ inputs.onixpkgs.overlays.default ];
  config = { };
};
```

Flake code that does not instantiate nixpkgs can use `inputs.onixpkgs.packages.${system}.<name>`. These packages are built from the overlay over plain nixpkgs. They do not see the consumer's nixpkgs config or other overlays.

`lib.kacheNixRust` builds rustc wrappers that route compilation through kache. Call it with the package set and kache package to use:

```nix
kacheLib = inputs.onixpkgs.lib.kacheNixRust {
  inherit (pkgs) lib;
  inherit pkgs;
  kachePackage = pkgs.kache;
};
wrappedRust = kacheLib.mkWrappedRustPackage {
  rust = pkgs.rustc;
  cacheDir = "/var/cache/kache-nix";
};
```

## Layout

- `overlay.nix` is `overlays.default`. Each directory `pkgs/<name>/` becomes `pkgs.<name>`, built with `final.callPackage`. `callArgs` holds arguments that do not come from the package set, such as flake inputs. `callers` holds packages built by a scoped callPackage.
- `pkgs/<name>/default.nix` is a callPackage function. Patches, local sources, and package tests live beside it.
- `herdr-unwrapped` is the upstream Herdr from `llm-agents.nix`. `pkgs.herdr` wraps it. A later overlay can replace the base.
- `flake.nix` exports `overlays.default`, `lib`, `packages`, `checks`, and `formatter`. `exportSystems` limits where a package is exported. An unlisted package is exported on every system its `meta.platforms` allows.
- `lib/kache-nix-rust.nix` is `lib.kacheNixRust`. `lib/kache-nix-rust-contract.nix` tests it with a fake kache.
- `mesh-llm-headless` is the headless Mesh LLM 0.72.1 build that onixos runs. Its `backend` argument selects `cpu`, the default, or `vulkan`: `pkgs.mesh-llm-headless.override { backend = "vulkan"; }`. It writes provenance and license-inventory JSON under `share/mesh-llm`. `mesh-llm` is a separate 0.72.2 build with plugins, which onix-core's services run.
- `nix-eval-jobs-onix` exports on x86_64-linux as a separate evaluator from
  generic `pkgs.nix-eval-jobs`, preserving consumers' own Nix ABI overrides.
  It links the Onix Nix fork `f93f28ad9dce007baae13aa461c16abf656d1171`
  (2.36.0), not stock Nix. It pins NixOS/nix-eval-jobs source
  `9f1553afabd95f9f59951f5c946e86005af7196a`
  (`sha256-t1FbcjvTWQ1WO3hJNKN+viNXuz4BX9Pte5K4F+IJLDk=`) and carries
  package-local derivation and API patches for that exact fork. A different
  fork revision or CLI version is rejected.
  `checks.x86_64-linux.nix-eval-jobs-onix-jsonl` covers dependent derivation
  discovery, per-job errors and wrong-fork rejection.
  Consumers own immutable jobset inputs, plugins and evaluation policy; a
  package build or JSONL observation does not confer host or deployment authority.
- `penpot-desktop` packages upstream 1.0.1 with supported Electron 45.2.1.
  Its `nixpkgs-penpot` input scopes the build/runtime cohort to the reviewed
  `6dadaf4375be35033e1c84395adbd53ff5fded96` revision without moving other packages'
  shared base. Advance the application release and this Electron cohort together;
  do not permit an end-of-life runtime to keep an old application evaluating.
  Build with `nix build .#penpot-desktop`; the installed launcher and desktop
  entry use the packaged ASAR/resources, icon, and license.

## AMD XDNA NPU runtime

`pkgs.amd-xdna-runtime` builds the official XRT **NPU** base, PCIe runtime,
`xrt-smi`, `xrt-runner`, and XDNA plugin together on x86_64-linux. The stable
xdna-driver tag `2.21.75` (`beb9e450fe123ecdf395453971576179cedcf1dd`)
pins XRT `4eb1f4392a012b4e6eca759762389c612537f7c7`; update the pair,
including recursive XRT submodules, together. The default contains open-source
userspace with dependency notices, not firmware, a kernel module, DKMS,
compiled workloads, a service, or global environment changes.

Install the package and retain a compatible `amdxdna` driver and firmware.
Grant the intended user access to `/dev/accel/accel*`, normally through `render`.
Do not source a distro `setup.sh` or mix libraries from another XRT release.
The ELF tools use Nix RPATHs; the core finds its XDNA plugin beside
`libxrt_core.so.2` and modules below `lib/xrt/module`.
`share/amd-xdna-runtime.json` records component provenance.

The matched KMQ/Strix shim maps a **64 MiB locked device heap even for queries**.
An insufficient `RLIMIT_MEMLOCK` can fail that mapping with `EAGAIN` and flags
`0x2011`. Check the invoking process's actual soft/hard limits. Command,
control-packet and other workload buffers need additional budget: 64 MiB is
a query floor, not a workload maximum. A consumer can explicitly approve a
bounded 256 MiB allowance (268,435,456 bytes; 262,144 KiB for PAM), but must
verify its workload. Resource policy belongs to the consumer; this package
does not raise limits, grant capabilities, disable locking, or shrink heaps.

Read-only initialization is `xrt-smi examine`, followed by
`xrt-smi examine --device <BDF> --report platform`. Enumeration and CLI smoke
tests are not compute proof. Hardware-specific validation help is
`xrt-smi validate --device <BDF> --help`.

### Optional workload data and driver feature boundary

After license review and explicit authorization,
`pkgs.amd-xdna-runtime.override { withValidationData = true; }` adds the
unmodified official Strix archive selected by xdna-driver's `tools/info.json`
from [VTD commit c79b5d2](https://github.com/Xilinx/VTD/tree/c79b5d21568a4ffa5b0612a8279b352fc4e1109a).
Its [LICENSE.vtd](https://github.com/Xilinx/VTD/blob/c79b5d21568a4ffa5b0612a8279b352fc4e1109a/LICENSE.vtd)
allows unmodified binary redistribution with notices, prohibits reverse
engineering except where law permits, and is not open source. The variant is
marked `unfreeRedistributable` and installs its license. The free default does
not fetch or close over VTD. The archive belongs at
`share/xrt/amdxdna/bins/xrt_smi_strx.a`: XRT searches `share/xrt` for a Nix
prefix, not the distro-style `share/amdxdna` location.

**The `xrt-smi validate --run gemm` benchmark requires firmware-debug-buffer support;
ordinary GEMM dispatch does not.** The benchmark's result buffer requires
`DRM_AMDXDNA_HWCTX_ASSIGN_DBG_BUF` and debug-buffer synchronization.
[Linux 6.18.60](https://github.com/gregkh/linux/blob/v6.18.60/drivers/accel/amdxdna/aie2_ctx.c#L786-L800)
returns `EOPNOTSUPP` for debug-buffer attachment/removal while implementing CU
configuration separately. [Upstream commit 7ea0468](https://github.com/torvalds/linux/commit/7ea0468380216c10b73633b976d33efa8c12d375)
adds that support, present in 6.19. This is a feature boundary, not a
recommendation to install an obsolete kernel or a complete compatibility
guarantee. Root, more memlock, ignoring the error, or stripping required
resources cannot make that benchmark valid on an unsupported driver.

`xrt-smi validate --device <BDF> --run gemm` also requests performance mode.
Capture the prior `power_mode` with a platform JSON report and re-query it
afterwards; interrupted validation may bypass restoration. If necessary,
`xrt-smi configure --device <BDF> --pmode <saved-mode>` restores it. Never
assume a killed process restored the mode. The benchmark checks completion
and cycle counts, not a golden matrix result.

### Ordinary arithmetic verification without debug buffers

The distinct official `recipe_temporal_sharing_ovd.json` runs the same real
`gemm.xclbin`/`gemm.elf` kernel with no debug buffer. Its unmodified profile is
finite: 100 iterations at depth 15, or 1,500 invocations in one context.
The standalone runner uses device index **0**, with no BDF selector in this
version: confirm that index is the intended NPU. It does not itself request
a power-mode change. This is not `xrt-smi`'s temporal-sharing benchmark,
which adds multiple contexts and preemption telemetry.

Run only after the consumer authorizes real device work, reviews the VTD
license, and configures sufficient per-process resources. From this checkout,
the following builds the authorized variant and extracts original members
without modifying the archive or their bytes. GNU `ar` and `timeout` are needed.

```sh
set -eu
runtime=$(NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --print-out-paths --expr '
  let f = builtins.getFlake (toString ./.);
  in f.packages.${builtins.currentSystem}.amd-xdna-runtime.override {
    withValidationData = true;
  }
')
archive="$runtime/share/xrt/amdxdna/bins/xrt_smi_strx.a"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
(cd "$work" && ar x "$archive" \
  recipe_temporal_sharing_ovd.json profile_temporal_sharing_ovd.json \
  gemm.xclbin gemm.elf)
timeout --kill-after=5s 180s "$runtime/bin/xrt-runner" \
  --recipe "$work/recipe_temporal_sharing_ovd.json" \
  --profile "$work/profile_temporal_sharing_ovd.json" \
  --dir "$work" --report "$work/report.json"
cat "$work/report.json"
```

Require exit zero and a throughput report with iterations 100 and depth 15;
the runner waits for command completion and propagates failures. This recipe
exposes **no numerical result or golden comparison**: success proves real
arithmetic-workload completion, not arithmetic correctness or model inference.
The source-matched KMQ golden-output tests need separate
`NPU5_1x4_TESTCASES` assets absent from this archive. Package checks do not
submit target work; hardware verification and its limits belong to consumers.

## Add a package

1. Create `pkgs/<name>/default.nix`. The directory name is the attribute name.
2. Take dependencies as callPackage arguments. Refer to other onixpkgs packages by attribute name, not by path, so a later overlay can replace them.
3. Put arguments that the package set cannot supply in `callArgs` in `overlay.nix`.
4. Restrict export systems with `meta.platforms` or `exportSystems`.
5. Run `nix build .#<name>` and `nix build .#checks.<system>.formatting`.

`nix run .#updater -- --list` lists packages that have a `nix-update-args` file. `nix run .#updater -- --package <name>` runs nix-update for one of them.

## Checks

`nix flake check -L` builds every exported package and the vulkan variant of `mesh-llm-headless`. It runs the Collie controller and remote-session tests, the iroh-ssh child-status test, the kache wrapper contract on x86_64-linux, and the treefmt check (nixfmt, deadnix, statix, ruff, shellcheck, shfmt, rustfmt, prettier). The ROCm llama.cpp builds and the DeepSeek draft conversion are large; the conversion downloads three checkpoint shards. `nix fmt` applies the same formatters. `ruff.toml` carries onix-core's Python lint settings.

## Lifecycle

Native Cairn changes live under `.cairn/`. `cairn-policy/PROVENANCE.md`
identifies the authenticated upstream revision and exact four-file Nickel
source closure. Regenerate the checked policy JSON, never hand-edit it:

```sh
cairn policy export --source cairn-policy/default.ncl --output cairn-policy/generated/cairn-policy.json
```

`cairn validate --root .` checks the repository lifecycle;
`cairn-policy/check-policy.sh` requires `cairn`, `nickel`, and `jq` and checks
policy freshness, strict proposal/design/tasks gates for the evaluator change,
and rejection of a policy missing the required `outcome-machine` profile.

## Consumers

- onix-core applies the overlay to its NixOS and nix-darwin machines, whose Home Manager profiles share that package set. It also applies the overlay to its DGX machines through `modules/dgx-machine` and to its check harnesses. Its dev shell uses `packages`. dgx-machine, tenstorrent-compat, nix-grpc-store, and aspen-uma-helper stay in onix-core, because they depend on onix-core's machine inventory, the private tenstorrent.nix flake, or its Nix fork.
- site takes `celld` from the overlay and trellis takes `tracey`.
- aspen takes `kache` from the overlay and builds its kache rustc wrappers with `lib.kacheNixRust`.
- onixos takes `iroh-ssh` and `mesh-llm-headless` from an overlaid package set and wraps Mesh LLM with its own guard and bundle.

site, trellis, aspen, and onixos pin onixpkgs by revision or through their locks, so a package change reaches them when they relock.

Maintainer: brittonr.

## Claim boundary

onixpkgs owns package definitions, their source pins, and package-local patches and tests. A successful build shows only that the derivation realizes on that system. It does not show that the package works on a host, that a consumer's service configuration is valid, or that the upstream software is correct. Service modules, machine policy, secrets, and deployment evidence stay with the consumers.

## References

- [Mastering Nixpkgs Overlays](https://nixcademy.com/posts/mastering-nixpkgs-overlays-techniques-and-best-practice/), the [NixOS wiki overlay page](https://wiki.nixos.org/wiki/Overlays), and [NixOS & Flakes: Overlays](https://nixos-and-flakes.thiscute.world/nixpkgs/overlays) — overlay conventions followed by `overlay.nix`: `final`/`prev` roles, no `rec`, dependencies through `final`, and shared choices exposed as attributes rather than overlay parameters.
- [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix) — upstream Herdr binary (`herdr-unwrapped`) wrapped by `pkgs/herdr`.
- [brittonr/wrappers](https://github.com/brittonr/wrappers) — wrapper library used by `pkgs/herdr`.
- [peters/horizon](https://github.com/peters/horizon) — source input of `pkgs/horizon`. It is fetched through git with LFS, because its bundled fonts are LFS objects.
- [domenkozar/agentaps](https://github.com/domenkozar/agentaps) — upstream of `pkgs/agentaps`. The package pins a `main` commit after the v0.2.1 release, because that release has no SSH projects or Web Connect.
- [rustonbsd/iroh-ssh](https://github.com/rustonbsd/iroh-ssh) — upstream of `pkgs/iroh-ssh`. `iroh-ssh-connection-type-evidence.patch` makes `iroh-ssh connect` print the connection type.
- [smarzban/herdr-file-viewer](https://github.com/smarzban/herdr-file-viewer), [persiyanov/herdr-reviewr](https://github.com/persiyanov/herdr-reviewr), [paulbkim-dev/vim-herdr-navigation](https://github.com/paulbkim-dev/vim-herdr-navigation), [nikok6/herdr-mirror](https://github.com/nikok6/herdr-mirror), and [NathanFlurry/herdr-plugin-jj-workspace](https://github.com/NathanFlurry/herdr-plugin-jj-workspace) — pinned Herdr plugins in the `pkgs/herdr` static registry.
- `pkgs/herdr/vendor/herdr-plugin-pueue` — local Herdr Pueue dashboard source, vendored until that repository has a remote.
- [osolmaz/ghzinga](https://github.com/osolmaz/ghzinga) — pinned Rust CLI and Herdr link handler for GitHub issue and pull request views.
- [umakers/collie-herdr](https://github.com/umakers/collie-herdr) — phone PWA for Herdr over Tailscale. `pkgs/collie-herdr/UPSTREAM.md` describes the package and trust boundaries.
- [Noelo-Lab/kuna](https://github.com/Noelo-Lab/kuna) — binaries and SLEIGH specs for the Kuna decompiler package.
- [PrimeIntellect-ai/prime-agent](https://github.com/PrimeIntellect-ai/prime-agent) — upstream coding and research agent.
- [OpenBubbles/openbubbles-app](https://github.com/OpenBubbles/openbubbles-app) — pinned Linux release bundle wrapped as `pkgs/openbubbles`.
- [denoland/celld](https://github.com/denoland/celld), [kunobi-ninja/kache](https://github.com/kunobi-ninja/kache), [murerkinn/bookshelf](https://github.com/murerkinn/bookshelf), and [Mesh-LLM/mesh-llm](https://github.com/Mesh-LLM/mesh-llm) — upstream sources of the packages behind onix-core's Celld, Kache, Bookshelf, and Mesh-LLM services.
