#!/usr/bin/env bash
# Fetch the versions in android/README.md; never replace an existing checkout.
set -euo pipefail
repo=$(cd "$(dirname "$0")/../.." && pwd)
deps=${1:-$repo/build/native-deps}
mkdir -p "$deps"
deps=$(cd "$deps" && pwd)

fetch() {
  local name=$1 url=$2 rev=$3 dir="$deps/$1"
  if [ -e "$dir" ]; then
    if [ ! -d "$dir/.git" ] || [ "$(git -C "$dir" rev-parse HEAD)" != "$rev" ]; then
      echo "$name: existing directory is not the pinned checkout; use a fresh deps directory" >&2
      exit 1
    fi
    echo "$name: already at $rev"
    return
  fi
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" remote add origin "$url"
  # Fetch the complete SHA explicitly: nv2a_vsh_cpu's pin is not on a branch.
  git -C "$dir" fetch --depth 1 origin "$rev"
  git -C "$dir" checkout -q --detach FETCH_HEAD
  test "$(git -C "$dir" rev-parse HEAD)" = "$rev"
}

fetch volk https://github.com/zeux/volk.git 0b17a763ba5643e32da1b2152f8140461b3b7345
fetch glslang https://github.com/KhronosGroup/glslang.git b5782e52ee2f7b3e40bb9c80d15b47016e008bc9
fetch spirv_reflect https://github.com/KhronosGroup/SPIRV-Reflect.git ef913b3ab3da1becca3cf46b15a10667c67bebe5
fetch vma https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator.git 1d8f600fd424278486eade7ed3e877c99f0846b1
fetch SDL3 https://github.com/libsdl-org/SDL.git 829a65d769d935c4852f8159e964312c0957260a
fetch adrenotools https://github.com/bylaws/libadrenotools.git 8fae8ce254dfc1344527e05301e43f37dea2df80
fetch root/subprojects/nv2a_vsh_cpu https://github.com/xemu-project/nv2a_vsh_cpu.git 561fe80da57a881f89000256b459440c0178a7ce
# GitHub mirror of the unmodified upstream libslirp 4.7.0 commit.
fetch libslirp https://github.com/utmapp/libslirp.git 26be815b86e8d49add8c9a8b320239b9594ff03d

git -C "$deps/adrenotools" submodule update --init --recursive
patch="$repo/tools/native/adrenotools-kgsl-context-priority.patch"
if git -C "$deps/adrenotools" apply --reverse --check "$patch" 2>/dev/null; then
  echo 'adrenotools: repository patch already applied'
else
  git -C "$deps/adrenotools" apply --check "$patch"
  git -C "$deps/adrenotools" apply "$patch"
fi
echo "Native dependencies ready in $deps"
