#!/usr/bin/env bash
# Build nifty_tool from the cool_tools repository and run the portable
# zipapp from outside the bazel tree, with and without
# experimental_python_import_all_repositories=false.
set -euo pipefail
cd "$(dirname "$0")"

no_import_all=--@rules_python//python/config_settings:experimental_python_import_all_repositories=false

# build_and_run <target> [bazel flags...]
# Builds @cool_tools//nifty:<target>, copies the zipapp to /tmp, and runs it.
function build_and_run() {
  local target="$1"
  shift
  bazel build "$@" "@cool_tools//nifty:${target}"
  rm -f "/tmp/${target}"
  cp "$(bazel info "$@" bazel-bin)/external/+local_repository+cool_tools/nifty/${target}.pyz" "/tmp/${target}"
  "/tmp/${target}"
}

echo '#######################################'
echo 'Try nifty_tool with the default experimental_python_import_all_repositories'
build_and_run nifty_tool

echo '#######################################'
echo 'Try nifty_tool with experimental_python_import_all_repositories=false'
build_and_run nifty_tool "$no_import_all" \
  || echo 'We fail with experimental_python_import_all_repositories=false, as expected'

echo '#######################################'
echo 'Try nifty_tool2, which sets imports on the binary, with experimental_python_import_all_repositories=false'
build_and_run nifty_tool2 "$no_import_all"
