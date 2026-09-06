package com.formatfactory.app

import android.content.Intent
import android.net.Uri
import androidx.activity.result.contract.ActivityResultContracts
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import com.formatfactory.app.unlock.KgmUnlocker
import com.formatfactory.app.unlock.NcmUnlocker
import com.formatfactory.app.unlock.QmcUnlocker

/// 原生存储通道，供 Dart 侧 StorageAccess 调用：
///  - pickOutputDir ：打开系统 SAF 目录选择器并持久化授权
///  - copyToTree    ：把本地文件复制进用户选择的 SAF 目录
/// 用 FlutterFragmentActivity（基于 Fragment/ComponentActivity），
/// 以获得 registerForActivityResult 能力。
class MainActivity : FlutterFragmentActivity(), MethodChannel.MethodCallHandler {

    private var pendingPick: MethodChannel.Result? = null

    private val openTree =
        registerForActivityResult(ActivityResultContracts.OpenDocumentTree()) { uri: Uri? ->
            val result = pendingPick
            pendingPick = null
            if (uri != null) {
                try {
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                    )
                } catch (_: Exception) {
                    // 个别 ROM 可能不区分读写 flag，忽略即可
                }
                result?.success(uri.toString())
            } else {
                result?.success(null) // 用户取消
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 存储通道（选目录 / 复制到 SAF 目录）
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.formatfactory.app/storage",
        ).setMethodCallHandler(this)
        // 音乐脱壳通道（.ncm 等解密）—— 必须单独注册，否则 Dart 会报 MissingPluginException
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.formatfactory.app/unlock",
        ).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickOutputDir" -> {
                pendingPick = result
                openTree.launch(null)
            }
            "copyToTree" -> {
                val treeUri = call.argument<String>("treeUri")
                val fileName = call.argument<String>("fileName")
                val srcPath = call.argument<String>("srcPath")
                if (treeUri == null || fileName == null || srcPath == null) {
                    result.error("bad_args", "缺少参数", null)
                    return
                }
                try {
                    // 显式赋给非空 val，便于编译器安全使用
                    val dir = DocumentFile.fromTreeUri(this, Uri.parse(treeUri))
                        ?: throw IllegalStateException("所选目录已不可访问，请重新选择")
                    var target: DocumentFile? = dir.findFile(fileName)
                    if (target == null) {
                        target = dir.createFile("application/octet-stream", fileName)
                            ?: throw IllegalStateException("无法在所选目录创建文件")
                    }
                    val out = contentResolver.openOutputStream(target.uri)
                        ?: throw IllegalStateException("无法打开输出流")
                    out.use { os ->
                        FileInputStream(File(srcPath)).use { ins -> ins.copyTo(os) }
                    }
                    result.success(target.uri.toString())
                } catch (e: Exception) {
                    result.error("copy_failed", e.message, null)
                }
            }
            // ===== 音乐脱壳（.ncm / .qmc / .kgm 等）=====
            "unlockNcm" -> {
                val src = call.argument<String>("src")
                val destDir = call.argument<String>("destDir")
                if (src == null || destDir == null) {
                    result.error("bad_args", "缺少参数", null)
                    return
                }
                // 解密是大文件 IO，放到后台线程，完成后切回主线程回调
                runAsync(result) {
                    val r = NcmUnlocker.unlock(File(src), File(destDir))
                    mapOf("path" to r.outputPath, "ext" to r.ext)
                }
            }
            "unlockQmc" -> {
                val src = call.argument<String>("src")
                val destDir = call.argument<String>("destDir")
                val format = call.argument<String>("format")
                if (src == null || destDir == null || format == null) {
                    result.error("bad_args", "缺少参数", null)
                    return
                }
                runAsync(result) {
                    val r = QmcUnlocker.unlock(File(src), File(destDir), format)
                    mapOf("path" to r.outputPath, "ext" to r.ext)
                }
            }
            "unlockKgm" -> {
                val src = call.argument<String>("src")
                val destDir = call.argument<String>("destDir")
                val format = call.argument<String>("format")
                if (src == null || destDir == null || format == null) {
                    result.error("bad_args", "缺少参数", null)
                    return
                }
                runAsync(result) {
                    val isVpr = format == "vpr"
                    val r = KgmUnlocker.unlock(File(src), File(destDir), isVpr)
                    mapOf("path" to r.outputPath, "ext" to r.ext)
                }
            }
            else -> result.notImplemented()
        }
    }

    /** 后台线程执行解密，完成后切回主线程返回结果。 */
    private fun runAsync(
        result: MethodChannel.Result,
        job: () -> Map<String, String>,
    ) {
        Thread {
            try {
                val r = job()
                runOnUiThread { result.success(r) }
            } catch (e: Exception) {
                runOnUiThread {
                    result.error(
                        "unlock_failed",
                        e.message ?: "解密失败",
                        null,
                    )
                }
            }
        }.start()
    }
}
