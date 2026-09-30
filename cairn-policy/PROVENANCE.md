# Cairn policy provenance

`default.ncl` and its three imported dependencies are exact snapshots of
`OnixResearch/cairn` revision `007ba5193dd8fec9067a1c0e0f8ef487807af872`,
source NAR `sha256-Kgx8JgsC/+26ETbL3lRaxXAYfzv2cmtG/i9OywPOz0c=`.
The source is `git+ssh://git@github.com/OnixResearch/cairn.git`.

| File | Source BLAKE3 |
| --- | --- |
| `default.ncl` | `c3b5981d71789b04ff3a7567a84a7b1df29b5703dcb3a65e664143713e77a97e` |
| `contracts.ncl` | `bc537dc32ff01fc9004dc032b78ad6fb5855c5c6f0158ecda219d5912b46619c` |
| `lifecycle-store-contracts.ncl` | `cfa0842a93d34d87db473c5f3a26b2e6b8285bf4d0fffc6bc9ffc54c77f32b99` |
| `nominal-evidence-identities.ncl` | `6e4798683072695e0c06feb2ceac31d9aa9fa74f6821c048c875dfe5b4c92b6c` |

The authoritative repository had `.cairn/` changes but no `cairn-policy/`
before this import. No previous repository-specific policy intent was replaced.
The default policy retains its required `outcome-machine` profile and admits
existing changes' explicit `spec-driven` selection. Regenerate only with
`cairn policy export --source cairn-policy/default.ncl --output cairn-policy/generated/cairn-policy.json`;
verify freshness with the same command plus `--check`.

This snapshot supplies lifecycle policy structure. It does not prove package
behavior, transfer gate authority from Cairn, or authorize release by itself.
