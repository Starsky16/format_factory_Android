# 参考源码（仅用于算法移植核对，非构建依赖）

本目录保存从开源项目下载的参考源码，仅供"逐字核对算法"使用，
**不参与任何构建**，也不属于本仓库的运行时组件。

| 文件 | 来源 | 许可证 |
|---|---|---|
| ncmcrypt.cpp | https://github.com/taurusxin/ncmdump（main 分支 src/ncmcrypt.cpp） | MIT（上游仓库 LICENSE） |
| main.cpp | 同上 src/main.cpp | MIT |

本仓库 Android 端的 `com.formatfactory.app.unlock.NcmUnlocker`
是对 `ncmcrypt.cpp` 的 Kotlin 移植，保留算法等价性；
测试样本 `android/app/src/test/resources/ncm_sample.ncm` 来自上游仓库
`test/test.ncm`（用于 JVM 单元测试验证，非运行时资源）。

> 许可证提示：上游为 MIT，移植代码以本仓库 GPL-3.0 对外发布时，
> 已保留 MIT 要求的来源声明于此。若需商用分发，请自行评估各平台加密
> 格式解密的法律与条款约束（仅供个人已购/缓存文件的本地还原）。
