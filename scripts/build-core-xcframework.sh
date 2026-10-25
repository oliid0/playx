#!/bin/bash
# 交叉编译 native/（vendor 自 guoapp-src 的 Go 原生核心）为静态库，
# 打包成 DuanjuCore.xcframework 供 iPhone / iPad / Mac 三个平台链接。
# 只能在 macOS + 完整 Xcode 下跑（CI 用）。
#
# 产物：
#   native/build/DuanjuCore.xcframework/   给 Xcode 链接（iOS arm64 + macOS arm64/x86_64）
#   native/build/ios/libDuanjuCore.a       调试用中间产物
#   native/build/macos/libDuanjuCore.a     调试用中间产物（arm64 + x86_64 fat）
#
# 用法：bash scripts/build-core-xcframework.sh [--all-sources]
set -euo pipefail
echo "bash: $BASH_VERSION"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALL_SOURCES=false
if [[ "${1:-}" == "--all-sources" ]]; then
  ALL_SOURCES=true
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "需要 macOS + Xcode 才能交叉编译 Go 核心。" >&2
  exit 1
fi
if ! command -v go >/dev/null 2>&1; then
  echo "未找到 go，请先安装 Go 1.24.1 或更新版本（CI 里用 brew install go）。" >&2
  exit 1
fi

export GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"
export GOSUMDB="${GOSUMDB:-off}"
export CGO_ENABLED=1

IOS_SDK="iphoneos"
IOS_SDK_PATH="$(xcrun --sdk "$IOS_SDK" --show-sdk-path)"
IOS_CC="$(xcrun --sdk "$IOS_SDK" --find clang)"
IOS_TRIPLE="arm64-apple-ios16.0"
IOS_FLAGS="-isysroot $IOS_SDK_PATH -target $IOS_TRIPLE"

MAC_SDK="macosx"
MAC_SDK_PATH="$(xcrun --sdk "$MAC_SDK" --show-sdk-path)"
MAC_CC="$(xcrun --sdk "$MAC_SDK" --find clang)"
MAC_MIN="13.0"

IOS_OUT="$ROOT/native/build/ios"
MAC_OUT="$ROOT/native/build/macos"
IOS_HEADERS="$IOS_OUT/Headers"
MAC_HEADERS="$MAC_OUT/Headers"
mkdir -p "$IOS_HEADERS" "$MAC_HEADERS"

build_slice() {
  local cc="$1"
  local goos="$2"
  local goarch="$3"
  local flags="$4"
  local out="$5"
  local label="$6"

  echo "==> $label -> $out (GOOS=$goos GOARCH=$goarch, all-sources=$ALL_SOURCES)"
  (
    cd "$ROOT/native"
    CC="$cc" GOOS="$goos" GOARCH="$goarch" \
      CGO_CFLAGS="$flags" CGO_LDFLAGS="$flags" \
      go build -trimpath -buildmode=c-archive \
      -ldflags "-s -w -X duanjuapp/native/core.buildAllSources=$ALL_SOURCES" \
      -o "$out" ./bridge
  )
}

# 1) iPhone / iPad 真机
build_slice "$IOS_CC" ios arm64 "$IOS_FLAGS" "$IOS_OUT/libDuanjuCore.a" "iOS device arm64"
cp -f "$IOS_OUT/libDuanjuCore.h" "$IOS_HEADERS/DuanjuCore.h"

# 2) macOS Apple Silicon
build_slice "$MAC_CC" darwin arm64 \
  "-isysroot $MAC_SDK_PATH -target arm64-apple-macos$MAC_MIN" \
  "$MAC_OUT/libDuanjuCore-arm64.a" "macOS arm64"

# 3) macOS Intel（兼容 macOS 13 的 Intel Mac）
build_slice "$MAC_CC" darwin amd64 \
  "-isysroot $MAC_SDK_PATH -target x86_64-apple-macos$MAC_MIN" \
  "$MAC_OUT/libDuanjuCore-x86_64.a" "macOS x86_64"

echo "==> 合并 macOS 双架构 -> $MAC_OUT/libDuanjuCore.a"
lipo -create \
  "$MAC_OUT/libDuanjuCore-arm64.a" \
  "$MAC_OUT/libDuanjuCore-x86_64.a" \
  -output "$MAC_OUT/libDuanjuCore.a"

# 两个 slice 的 C 头由同一次 Go 源码生成，内容一致；各放一份避免 xcframework 引用同一个
# 目录时 Xcode 在增量构建里报 header 所有关系错误。
cp -f "$MAC_OUT/libDuanjuCore-arm64.h" "$MAC_HEADERS/DuanjuCore.h"

FRAMEWORK="$ROOT/native/build/DuanjuCore.xcframework"
rm -rf "$FRAMEWORK"
echo "==> 打包 xcframework -> $FRAMEWORK"
xcodebuild -create-xcframework \
  -library "$IOS_OUT/libDuanjuCore.a" -headers "$IOS_HEADERS" \
  -library "$MAC_OUT/libDuanjuCore.a" -headers "$MAC_HEADERS" \
  -output "$FRAMEWORK"

echo "✓ 完成: $FRAMEWORK"
