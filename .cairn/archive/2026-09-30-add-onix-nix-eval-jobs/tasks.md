## Phase 1: Implementation

- [x] [serial] Pin and build the exact fork-linked evaluator with package-local 2.36 API patches; confirm seven linked fork libraries and absence of stock libnix. r[onixpkgs.eval_jobs.fork_abi]
- [x] [serial] Check two dependent JSONL derivations, a failing job, wrong fork and stock CLI rejection; smoke the consumer's local immutable Nickel snapshot and observe no-WASM rejection without treating its dirty source as a published pin. r[onixpkgs.eval_jobs.fork_abi] r[onixpkgs.eval_jobs.jsonl]
- [x] [serial] Import the authenticated four-file Cairn Nickel closure, export/check generated JSON, verify positive spec-driven gates and reject missing outcome-machine fixture. r[onixpkgs.eval_jobs.cairn_policy]
- [x] [serial] Document source and package boundaries, run scoped Nix build, JSONL check and formatting check. r[onixpkgs.eval_jobs.fork_abi] r[onixpkgs.eval_jobs.jsonl]
- [x] [serial] Review the final package and policy pins; pass native Cairn validation, strict proposal/design/tasks gates, the package build/JSONL check and formatting. Publication remains a separate owner decision and cannot make a dirty consumer snapshot into a published source pin. r[onixpkgs.eval_jobs.cairn_policy] r[onixpkgs.eval_jobs.fork_abi]
- [x] [serial] Export the evaluator only as `nix-eval-jobs-onix`, update all owning contracts and checks, rebuild it, and evaluate an onix-core machine with the candidate overlay to preserve its independently overridden generic `nix-eval-jobs`. r[onixpkgs.eval_jobs.fork_abi]
