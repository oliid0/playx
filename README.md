# PlayerX

PlayerX 是一个以 SwiftUI 构建的 Apple 多平台媒体浏览器与播放器。它把多个公开站源
归一成 **电影 / 剧集 / 动漫 / 短剧 / 综艺 / 纪录片** 六类内容库，并在详情页叠加
TMDB 元数据、Bangumi 追番、弹弹play 弹幕与 MoviePilot 找片/下载/订阅。

## 平台与目标

| Target | 平台 | 播放内核 |
| --- | --- | --- |
| `PlayerX` | iPhone / iPad (iOS 17+) | Pillarbox（默认）、Erika、原生 AVPlayer |
| `PlayerX-macOS` | macOS 14+ | Erika、原生 AVPlayer |
| `PlayerX-tvOS` | Apple TV (tvOS 17+) | Pillarbox + 外部媒体源 / 直链播放 |

## 界面结构（对齐 OcPlayer）

- iPhone / iPad 底部 Tab：**首页 / Bangumi / MoviePilot / 设置 / 搜索**。
- macOS 顶部胶囊：**首页 / MoviePilot / Bangumi / 设置**，不再使用侧栏。
- 首页栏目固定为：**继续观看 / 接下来看 / 最近添加 / 媒体库**。
  每个站源或外部媒体源就是一张媒体库卡片，进入后再按该库的分类浏览。
- 详情页是 OcPlayer 式的长页：背景氛围、海报、评分、简介、剧集、演员、媒体信息、
  相关推荐，不再拆成额外 Tab 入口。
- macOS 点击播放使用**同一窗口根覆盖层**，不再用 sheet 新开播放窗口。

## 功能

- **首页 / 媒体库**：继续观看、接下来看、最近添加、媒体库卡片、库内分类、筛选。
- **详情页**：背景氛围图、海报、年份、类型、TMDB 评分、简介、季/集、演员表、
  媒体信息、外部链接、相关推荐、手动 TMDB 匹配。
- **统一媒体源平台**：
  - 内置 Go 站源；
  - Emby / Jellyfin（登录、媒体库、Items、Episodes、HLS 转码）；
  - WebDAV / NAS / Alist·OpenList（PROPFIND 目录、视频识别、Basic Auth）；
  - MacCMS（`provide/vod` JSON API、播放组解析）；
  - 配置保存在本机，设置 → 媒体源中增删改和测试。
  - 所有源统一实现 `ContentProvider`；站源配置、外部源配置、首页、搜索、详情、
    播放器只依赖这一层，后续新协议只需新增 `PXSourceKind` 与 provider。
- **播放器**：Pillarbox 默认；Erika（FFmpeg + libass，iOS/macOS）；原生 AVPlayer。
  竖屏 Stories 进度条、左右切换上一集/下一集、横屏章节导航、倍速、音轨/字幕、
  自动连播、锁定、弹幕覆盖层。
- **弹弹play**：内置公共网关 Key，按标题与集数匹配，支持字号/透明度/速度/轨道。
- **Bangumi**：每日放送、搜索、条目详情、想看/在看/看过、章节进度。
- **MoviePilot**：媒体搜索、SSE 站点资源搜索、添加下载、订阅、下载进度轮询。
- **TMDB**：内置只读 Token；自动匹配 + 手动匹配；中文/英文回退。
- **tvOS**：OcPlayer 同级五入口侧边栏、焦点卡片、首页/详情/Bangumi/MoviePilot/
  设置/搜索；媒体库栏直接读取外部媒体源，详情与播放共用同一套 provider。

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
