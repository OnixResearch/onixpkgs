{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  cmake,
  pkg-config,
  git,
  boost,
  libdrm,
  libuuid,
  ncurses,
  ocl-icd,
  opencl-headers,
  openssl,
  systemtap-unwrapped,
  withValidationData ? false,
}:
let
  version = "2.21.75";
  xdnaRevision = "beb9e450fe123ecdf395453971576179cedcf1dd";
  # The xrt gitlink at xdna-driver tag 2.21.75, not an independent XRT pin.
  xrtRevision = "4eb1f4392a012b4e6eca759762389c612537f7c7";
  xrtSource = fetchFromGitHub {
    owner = "Xilinx";
    repo = "XRT";
    rev = xrtRevision;
    fetchSubmodules = true;
    hash = "sha256-sujiSRZuIelhvUew7yeCfApAmp/Pf2+F38KO9cxI2HE=";
  };
  # Official Strix validation archive selected by tools/info.json at this tag.
  validationRevision = "c79b5d21568a4ffa5b0612a8279b352fc4e1109a";
  validationData = fetchurl {
    url = "https://raw.githubusercontent.com/Xilinx/VTD/${validationRevision}/archive/strx/xrt_smi_strx.a";
    hash = "sha256-VzhPDVzz/GBLAFQO2bdUKCbNlhwwovMgc1fJcsw+8yw=";
  };
  validationLicense = fetchurl {
    url = "https://raw.githubusercontent.com/Xilinx/VTD/${validationRevision}/LICENSE.vtd";
    hash = "sha256-3prdws5Si3wrj53U7bfAKcwaVfLyIarxUXndOiIlHUE=";
  };
in
stdenv.mkDerivation {
  pname = "amd-xdna-runtime";
  inherit version;

  src = fetchurl {
    url = "https://codeload.github.com/amd/xdna-driver/tar.gz/${xdnaRevision}";
    hash = "sha256-4fdHl9rgZqZZb+0phCf46IxSlj5ojjCo/pcXDNh2M7E=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    git
  ];
  buildInputs = [
    boost
    libdrm
    libuuid
    ncurses
    ocl-icd
    opencl-headers
    openssl
    systemtap-unwrapped
  ];

  unpackPhase = ''
    runHook preUnpack
    mkdir -p source/xdna
    tar -xf "$src" --strip-components=1 -C source/xdna
    cp -r ${xrtSource} source/xrt
    chmod -R u+w source/xrt
    cp ${./CMakeLists.txt} source/CMakeLists.txt
    sourceRoot=source
    runHook postUnpack
  '';

  postPatch = ''
    patch -p1 -d xrt < ${./target-distro.patch}
    patch -p1 -d xdna < ${./runtime-install.patch}
    # GCC 16 requires the standard namespace-level memory-order constant.
    substituteInPlace xdna/src/shim/umq/dbg_hwq.cpp \
      xdna/src/shim/umq/hwq.cpp \
      --replace-fail "std::memory_order::memory_order_seq_cst" "std::memory_order_seq_cst"
  '';

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_BINDIR=bin"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DLINUX_FLAVOR=nixos"
    "-DXRT_ENABLE_HIP=OFF"
    "-DAIEBU_PYTHON=OFF"
  ];
  enableParallelBuilding = true;

  postInstall = ''
    # Use the real ELF tools with Nix RPATHs, not distro loader scripts
    # that source setup.sh and edit LD_LIBRARY_PATH.
    for tool in "$out"/bin/unwrapped/*; do
      mv -f "$tool" "$out/bin/$(basename "$tool")"
    done
    rmdir "$out/bin/unwrapped"
    install -Dm644 ${xrtSource}/LICENSE "$out/share/licenses/amd-xdna-runtime/LICENSE.xrt"
    install -Dm644 ${xrtSource}/NOTICE "$out/share/licenses/amd-xdna-runtime/NOTICE.xrt"
    install -Dm644 ${xrtSource}/src/runtime_src/core/common/aiebu/LICENSE "$out/share/licenses/amd-xdna-runtime/LICENSE.aiebu"
    install -Dm644 ${xrtSource}/src/runtime_src/core/common/aiebu/NOTICE "$out/share/licenses/amd-xdna-runtime/NOTICE.aiebu"
    install -Dm644 ${xrtSource}/src/runtime_src/aie-rt/license.txt "$out/share/licenses/amd-xdna-runtime/LICENSE.aie-rt"
    cat > "$out/share/amd-xdna-runtime.json" <<EOF
    ${builtins.toJSON {
      inherit version xdnaRevision xrtRevision withValidationData;
      validationRevision = if withValidationData then validationRevision else null;
      kernelModule = "external in-tree amdxdna; no kernel module or firmware installed";
    }}
    EOF
  '' + lib.optionalString withValidationData ''
    # For prefixes not literally named xrt, platform_path searches share/xrt.
    install -Dm644 ${validationData} "$out/share/xrt/amdxdna/bins/xrt_smi_strx.a"
    install -Dm644 ${validationLicense} "$out/share/licenses/amd-xdna-runtime/LICENSE.vtd"
  '';

  passthru = {
    inherit xdnaRevision xrtRevision validationRevision;
  };

  meta = {
    description = "XRT NPU userspace tools and matching AMD XDNA driver plugin";
    homepage = "https://github.com/amd/xdna-driver";
    license = [ lib.licenses.asl20 lib.licenses.mit ] ++ lib.optional withValidationData lib.licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
    mainProgram = "xrt-smi";
  };
}
