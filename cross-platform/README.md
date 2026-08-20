# ZapIPTV 2.0 — 跨平台客户端

与 macOS 原生版共享同一套亚洲频道目录（M3U 源、华语影视、春晚等）。

## 目录

| 路径 | 说明 |
|------|------|
| `web/` | 共用 Web UI（首页、直播、设置） |
| `electron/` | Windows 桌面壳（Electron） |
| `android/` | Android WebView 壳 |
| `scripts/bundle-web.sh` | 打包单文件 JS（Electron / Android 用） |

## 一键构建（Mac 上）

```bash
./scripts/build-all.sh
```

产物在 `dist/`：

- `ZapIPTV-2.0.0-universal-installer.dmg` — macOS（Apple Silicon + Intel）
- `ZapIPTV-2.0.0-win-x64.exe` — Windows 便携版
- `ZapIPTV-2.0.0-android.apk` — Android

## 分别构建

```bash
# 1. 打包 Web
bash cross-platform/scripts/bundle-web.sh

# 2. Windows
cd cross-platform/electron && npm install && CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --win portable --x64

# 3. Android（需 JDK 17 + Android SDK）
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
cd cross-platform/android && ./gradlew assembleRelease
```

## 与 macOS 原生版差异

- **macOS 原生**（`ZapIPTV/`）：SwiftUI、完整设置、TMDB、应用内更新
- **Win / Android**：共用 Web 核心，直播 + 分类 + 简繁 + 深浅色
