#!/usr/bin/env bash
# LLVM toolchain pin for Li (sourced by studio gate scripts).
LI_LLVM_MAJOR="${LI_LLVM_MAJOR:-22}"

li_detect_compilers() {
  local v="${LI_LLVM_MAJOR:-22}"
  if [[ -n "${CC:-}" && -n "${CXX:-}" ]]; then
    return 0
  fi
  if [[ "$(uname -s)" == "Darwin" ]]; then
    export CC="${CC:-clang}"
    export CXX="${CXX:-clang++}"
    return 0
  fi
  if command -v "clang-${v}" >/dev/null 2>&1; then
    export CC="clang-${v}"
    export CXX="clang++-${v}"
    return 0
  fi
  export CC="${CC:-clang}"
  export CXX="${CXX:-clang++}"
}
