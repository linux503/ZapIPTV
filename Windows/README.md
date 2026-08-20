# ZapIPTV Windows（开发骨架说明）

你本次选择的是：
- Windows 桌面客户端
- `.NET/MAUI`
- 播放使用 `VLC`（优先实现快速可用）

## 当前限制
本机环境里没有 `dotnet` SDK（`dotnet --info` 显示命令不存在），因此我无法在这里直接编译并产出 `.exe/.msi` 安装包。

## 我接下来能交付什么
我已经把官网的 Windows 部分写入路线图和下载入口（Coming soon）。
同时在这里给出一个“可在 Windows 上一键生成”的项目骨架清单（你在 Windows 机器上跑完就能得到可发布产物）。

## 在 Windows 上生成 MAUI 客户端的建议步骤
1. 安装 .NET 8 SDK
2. 在 Visual Studio / VS Code 安装 MAUI Workload
3. 创建新 MAUI App（空模板）
4. 集成 VLC 播放控件
   - 推荐：使用 VLC.DotNet（具体包名/版本以 NuGet 检索为准）
5. 复用 ZapIPTV 的核心概念：
   - 区域分类：🇨🇳/🇹🇼/🇭🇰/🇯🇵/🇰🇷/SEA
   - IPTV/M3U 导入（同样解析得到 stream URL）

## 需要你确认的一个实现细节
当你在 Windows 端接入 VLC 时，你希望播放控件是：
- A. “视频控件内嵌”（类似 AVPlayerView）
- B. “单独弹窗播放器”

确认后我就可以把 Windows 端的 UI 结构和对接点写成更明确的代码骨架。

你当前选择：A（视频控件内嵌）。

