# 格式工厂 · Format Factory（Android）

[![CI](https://github.com/Starsky16/format_factory_Android/actions/workflows/ci.yml/badge.svg)](https://github.com/Starsky16/format_factory_Android/actions/workflows/ci.yml)
[![Build & Release](https://github.com/Starsky16/format_factory_Android/actions/workflows/release-apk.yml/badge.svg)](https://github.com/Starsky16/format_factory_Android/actions/workflows/release-apk.yml)
[![Latest Release](https://img.shields.io/github/v/release/Starsky16/format_factory_Android?label=Download)](https://github.com/Starsky16/format_factory_Android/releases/latest)
[![License](https://img.shields.io/github/license/Starsky16/format_factory_Android)](LICENSE)

> 安装包请到 **GitHub Releases** 下载：https://github.com/Starsky16/format_factory_Android/releases/latest

一个类似电脑端"格式工厂"的**手机版媒体格式转换工具**，支持**视频 / 音频 / 图片**三类互转、**批量**转换与后台任务队列。

- 技术栈：Flutter 3.x + Material 3（Material You 风格）+ FFmpeg（`ffmpeg_kit_flutter_new`，FFmpeg v8）
- 最低系统：Android 7.0（API 24）——由 FFmpeg 底层库要求决定，不能再低
- 目标系统：API 36（Android 16，最新）
- 许可证：**GPL-3.0**（原因见文末）

## v0.2 新增能力

- **参数可精确调整**：视频质量改 CRF 数值（0~51）、可设视频码率/帧率，每一项参数下都有中文说明
- **自定义格式**：视频/音频/图片各提供"自定义"，编码器、封装、码率、采样率等全参数自由组合
- **设置页**：
  - 视频/音频/图片**输出位置分别设置**：应用专属目录，或自选 SAF 目录（系统目录选择器）
  - **读取文件方式**切换：系统文件选择器（SAF，无需权限）/ 文件管理权限 + 内置文件浏览器
- **通知与后台转码**：转码时通知栏实时显示"转换中 45%（1/3）"并保持后台运行，可一键关闭
- **转码历史**：本地 SQLite 持久化，可查看 / 再次转换 / 分享 / 删除

## 功能一览

| 类别 | 输出格式 | 可调参数 |
|---|---|---|
| 视频 | MP4(H.264/H.265)、MKV、AVI、MOV、WebM、FLV、3GP、GIF | 画面尺寸、视频质量 |
| 音频 | MP3、AAC(M4A)、FLAC、WAV、OGG、Opus | 码率、采样率、声道 |
| 图片 | JPG、PNG、WebP、BMP、TIFF、GIF | 尺寸、图片质量 |

其它：FFprobe 读取媒体信息、批量串行队列、实时进度、单任务/全队取消、失败重试与错误详情、完成后一键分享文件。

## 项目结构（重点，都很短）

```
lib/
├── models.dart             领域模型（任务/设置/媒体信息）
├── formats.dart            格式预设的结构 + 参数翻译助手
├── formats_data.dart       汇总入口（按类别取格式清单）
├── formats_video_data.dart 视频格式清单（想加视频格式改这里）
├── formats_audio_data.dart 音频格式清单
├── formats_image_data.dart 图片格式清单
├── services/               FFmpeg 引擎、FFprobe、输出目录
├── state/task_queue.dart   全局任务队列（Riverpod 串行调度）
└── ui/                     首页 / 选择文件 / 设置 / 任务列表
```

## 三步上手

### 1. 构建 APK

```bash
flutter pub get
flutter build apk --release --split-per-abi
```

产物在 `build/app/outputs/flutter-apk/`：
- `app-arm64-v8a-release.apk` —— 2017 年后的主流手机，**装这个即可**
- `app-armeabi-v7a-release.apk` —— 老款 32 位手机
- `app-x86_64-release.apk` —— 模拟器 / 平板

安装到手机：

```bash
adb install app-arm64-v8a-release.apk
```

> 注意：当前 release 包用调试签名，仅供自用测试；正式发布请自行生成 keystore 签名。

### 2. 想加/改一种输出格式？

打开 `lib/formats_video_data.dart`（或 audio / image），照着现有条目复制一条 `FormatPreset`，改三处即可：

- `name / extension`：显示名与扩展名
- `fields`：转换页要展示的参数下拉框
- `buildArgs`：把用户选择翻译成 FFmpeg 参数（看不懂某个参数？它旁边都有中文注释）

### 3. 想换主题色？

打开 `lib/theme.dart`，改 `seedColor` 一个值，整套 Material 3 配色自动生成。

## 分支与协作约定

- 默认分支 `main`：只存放**已验证通过**的代码
- 开发分支 `dev`：所有日常开发都在这提交
- 合并到 `main` 前必须通过：`flutter analyze`、`flutter test`、`flutter build apk --release --split-per-abi`

## 常见问题

**Q：为什么 Android 7.0 起？**
转码库 ffmpeg-kit 的预编译库要求 API ≥ 24；Android 5.0/6.0 设备占比已不足 1%，且跑视频转码体验差。

**Q：转换后的文件在哪？**
应用专属目录（无需任何存储权限，任何系统版本都能写）：
`Android/data/com.formatfactory.app/files/FormatFactory/<类别>/`
任务完成后点"分享"图标即可把文件发给其它 App 或保存到任意位置。

**Q：为什么是 GPL-3.0？**
本应用内置 FFmpeg 的 **full-gpl** 完整版（含 x264/x265 等 GPL 授权编解码器），GPL 要求衍生作品也以 GPL 开源，因此本项目选择 GPL-3.0 开源到 GitHub 是完全合规且功能最全的方案。

## 致谢

- [FFmpeg](https://ffmpeg.org/)
- [ffmpeg_kit_flutter_new](https://pub.dev/packages/ffmpeg_kit_flutter_new)（FFmpegKit 活跃维护 fork）
- [Flutter](https://flutter.dev/)

## 注意
本项目全数由ai生成，作者的唯一任务是保证其的行为及功能测试正常，本readme仅有这句话为人类所写
