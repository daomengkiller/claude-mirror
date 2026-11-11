#!/usr/bin/env bash
# Claude Desktop 镜像下载助手（随 release 一起发布）
# 用法:
#   bash download-helper.sh                 # 下最新
#   bash download-helper.sh v0.1.72         # 下指定版本
#   MIRROR=https://ghfast.top/ bash download-helper.sh   # 走国内加速前缀
set -euo pipefail

REPO="${REPO:-daomengkiller/claude-mirror}"
TAG="${1:-latest}"
MIRROR="${MIRROR:-}"
DEST="${DEST:-./claude-desktop-$TAG}"

command -v jq >/dev/null || { echo "需要 jq：apt install jq / brew install jq"; exit 1; }

if [ "$TAG" = "latest" ]; then
  API="https://api.github.com/repos/$REPO/releases/latest"
else
  API="https://api.github.com/repos/$REPO/releases/tags/$TAG"
fi

mkdir -p "$DEST"
echo "读取资产列表: $API"
curl -fsSL "$API" -o /tmp/rel.json
VER=$(jq -r '.tag_name' /tmp/rel.json)
echo "版本: $VER  →  $DEST"

jq -r '.assets[] | "\(.name)\t\(.browser_download_url)"' /tmp/rel.json |
while IFS=$'\t' read -r name url; do
  out="$DEST/$name"
  [ -f "$out" ] && { echo "跳过（已存在）$name"; continue; }
  real="${MIRROR}${url}"
  echo "↓ $name"
  curl -fL --retry 5 --retry-delay 3 -C - -o "$out" "$real"
done

echo
echo "校验哈希:"
( cd "$DEST" && sha256sum -c SHA256SUMS.txt 2>/dev/null || echo "(无 SHA256SUMS.txt，跳过)" )
echo "完成 → $DEST"


