# PlayerX

PlayerX 是一个以 SwiftUI 构建的 Apple 多平台媒体浏览器与播放器。它把多个公开站源
归一成 **电影 / 剧集 / 动漫 / 短剧 / 综艺 / 纪录片** 六类内容库，并在详情页叠加
TMDB 元数据、Bangumi 追番、弹弹play 弹幕与 MoviePilot 找片/下载/订阅。

## 平台与目标

| Target | 平台 | 播放内核 |
| --- | --- | --- |
| `PlayerX` | iPhone / iPad (iOS 17+) | Pillarbox（默认）、Erika、原生 AVPlayer |
| `PlayerX-macOS` | macOS 14+ | Erika、原生 AVPlayer |
| `PlayerX-tvOS` | Apple TV (tvOS 17+) | Pillarbox 系统播放器 + 直链播放 |

## 功能

- **首页 / 片库**：Hero、继续观看、站源推荐、类型分类、筛选（站源、题材、年份、排序）。
- **详情页**：背景氛围图、海报、年份、类型、TMDB 评分、简介、季/集、演员表、
  媒体信息、外部链接、相关推荐、手动 TMDB 匹配。
- **播放器**：Pillarbox 默认；Erika（FFmpeg + libass，iOS/macOS）；原生 AVPlayer。
  竖屏 Stories 进度条、左右切换上一集/下一集、横屏章节导航、倍速、音轨/字幕、
  自动连播、锁定、弹幕覆盖层。
- **弹弹play**：内置公共网关 Key，按标题与集数匹配，支持字号/透明度/速度/轨道。
- **Bangumi**：每日放送、搜索、条目详情、想看/在看/看过、章节进度。
- **MoviePilot**：媒体搜索、SSE 站点资源搜索、添加下载、订阅、下载进度轮询。
- **TMDB**：内置只读 Token；自动匹配 + 手动匹配；中文/英文回退。
- **tvOS**：侧边栏 Shell、焦点卡片、首页/分类/搜索/详情、Bangumi、MoviePilot、
  原生系统播放器与直链输入。

## 构建

工程由 XcodeGen 从 `project.yml` 生成；`.xcodeproj` 不提交。

```bash
# Erika 预编译内核（仅 iOS / macOS target 需要）
bash Packages/ErikaKit/Scripts/fetch-erika.sh v0.2.1

# Go 原生站源核心（iOS / macOS）
bash scripts/build-core-xcframework.sh --all-sources

xcodegen generate --spec project.yml

xcodebuild archive -project PlayerX.xcodeproj -scheme PlayerX \
  -destination 'generic/platform=iOS' -archivePath build/PlayerX.xcarchive \
  CODE_SIGNING_ALLOWED=NO

xcodebuild archive -project PlayerX.xcodeproj -scheme PlayerX-macOS \
  -destination 'generic/platform=macOS' -archivePath build/PlayerX-macOS.xcarchive \
  CODE_SIGNING_ALLOWED=NO

xcodebuild archive -project PlayerX.xcodeproj -scheme PlayerX-tvOS \
  -destination 'generic/platform=tvOS' -archivePath build/PlayerX-tvOS.xcarchive \
  CODE_SIGNING_ALLOWED=NO
```

CI 会依次执行 Erika 拉取、Go 核心构建、XcodeGen 和三个平台的 unsigned archive。
构建失败时会把紧凑错误日志推送到 `ci-logs-ios` / `ci-logs-macos` / `ci-logs-tvos`
分支，便于在无 Actions 日志权限的环境里排障。

## 目录

```
PlayerX/
  PXCore/      模型、TMDB/Bangumi/MoviePilot/弹弹play 客户端、播放器适配
  PXDesign/    主题、玻璃组件、卡片、远程图管道
  PXFeatures/  首页、片库、详情、播放器、搜索、设置、追番、找片
PlayerXTV/     tvOS Shell 与页面
Packages/      ErikaKit / PlaybackKit / DiagnosticsKit（本地 SwiftPM 包）
```
