# 格式工厂 · Format Factory（Android）

[![CI](https://github.com/Starsky16/format_factory_Android/actions/workflows/ci.yml/badge.svg)](https://github.com/Starsky16/format_factory_Android/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/Starsky16/format_factory_Android?label=Download)](https://github.com/Starsky16/format_factory_Android/releases/latest)
[![License](https://img.shields.io/github/license/Starsky16/format_factory_Android)](LICENSE)

一款 Android 上的"格式工厂"：把视频、音频、图片转换成你想要的格式；还能把网易云/QQ音乐/酷狗下载的**加密音乐还原成普通格式**。全部处理都在手机本地完成，不联网、不上传。

## 📲 下载与安装

安装包发布在 **GitHub Releases**：
👉 https://github.com/Starsky16/format_factory_Android/releases/latest

| 安装包 | 适用设备 |
|---|---|
| `app-arm64-v8a-release.apk` | 2017 年后的主流手机（**推荐**） |
| `app-armeabi-v7a-release.apk` | 老款 32 位手机 |
| `app-x86_64-release.apk` | Android 模拟器 / x86 平板 |

- 系统要求：**Android 7.0（API 24）及以上**（FFmpeg 底层库要求，无法更低）
- 下载后直接点开 APK 安装；若提示"未知来源"，请在系统弹窗中允许本次安装

## ✨ 它能做什么

### 媒体格式转换
| 类别 | 输出格式 | 可调参数 |
|---|---|---|
| 视频 | MP4(H.264/H.265)、MKV、AVI、MOV、WebM、FLV、3GP、GIF | 分辨率、CRF 质量、视频/音频码率、帧率 |
| 音频 | MP3、AAC(M4A)、FLAC、WAV、OGG、Opus | 码率、采样率、声道 |
| 图片 | JPG、PNG、WebP、BMP、TIFF、GIF | 尺寸、质量 |

每类还有"**自定义**"选项，编码器/封装/码率等全部参数自由组合，每个参数下都有一行中文说明。

### 音乐脱壳（加密音乐还原）
| 来源 | 扩展名 | 还原为 |
|---|---|---|
| 网易云 | `.ncm` | 原始 flac / mp3 |
| QQ 音乐 | `.qmc0/.qmc2/.qmc3/.qmcflac/.qmcogg`、`.mflac/.mflac0/.mflach/.mgg/.mgg0/.mgg1/.mggl` | 原始 flac / ogg / mp3 |
| 酷狗 | `.kgm/.kgma/.vpr` | 原始 flac / mp3 / wav / ogg |

> 说明：QQ 音乐的 `.mflac/.mgg` 等需要文件**内嵌密钥**（新下载的多数带有 QTag/V1 尾部）才能离线解密；个别文件未带密钥会明确提示，无法离线处理。

### 其它贴心设计
- **批量**：一次选多个文件，队列逐个处理，实时进度、可取消/重试/查看原因
- **后台不中断**：切后台、锁屏也继续转，通知栏显示"转换中 45%（1/3）"，可一键关闭通知
- **转码历史**：本地保存每次任务，可再次转换、分享、删除
- **输出位置可设**：视频/音频/图片可分别存到"应用专属目录"或你自选的目录
- **读取文件方式可选**：系统文件选择器（免权限）或"文件管理权限" + 内置文件浏览器（支持搜索、书签、直达主存储、全选）

## 🚀 快速上手

1. 打开首页点"**视频/音频/图片转换**"→ 选文件（可多选）→ 选目标格式和参数 → 开始转换；进度在底部"任务"页实时显示。
2. 首页"**音乐脱壳**"→ 选加密音乐 → 加入任务队列，解出的原始音频自动保存。
3. "**设置**"页可调整三类输出位置、读取文件方式、后台通知开关。

## ❓ 常见问题

**Q：转换/脱壳后的文件在哪里？**
默认在应用专属目录 `Android/data/com.formatfactory.app/files/FormatFactory/<类别>/`（无需任何权限）。任务完成后点"分享"可存到相册/发给其它应用；或在设置里把输出位置改成你选的目录。

**Q：为什么从 Android 7.0 才开始支持？**
FFmpeg 转码库要求 API ≥ 24，且 5.0/6.0 设备占比不足 1%，跑视频转码体验也很差。

**Q：为什么有些加密音乐提示解不了？**
`.ncm`/`.kgm/.kgma/.vpr` 均可离线解；QQ 音乐 `.mflac/.mgg` 需要文件自带密钥（多数新版带 QTag/V1）。没有密钥的文件只能交给对应客户端处理，App 无法凭空解密。

**Q：后台转码会一直常驻吗？**
只在有任务时启动前台服务，队列完成后自动结束；可在设置里关闭"转码通知"。

## ⚖️ 合规与许可证

- 本应用内置 FFmpeg **full-gpl**（含 x264/x265），故本项目以 **GPL-3.0** 开源，代码见本仓库。
- 音乐脱壳仅建议用于**你本人拥有合法使用权的本地缓存文件**，请遵守平台服务条款与你所在地区的法律；本项目不提供任何绕过付费/版权保护的逻辑。

---
## 🛠 开发者 / 贡献者专区

> 以下内容面向想参与开发的人，普通用户无需阅读。

**技术栈**：Flutter 3.x · Material 3 · Riverpod · FFmpeg（`ffmpeg_kit_flutter_new`）· SQLite
**要求**：minSdk 24 / targetSdk 36

**项目结构（都很短）**
```
lib/
├── models.dart             领域模型（任务/设置/媒体信息）
├── formats.dart            格式预设结构与参数翻译助手
├── formats_data.dart       汇总入口
├── formats_video_data.dart 视频格式清单（想加视频格式改这里）
├── formats_audio_data.dart 音频格式清单
├── formats_image_data.dart 图片格式清单
├── services/               FFmpeg 引擎、FFprobe、输出目录、解锁通道、前台通知
├── state/                  Riverpod：任务队列 / 设置 / 历史
└── ui/                     首页 / 转换 / 音乐脱壳 / 任务 / 历史 / 设置 / 文件浏览器

android/app/src/main/kotlin/.../unlock/   脱壳算法（Ncm/Qmc/Kgm，纯 Kotlin）
android/app/src/test/.../unlock/          JVM 单元测试（含真实 .ncm 样本与往返样本）
```

**从源码构建与发布**
```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release --split-per-abi
# 涉及脱壳算法改动另跑：
cd android && ./gradlew :app:testDebugUnitTest
# 打 tag 后 CI 会自动出 Release：git tag -a vX.Y.Z -m "..." && git push origin vX.Y.Z
```

**想加一种转码格式？**
打开 `lib/formats_video_data.dart`（或 audio/image），复制一条 `FormatPreset` 改三处：
`name/extension`（显示名与扩展名）、`fields`（设置页参数下拉框）、`buildArgs`（FFmpeg 参数，均有中文注释）。

**想换主题色？**
改 `lib/theme.dart` 里的 `seedColor` 一个值，整套 Material 3 配色自动生成。

**分支与协作约定**
- `main`：只存放已验证通过的代码
- `dev`：日常开发分支
- 合并到 `main` 前必须通过：`flutter analyze`、`flutter test`、release 构建（涉及原生另跑 Kotlin 单测）
- 详见 [CONTRIBUTING.md](CONTRIBUTING.md) 与 [SECURITY.md](SECURITY.md)

**致谢**
[FFmpeg](https://ffmpeg.org/) · [ffmpeg_kit_flutter_new](https://pub.dev/packages/ffmpeg_kit_flutter_new) · [Flutter](https://flutter.dev/) · 脱壳算法参考 [ncmdump](https://github.com/taurusxin/ncmdump) / [ncm2mp3-js](https://github.com/LingBrian/ncm2mp3-js) / [kugou-audio-unlock](https://github.com/onavcn/kugou-audio-unlock)（MIT）

## 注意
本项目全数由ai生成，作者的唯一任务是保证其的行为及功能测试正常，本readme仅有这句话为人类所写

