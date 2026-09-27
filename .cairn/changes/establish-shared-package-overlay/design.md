## Context

onix-core exposed `pkgs/<name>` packages three ways. Flake `packages` came from `flake-outputs/tools.nix` over plain nixpkgs. NixOS modules and Home Manager profiles called `pkgs.callPackage ../../pkgs/<name> { }` against the machine package set. An internal overlay in `inventory/tags/common/shared-nix.nix` injected nine flake packages into machine package sets. Some packages also took flake inputs as arguments: herdr took the `llm-agents` Herdr and the `wrappers` library, and horizon took its `horizon` source input.

The migration base is onix-core `c5001ff2` with its uncommitted working tree of 2026-09-27, which includes in-flight packages such as laya, arxiv-corpus, mesh-research, and underclass-mesh-gateway.

## Decisions

### Decision: One overlay with directory discovery

**Choice:** `overlay.nix` maps every directory under `pkgs/` to `final.callPackage ./pkgs/<name> (callArgs.<name> or { })`. `callers` selects a scoped callPackage, which only claude-md needs: it uses `python3Packages.callPackage`. `herdr-unwrapped` exposes the upstream Herdr as an attribute of its own.

**Rationale:** A new package cannot be forgotten in a registry. Dependencies between onixpkgs packages resolve through `final`, so a later overlay that replaces collie-herdr or herdr-unwrapped reaches the wrapper. This follows the nixpkgs overlay guidance: use `prev` only to override existing symbols, reference packages through `final`, avoid `rec`, and publish shared choices as attributes instead of overlay parameters.

### Decision: Flake inputs are wired in the overlay and followable

**Choice:** onixpkgs declares `nixpkgs`, `llm-agents`, `wrappers`, and `horizon`. `overlay.nix` passes them to herdr and horizon. The initial lock pins the same revisions that onix-core locked at the migration base.

**Rationale:** Package functions stay ordinary callPackage functions. A consumer that follows `nixpkgs`, `llm-agents`, and `wrappers` gets the derivations it built before the move.

### Decision: Byte-identical package contents

**Choice:** Copy only the files onix-core's flake saw (`git ls-files`, including intent-to-add files, with working-tree contents and modes). Keep directory names, except that `lemonade` becomes `lemonade-server`, its attribute name. Move the lemonade and mesh-llm patches from onix-core's `patches/` into their package directories. Change the updater's description to name onixpkgs.

**Rationale:** Packages with `src = ./.` or `lib.cleanSource ./.` hash their whole directory, and path sources hash by name and content. Identical contents and names give identical derivations, which makes the move checkable. The updater description change rebuilds only the updater, which is in no machine closure.

### Decision: Consumer-bound packages stay with the consumer

**Choice:** dgx-machine, tenstorrent-compat, nix-grpc-store, and aspen-uma-helper stay in onix-core. The Collie Home Manager integration check stays in onix-core too, because it inspects onix-core's evaluated machine configuration.

**Rationale:** dgx-machine bakes onix-core's DGX inventory into its build. tenstorrent-compat patches the private tenstorrent.nix flake. nix-grpc-store is built against onix-core's Nix fork and its nixpkgs snapshot. aspen-uma-helper is a separate flake project, not a callPackage function. Moving them would give every consumer of onixpkgs private or fork inputs, or a package that cannot build without consumer data.

### Decision: Export only what evaluates

**Choice:** `packages` covers x86_64-linux, aarch64-linux, and aarch64-darwin. `exportSystems` carries onix-core's former export gates. The three ROCm llama.cpp packages move to x86_64-linux only, and `meta.platforms` excludes the rest, including prime-agent on everything but x86_64-linux.

**Rationale:** The pinned nixpkgs throws for x86_64-darwin. onix-core exported the ROCm packages on aarch64-linux and prime-agent on every system, where their evaluation fails. The export table now only removes packages that could not evaluate.

## Risks / Trade-offs

- onixpkgs has no published remote. Consumers use a local `git+file` URL, so CI runners and other hosts cannot fetch it until a remote exists and the consumers switch their input URL.
- onixpkgs has no CI of its own yet. onix-core CI still builds every migrated package that a machine closure or the dev shell contains. Packages outside those closures, such as hx-oil and updater, are built only by `nix flake check` here.
- `checks` build every exported package, including the ROCm llama.cpp builds and the DeepSeek draft conversion. A full check run is expensive without a warm cache.
- Machine package sets now build the nine packages that shared-nix.nix used to inject from onix-core's flake packages. When a machine's nixpkgs configuration changes their dependencies, their derivations differ from `packages.<system>`.
