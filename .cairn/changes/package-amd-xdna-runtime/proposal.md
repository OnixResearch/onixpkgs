## Why

AMD XDNA devices require both XRT NPU userspace and its version-matched XDNA plugin; FPGA-only XRT and PCI enumeration do not establish usable NPU execution. Consumers should not need Ubuntu installers or local source checkouts.

## What Changes

Export one `amd-xdna-runtime` package on x86_64-linux, using xdna-driver stable tag 2.21.75 and its exact recursive XRT submodule pin. Build tools and plugin together with normal Nix library discovery. Keep device policy, kernel, firmware and target tests in the consumer. Default to free userspace; make binary-only redistributable official Strix test data a clearly licensed opt-in override.

## Impact

Files: package directory, README, and this Cairn change only. Acceptance is a real local package build and CLI version/help smoke, not hardware functionality. Consumer adoption requires a canonical published onixpkgs revision, device permissions, compatible existing kernel/firmware, and explicit authorization for finite device validation and its temporary power-mode change.
