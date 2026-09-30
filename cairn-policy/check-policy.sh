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
for stage in proposal design tasks; do
  cairn gate "$stage" add-onix-nix-eval-jobs --root . |
    jq -e '.valid == true and .verdict == "PASS" and .workflow_profile == "spec-driven" and .workflow_profile_compatibility_fallback == false' >/dev/null
done

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
nickel export cairn-policy/fixtures/negative-missing-outcome-profile.ncl >"$scratch/missing-outcome.json"
if cairn gate proposal add-onix-nix-eval-jobs --root . \
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
