# SPDX-License-Identifier: Apache-2.0
cmake_minimum_required(VERSION 3.19...4.0)
project(amd_xdna_runtime LANGUAGES C CXX)

# Build the official NPU (base + PCIe core + tools) component, not Alveo.
set(XRT_NPU ON)
set(XRT_UPSTREAM_DEBIAN ON)
set(XRT_BUILD_NUMBER 75)
set(XRT_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/xrt/src")
set(XRT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/xrt")
set(XRT_EXCLUDE_INCLUDE_FILE src/CMake/nativeTests.cmake)
set(XRT_EXCLUDE_SUB_DIRECTORY
    src/python
    src/runtime_src/doc
    src/runtime_src/tools/scripts
    src/runtime_src/tools/xclbinutil
    src/runtime_src/core/tools/xbtracer)
add_subdirectory(xrt/src xrt)

# xdna-driver's upstream mode builds only the userspace plugin, reusing
# the exact XRT headers, generated headers, and targets above.
set(XRT_UPSTREAM ON)
set(XRT_VERSION_STRING 2.21.75)
set(XRT_SOVERSION 2)
set(XDNA_PKG_LIB_DIR lib)
add_subdirectory(xdna)
