{
  pkgs,
  evaluator,
  nixOnix,
}:
let
  invalidFork = nixOnix // {
    rev = "not-the-pinned-onix-fork";
  };
  rejectsWrongFork =
    !(builtins.tryEval (evaluator.override { nixOnix = invalidFork; }).drvPath).success;
  stockComponents = nixOnix.packages // {
    ${pkgs.stdenv.hostPlatform.system} = nixOnix.packages.${pkgs.stdenv.hostPlatform.system} // {
      nix-cli = pkgs.nix;
    };
  };
  rejectsStockNix =
    !(builtins.tryEval
      (evaluator.override {
        nixOnix = nixOnix // {
          packages = stockComponents;
        };
      }).drvPath
    ).success;
in
assert rejectsWrongFork;
assert rejectsStockNix;
pkgs.runCommand "onix-nix-eval-jobs-jsonl"
  {
    nativeBuildInputs = [
      evaluator
      pkgs.jq
      nixOnix.packages.${pkgs.stdenv.hostPlatform.system}.nix-cli
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    export NIX_STATE_DIR="$TMPDIR/state"
    export NIX_STORE_DIR="$TMPDIR/store"
    export NIX_DATA_DIR="$TMPDIR/data"
    export NIX_LOG_DIR="$TMPDIR/log"
    export NIX_CONF_DIR="$TMPDIR/conf"
    mkdir -p "$HOME" "$NIX_STATE_DIR" "$NIX_STORE_DIR" "$NIX_DATA_DIR" "$NIX_LOG_DIR" "$NIX_CONF_DIR"
    cat > "$NIX_CONF_DIR/nix.conf" <<'EOF'
    experimental-features = nix-command flakes wasm-builtin
    flake-registry =
    substituters =
    sandbox = false
    EOF

    nix-eval-jobs --workers 1 --show-input-drvs --expr '
      let
        base = derivation {
          name = "onix-eval-base";
          system = "x86_64-linux";
          builder = "/bin/sh";
          args = [ "-c" "echo base > $out" ];
        };
      in {
        inherit base;
        dependent = derivation {
          name = "onix-eval-dependent";
          system = "x86_64-linux";
          builder = "/bin/sh";
          args = [ "-c" "echo dependent > $out" ];
          parent = base.out;
        };
        rejected = throw "onix-eval-rejected-fixture";
      }
    ' > jobs.jsonl

    jq -se '
      length == 3 and
      ([.[].attr] | sort) == ["base", "dependent", "rejected"] and
      ((map(select(.attr == "base"))[0]) as $base |
        (map(select(.attr == "dependent"))[0]) as $dependent |
        ($base.drvPath | type) == "string" and
        ($dependent.inputDrvs[$base.drvPath] == ["out"])) and
      (map(select(.attr == "rejected"))[0].error | contains("onix-eval-rejected-fixture"))
    ' jobs.jsonl > /dev/null
    touch "$out"
  ''
