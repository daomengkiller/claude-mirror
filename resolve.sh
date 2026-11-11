#!/usr/bin/env bash
# 解析 Anthropic 官方下载页 → 产出 manifest.json（url / file / size / etag / platform）
# 由 workflow 调用，也可单独跑：bash resolve.sh > manifest.json
set -euo pipefail

BASE="https://downloads.claude.ai/claude-science/latest"
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36'
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

echo "· 抓取官方下载页" >&2
PAGE=$(curl -sL --retry 3 --retry-delay 2 -A "$UA" https://claude.com/download || true)

# 落地页上明写的链接 + 已知的 arm64 / x64 变体（页面下拉菜单里不一定全列）
{
  echo "$PAGE" | grep -oE 'https://downloads\.claude\.ai[^"'"'"' )\\]+' || true
  echo "$BASE/windows-x64.exe"
  echo "$BASE/windows-arm64.exe"
  echo "$BASE/mac-arm64.dmg"
  echo "$BASE/mac-x64.dmg"
  echo "$BASE/linux-x64"
  echo "$BASE/linux-arm64"
} | sed 's/[",]$//' | sort -u > "$TMP/urls.txt"

echo "· 候选 URL $(wc -l < "$TMP/urls.txt") 条，逐个探活" >&2

: > "$TMP/items.jsonl"
while read -r url; do
  [ -n "$url" ] || continue
  hdr=$(curl -sIL -m 30 -A "$UA" "$url" 2>/dev/null || true)
  code=$(printf '%s\n' "$hdr" | grep -oE '^HTTP/[0-9.]+ [0-9]{3}' | tail -1 | awk '{print $2}')
  [ "$code" = "200" ] || { echo "  × $url ($code)" >&2; continue; }

  disp=$(printf '%s\n' "$hdr" | grep -i '^content-disposition:' | tail -1 | sed 's/.*filename="\?//; s/"\r\?$//' | tr -d '\r')
  size=$(printf '%s\n' "$hdr" | grep -i '^content-length:' | tail -1 | awk '{print $2}' | tr -d '\r')
  etag=$(printf '%s\n' "$hdr" | grep -i '^etag:' | tail -1 | sed 's/^[Ee][Tt]ag: *//' | tr -d '"\r')
  lm=$(printf '%s\n' "$hdr" | grep -i '^last-modified:' | tail -1 | sed 's/^[Ll]ast-[Mm]odified: *//' | tr -d '\r')

  file="${disp:-$(basename "$url")}"
  case "$url" in
    *windows-x64*)        plat="windows-x64";;
    *windows-arm64*)      plat="windows-arm64";;
    *mac-arm64*)          plat="macos-arm64";;
    *mac-x64*|*Intel*)    plat="macos-x64";;
    *linux-x64*)          plat="linux-x64";;
    *linux-arm64*)        plat="linux-arm64";;
    *)                    plat="other";;
  esac

  jq -cn --arg url "$url" --arg file "$file" --arg size "$size" \
        --arg etag "$etag" --arg lm "$lm" --arg plat "$plat" \
        '{url:$url, file:$file, size:($size|tonumber? // 0), etag:$etag, last_modified:$lm, platform:$plat}' \
    >> "$TMP/items.jsonl"
  echo "  √ $plat  $file  ${size} bytes" >&2
done < "$TMP/urls.txt"

jq -s 'sort_by(.platform)' "$TMP/items.jsonl"

# 版本号：从文件名里抽 x.y.z
VER=$(jq -r '.[].file' "$TMP/items.jsonl" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1 || true)
echo "· 解析到版本: ${VER:-未知}" >&2
printf '%s' "${VER:-unknown}" > .version


