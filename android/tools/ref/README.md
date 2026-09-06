# 参考源码（仅用于算法移植核对，非构建依赖）

本目录保存从开源项目下载的参考源码，仅供"逐字核对算法"使用，
**不参与任何构建**，也不属于本仓库的运行时组件。

| 文件 | 来源 | 许可证 |
|---|---|---|
| ncmcrypt.cpp | https://github.com/taurusxin/ncmdump（main 分支 src/ncmcrypt.cpp） | MIT（上游仓库 LICENSE） |
| main.cpp | 同上 src/main.cpp | MIT |
| qmc-js/（本地克隆） | https://github.com/LingBrian/ncm2mp3-js（lib/qmc/index.html 含 QMC1/QMC2 解密） | MIT（见克隆目录 LICENSE，不入库） |
| kgm-py/（本地克隆） | https://github.com/onavcn/kugou-audio-unlock（decrypt_kgm.py 含 KGM V2 XOR 与表） | MIT（见克隆目录 LICENSE，不入库） |

本仓库 Android 端的 `com.formatfactory.app.unlock.*` 各解密器：
- NcmUnlocker ← ncmcrypt.cpp 移植
- QmcUnlocker ← qmc-js QMC 解密移植
- KgmUnlocker / KgmTables ← decrypt_kgm.py KGM V2 XOR 移植（掩码表由脚本精确抽取）

测试样本：
- `android/app/src/test/resources/ncm_sample.ncm` 来自 ncmdump `test/test.ncm`；
- QMC1 / KGM 采用"合成样本往返"验证（真实厂商样本不在公开仓库内）。

> 许可证提示：上游为 MIT，移植代码以本仓库 GPL-3.0 对外发布时，
> 已保留 MIT 要求的来源声明于此。若需商用分发，请自行评估各平台加密
> 格式解密的法律与条款约束（仅供个人已购/缓存文件的本地还原）。
