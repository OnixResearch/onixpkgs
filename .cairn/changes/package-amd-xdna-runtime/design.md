## Design

A package-local CMake parent builds the NPU component from the XRT gitlink of xdna-driver tag 2.21.75, then invokes xdna-driver upstream mode to reuse the same generated headers and link targets. This avoids two separately configured XRT copies and ABI drift. Install the real ELF tools rather than distro setup wrappers. Keep libxrt_core, its libxrt_driver_xdna.so.2 discovery symlink, and module layout in one prefix.

The plugin is Apache-2.0; neither the repository binary firmware license nor firmware itself is included. VTD is a lazy optional input with unfreeRedistributable metadata and its own retained license; the default closure is free. No installer, module, udev policy, global library path, error suppression or fake execution fallback is supplied.

Runtime compatibility must be checked against the actual in-tree amdxdna and firmware; newer optional telemetry can legitimately be unavailable on kernel 6.18. Local version/help proves CLI loading, not device work. The consumer owns queries, any authorized GEMM validation, and checking power-mode restoration.

## Initial build evidence

The final free runtime and explicitly authorized `withValidationData = true` override both built locally with command-local no-GC and local-builder configuration. Both real `xrt-smi --version` and `--help` exited zero with `LD_LIBRARY_PATH` and `XILINX_XRT` removed; version was 2.21.75. The free output measured 40,535,832 NAR bytes and 150,267,448 closure bytes; the optional output measured 76,602,224 NAR bytes and 186,333,840 closure bytes. The installed VTD archive retained SHA-256 `VzhPDVzz/GBLAFQO2bdUKCbNlhwwovMgc1fJcsw+8yw=` exactly. These checks did not run a device workload or change a target. Hardware compatibility and restoration remain the consumer's separate acceptance step.

## Validation archive discovery correction

Consumer hardware testing successfully queried the NPU after an approved finite memlock allowance, then reported `No archive provided, skipping test` and a failed GEMM result. The original optional install used the distro layout `share/amdxdna`, but matched XRT `detail/linux/xilinx_xrt.h::platform_repo_path` searches `share/xrt` when the installation prefix basename is not literally `xrt`. The shim selects relative `amdxdna/bins/xrt_smi_strx.a` for Strix, including PCI 17f0 revision11. Install the unmodified archive at `share/xrt/amdxdna/bins/xrt_smi_strx.a`; no global environment override, explicit archive selector, shim patch, or error suppression is needed.

The corrected optional output built successfully at `/nix/store/ivi199dzfmmk7gng2wca46xyn0rzbpdn-amd-xdna-runtime-2.21.75`, rooted by `/tmp/aspen-xdna-packaging/discovery-runtime-1`. It measured 76,602,392 NAR bytes and 186,334,008 closure bytes. Version/help smoke both exited zero with `LD_LIBRARY_PATH` and `XILINX_XRT` removed, reporting 2.21.75. The archive hash remained exactly unchanged. The free output remained `/nix/store/37kk09jxa0jnv2w9ki4c6cd8rjnanspw-amd-xdna-runtime-2.21.75`. These local checks establish packaging/CLI evidence, not successful GEMM execution; the consumer owns the corrected target retest.

## Kernel feature compatibility boundary

The consumer's corrected-archive GEMM test failed with `DRM_IOCTL_AMDXDNA_CONFIG_HWCTX` returning `-EOPNOTSUPP`, not successful execution. The official recipe creates a debug/result BO; matched XRT runner allocates it with debug use, and the shim attaches it through `DRM_AMDXDNA_HWCTX_ASSIGN_DBG_BUF` (parameter 1). Upstream Linux v6.18.60 `aie2_hwctx_config` explicitly rejects assignment/removal of debug buffers. UAPI enum presence and successful enumeration do not establish implementation. The matched out-of-tree driver implements those operations; upstream commit `7ea0468380216c10b73633b976d33efa8c12d375` introduced the in-tree implementation and feature ABI 0.3, present in checked Linux v6.19. A maintained kernel/module with this feature and subsequent fixes, plus compatible firmware, is an independently approved consumer prerequisite for this GEMM test.

The examined maintained xdna-driver 1.4 and 1.5 XRT pins already create debug BOs for GEMM; 1.6 uses the same runner/result-buffer approach. No evidenced userspace-only downgrade fixes the missing kernel operation for this workload. Do not remove the debug resource or suppress its errors. No package compatibility change or rebuild was justified by this finding; existing outputs remain rooted. No target test was repeated and no kernel/firmware state was changed by this investigation.

## Ordinary compute without firmware-debug BOs

The missing debug-buffer feature does not imply that every ordinary compute workload needs a kernel change. The approved installed archive contains an unmodified official `recipe_temporal_sharing_ovd.json` that uses the same real GEMM xclbin/ELF with no resource buffers, plus a finite original throughput profile of 100 iterations at depth 15. The packaged official standalone `xrt-runner` accepts that recipe, profile and extracted artifact directory, uses device index 0, waits for completion and propagates failures; unlike the xrt-smi temporal benchmark it need not collect preemption telemetry or run two contexts, and it does not request a power mode. README documents exact member extraction and invocation without changing the payload or suppressing a required debug request.

This alternative has no numeric result/golden comparison and therefore offers real arithmetic workload completion evidence only, not arithmetic correctness proof. The other examined approved Strix recipes are no-op, DMA or reconfiguration timing tests. The source-matched KMQ shim tests do check golden outputs but require the separate NPU5_1x4_TESTCASES workload/input/golden files absent from this archive; the vector-add source examples target NPU3/UMQ. No new package build or target execution was performed in this source-only investigation. Consumer authorization and execution results remain separate.

## Canonical GCC 16 compatibility

The consumer's actual GCC16.2 build rejected std::memory_order::memory_order_seq_cst in the vendor UMQ queue fences. Both occurrences, in dbg_hwq.cpp and hwq.cpp, use the standard std::memory_order_seq_cst constant at package patch time. This preserves sequentially consistent fences, does not disable diagnostics or change component pins, and makes the actual consumer build the acceptance check rather than relying on the earlier standalone toolchain.

