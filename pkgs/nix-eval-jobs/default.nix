{
  lib,
  fetchFromGitHub,
  callPackage,
  stdenv,
  nixOnix,
}:
let
  forkRevision = "f93f28ad9dce007baae13aa461c16abf656d1171";
  sourceRevision = "9f1553afabd95f9f59951f5c946e86005af7196a";
  source = fetchFromGitHub {
    owner = "NixOS";
    repo = "nix-eval-jobs";
    rev = sourceRevision;
    hash = "sha256-t1FbcjvTWQ1WO3hJNKN+viNXuz4BX9Pte5K4F+IJLDk=";
  };
  components = nixOnix.packages.${stdenv.hostPlatform.system};
in
assert lib.assertMsg (
  nixOnix.rev == forkRevision
) "nix-eval-jobs requires the pinned Onix Nix fork ${forkRevision}";
assert lib.assertMsg (
  components.nix-cli.version == "2.36.0"
) "nix-eval-jobs requires Onix Nix CLI version 2.36.0";
(callPackage "${source}/default.nix" { nixComponents = components; }).overrideAttrs (previous: {
  patches = (previous.patches or [ ]) ++ [
    ./onix-nix-2.36-derivations.patch
    ./onix-nix-2.36-api.patch
  ];
  passthru = (previous.passthru or { }) // {
    onixForkRevision = forkRevision;
    nixEvalJobsSourceRevision = sourceRevision;
  };
})
