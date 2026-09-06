# 贡献指南

感谢你愿意参与 **格式工厂 · Format Factory (Android)**。

## 分支约定
- `main`：只存放**已验证通过**的代码
- `dev`：所有日常开发都在这里进行
- 合并到 `main` 前必须通过：`flutter analyze`、`flutter test`、`flutter build apk --release --split-per-abi`（涉及原生解密改动另需 `android/gradlew :app:testDebugUnitTest`）

## 开发环境
- Flutter stable（本仓库要求 Dart ≥3.13）
- Android SDK（minSdk 24）
- 常用命令：
  ```bash
  flutter pub get
  flutter analyze
  flutter test
  flutter build apk --release --split-per-abi
  ```

## 想加一种格式？
- **转码格式**：改 `lib/formats_*_data.dart`（复制一条 `FormatPreset`，参数含义都有中文注释）
- **脱壳格式**：Android `com.formatfactory.app.unlock.*`，照 Ncm/Qmc/Kgm 的实现 + JVM 单元测试

## 提交信息风格
建议遵循 `type(scope): 描述`（如 `feat(unlock-QMC): …` / `fix(browser): …`）。

## 说明
本项目绝大多数代码由 AI 生成，作者负责保证其行为与功能测试正常；请同样以"可验证、可测试"为标准提交改动。
