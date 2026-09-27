# Agent Notes

## Scope

onixpkgs holds package definitions: derivations, source pins, and package-local patches and tests. Service modules, machine configuration, inventories, and secrets belong to consumers such as onix-core.

## Package rules

- Name each directory under `pkgs/` after its attribute. `overlay.nix` calls every `pkgs/<name>/default.nix` with `final.callPackage`.
- Refer to another onixpkgs package through a callPackage argument, never by path. `callArgs` in `overlay.nix` maps renamed arguments, such as herdr's `collie`.
- Do not give a package function a default that reaches into a flake input. Pass inputs through `callArgs`.
- Do not bake consumer data, such as machine inventories or secrets, into a package here. Such packages stay with their consumer.
- Keep patches inside the package directory they apply to.
- A package with `src = ./.` or `lib.cleanSource ./.` hashes its whole directory, including `default.nix`. Any edit there rebuilds the package and every closure that contains it.
- `pkgs/lemonade-server/default.nix` must accept either `lemond` or `lemonade-router` as the daemon binary name. Upstream changed names across releases, so install both aliases.
- nix-update bumps only `version` when a package pins a literal `rev = "<commit>"`. Template tag revisions (`rev = "v${version}"`) or refresh the source and dependency hashes by hand.

## Checks

- Build a changed package with `nix build .#<name>`. Run `nix build .#checks.<system>.formatting` for the treefmt formatting and lint check.
- `nix flake check -L` builds every exported package, including the ROCm llama.cpp builds and the DeepSeek draft conversion. Run it before claiming the whole set builds.
- Run `nix fmt` to apply the formatters. Formatting a file inside a `src = ./.` package changes that package's derivation.

## Consumers

- onix-core follows this flake's `nixpkgs`, `llm-agents`, `wrappers`, and `treefmt-nix` inputs from its own lock. Before merging a package change, evaluate the onix-core machines that use the package.
- Do not push or publish unless explicitly requested.

## Lifecycle

Use native Cairn under `.cairn/`.
