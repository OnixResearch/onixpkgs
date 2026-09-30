#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

verify_source() {
  local file=$1 expected=$2 observed
  observed=$(b3sum --no-names "cairn-policy/$file")
  if [[ $observed != "$expected" ]]; then
    printf 'Cairn policy source drift: %s\n' "$file" >&2
    exit 1
  fi
}
verify_source default.ncl c3b5981d71789b04ff3a7567a84a7b1df29b5703dcb3a65e664143713e77a97e
verify_source contracts.ncl bc537dc32ff01fc9004dc032b78ad6fb5855c5c6f0158ecda219d5912b46619c
verify_source lifecycle-store-contracts.ncl cfa0842a93d34d87db473c5f3a26b2e6b8285bf4d0fffc6bc9ffc54c77f32b99
verify_source nominal-evidence-identities.ncl 6e4798683072695e0c06feb2ceac31d9aa9fa74f6821c048c875dfe5b4c92b6c

cairn policy export --source cairn-policy/default.ncl \
  --output cairn-policy/generated/cairn-policy.json --check
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
change=add-onix-nix-eval-jobs
gate_root=.
if [[ ! -d .cairn/changes/$change ]]; then
  archives=(.cairn/archive/*-"$change")
  if ((${#archives[@]} != 1)) || [[ ! -d ${archives[0]} ]]; then
    printf 'expected exactly one active or archived evaluator change\n' >&2
    exit 1
  fi
  # Hashes from the accepted sync receipt and the archive mutation manifest
  # (1fe0f6dab1dd22bc890123bad97eb1d2fa13a7b70d05d4e6444fef5d990ff2cb).
  verify_archived() {
    local file=$1 expected=$2 observed
    observed=$(b3sum --no-names "$file")
    if [[ $observed != "$expected" ]]; then
      printf 'Cairn approved archive drift: %s\n' "$file" >&2
      exit 1
    fi
  }
  archive=${archives[0]}
  verify_archived "$archive/design.md" 9cd8c2e11a2727d91d9580635d4aeaff4cf0d3496a5516cbe9847f66a5bcf07c
  verify_archived "$archive/metadata.json" df8b71bae570eb5accd702e7370a816b8ea9f2e4521254c5d75ea82a9cfcf4db
  verify_archived "$archive/proposal.md" f3697ed5ffca794b0d274260e51165e45c8884c46676d991b9f392e2c2633ea4
  verify_archived "$archive/specs/package-overlay/spec.md" 8a083b144af7499a054ea579cf7389c2124a5d57336cba2ba7546a8548f4e11e
  verify_archived "$archive/tasks.md" e63a21b505c5c15290c3ab2de034ca1f48a413b3f8a93bfb4a0cdb136dad99c9
  verify_archived .cairn/specs/package-overlay/spec.md 50a8c3dc338701c5c1fc97f96c27283ae673ddc05d3fddd58e12e3976a82b02d
  cairn validate --root . | jq -e '.valid == true and .issues == []' >/dev/null
  gate_root="$scratch/archived"
  mkdir -p "$gate_root/.cairn/changes" "$gate_root/.cairn/specs"
  cp -a "${archives[0]}" "$gate_root/.cairn/changes/$change"
fi
for stage in proposal design tasks; do
  cairn gate "$stage" "$change" --root "$gate_root" \
    --policy "$root/cairn-policy/generated/cairn-policy.json" |
    jq -e '.valid == true and .verdict == "PASS" and .workflow_profile == "spec-driven" and .workflow_profile_compatibility_fallback == false' >/dev/null
done

nickel export cairn-policy/fixtures/negative-missing-outcome-profile.ncl >"$scratch/missing-outcome.json"
if cairn gate proposal "$change" --root "$gate_root" \
  --policy "$scratch/missing-outcome.json" >"$scratch/receipt" 2>"$scratch/error"; then
  printf 'policy without required outcome-machine profile was admitted\n' >&2
  exit 1
fi
error=$(<"$scratch/error")
if [[ $error != *'initial workflow profile is missing: outcome-machine'* ]]; then
  printf 'missing outcome-machine failed for the wrong reason: %s\n' "$error" >&2
  exit 1
fi
printf 'native Cairn gates passed; missing outcome-machine rejected\n'
