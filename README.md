# Claude Desktop 镜像仓库

给国内下载不动的场景准备的**安装包镜像**：GitHub Actions 定时/手动抓 `claude.ai/download` 的最新版，发布成本仓库的 Release。你从本仓库的 Release 下载即可，不需要访问 `claude.ai`。

## 直接下载

打开 [Releases](../../releases/latest)，按平台取：

| 平台 | 文件名（示例） |
| --- | --- |
| Windows x64 | `Claude-Science-<ver>.exe` |
| Windows arm64 | `Claude-Science-<ver>-arm64.exe` |
| macOS Apple Silicon | `Claude-Science-<ver>.dmg` |
| macOS Intel | `Claude-Science-<ver>-Intel.dmg` |
| Linux x64 | `claude-science-<ver>-linux-x64`（ELF 可执行文件，`chmod +x` 后直接跑） |

每个 Release 还附带 `SHA256SUMS.txt`、`manifest.json`、`download-helper.sh`。

## 一条命令全下（推荐，带断点续传）

```bash
curl -O https://raw.githubusercontent.com/daomengkiller/claude-mirror/main/download-helper.sh
MIRROR=https://ghfast.top/ bash download-helper.sh          # 走加速前缀
bash download-helper.sh v0.1.72                             # 指定版本，直连
```

`MIRROR` 可换成任意可用前缀（`https://ghfast.top/`、`https://gh-proxy.com/` 等），脚本会拼在 `https://github.com/...` 前面。

## Linux 说明

官方站点明确写了：Claude Desktop for Linux 处于 **beta**，支持 Ubuntu / Debian（x64）。当前只发布了 x64（`linux-arm64` 返回 404）。
产物是**无扩展名的 ELF 可执行文件**（不是 deb/AppImage），落地后：

```bash
chmod +x claude-science-*-linux-x64
./claude-science-*-linux-x64
```

## 自己跑

Actions → `mirror-claude-desktop` → **Run workflow**：

| 输入 | 说明 |
| --- | --- |
| `force` | 同版本也重建 release（`true`/`false`） |
| `keep_releases` | 保留最近几份，默认 2 |
| `max_total_mb` | 资产总大小上限，超了先删最旧的，默认 3000 |

同版本重复触发会直接跳过（第 3 步判定），不会重复占用存储。定时任务每天 03:17 UTC 自检一次新版本，不需要就在 workflow 里删掉 `schedule` 段。

## 说明

- 本仓库只做**搬运**，不改包、不签名、不注入；校验值见每个 Release 的 `SHA256SUMS.txt`。
- 版权归 Anthropic 所有，安装仍需你自己的 Claude 账号。


