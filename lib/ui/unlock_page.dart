import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../services/file_store.dart';
import '../services/manage_permission.dart';
import '../services/storage_access.dart';
import '../services/unlock_api.dart';
import '../state/app_settings.dart';
import 'file_browser_page.dart';
import 'picked_media.dart';

/// "音乐脱壳"：把 .ncm（后续含 .qmc/.kgm）解成原始 flac/mp3，直接保存，不做转码。
class UnlockPage extends ConsumerStatefulWidget {
  const UnlockPage({super.key});

  @override
  ConsumerState<UnlockPage> createState() => _UnlockPageState();
}

enum _UnlockStatus { idle, working, done, failed }

class _Entry {
  _Entry({required this.path, required this.name, required this.size})
      : status = _UnlockStatus.idle;
  final String path;
  final String name;
  final int size;
  _UnlockStatus status;
  String? output;
  String? error;
}

class _UnlockPageState extends ConsumerState<UnlockPage> {
  final List<_Entry> _entries = [];
  bool _busy = false;

  Future<void> _pick() async {
    // 与转换流程一致：按设置里的"读取文件方式"选择
    final mode = ref.read(appSettingsProvider).pickerMode;
    if (mode == 'manage' && Platform.isAndroid) {
      await _pickWithBrowser();
      return;
    }
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['ncm'],
      );
      if (files.isEmpty) return;
      _addPaths([for (final f in files) if (f.path != null) f.path!]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败：$e')),
        );
      }
    }
  }

  /// 文件管理权限模式：用自建文件浏览器选取。
  Future<void> _pickWithBrowser() async {
    final messenger = ScaffoldMessenger.of(context);
    final granted = await ManagePermission.ensureGranted();
    if (!granted) {
      messenger.showSnackBar(const SnackBar(
        content: Text('需要"文件管理权限"才能浏览文件。请在系统弹窗中开启后重试。'),
      ));
      return;
    }
    if (!mounted) return;
    final picked = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => const FileBrowserPage(extensions: ['ncm']),
      ),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    _addPaths(picked);
  }

  void _addPaths(List<String> paths) {
    final fresh = <_Entry>[];
    for (final p in paths) {
      if (_entries.any((e) => e.path == p)) continue;
      final f = File(p);
      fresh.add(_Entry(
        path: p,
        name: p.split(Platform.pathSeparator).last,
        size: _safeSize(f),
      ));
    }
    if (fresh.isEmpty) return;
    setState(() => _entries.addAll(fresh));
  }

  static int _safeSize(File f) {
    try {
      return f.lengthSync();
    } catch (_) {
      return 0;
    }
  }

  Future<void> _unlockAll() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    var ok = 0;
    var fail = 0;

    final target = ref.read(appSettingsProvider).targetOf(MediaKind.audio);
    // 输出目录：app 专属直接写；自定义 SAF 目录则先写内部工作区，成功后再复制
    final destDir = await FileStore.outputDir(MediaKind.audio, target);

    for (final e in _entries) {
      if (e.status == _UnlockStatus.done || e.status == _UnlockStatus.working) {
        continue;
      }
      setState(() {
        e.status = _UnlockStatus.working;
        e.error = null;
      });
      try {
        final r = await UnlockApi.unlockNcm(src: e.path, destDir: destDir.path);
        e.output = r.path;
        e.status = _UnlockStatus.done;
        ok++;

        // 若设置了"自定义 SAF 目录"，把结果复制过去
        if (target != AppSettings.targetApp) {
          final name = r.path.split(Platform.pathSeparator).last;
          final uri = await StorageAccess.copyToTree(
            treeUri: target,
            fileName: name,
            srcPath: r.path,
          );
          if (uri == null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('已脱壳，但写入自定义目录失败（目录可能已失效）'),
            ));
          }
        }
      } catch (err) {
        e.status = _UnlockStatus.failed;
        e.error = err.toString().replaceFirst('Exception: ', '');
        fail++;
      }
      if (mounted) setState(() {});
    }

    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(content: Text(ok > 0 ? '脱壳完成：成功 $ok 个' : '全部失败($fail 个)，请查看列表原因')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('音乐脱壳')),
      body: _entries.isEmpty ? _emptyHint() : _entryList(scheme),
      bottomNavigationBar: _entries.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pick,
                      icon: const Icon(Icons.add),
                      label: const Text('继续添加'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _unlockAll,
                        icon: const Icon(Icons.lock_open),
                        label: Text(_busy ? '脱壳中…' : '开始脱壳 (${_entries.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _emptyHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_open_outlined,
                size: 72, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text('选择加密音乐文件'),
            const SizedBox(height: 8),
            Text(
              '支持网易云 .ncm → 解出原始 flac/mp3\n（.qmc/.kgm 支持开发中）',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.folder_open),
              label: const Text('选择文件'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryList(ColorScheme scheme) {
    return ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (context, i) {
        final e = _entries[i];
        final (icon, color, line) = switch (e.status) {
          _UnlockStatus.idle => (
              Icons.schedule,
              scheme.outline,
              formatBytes(e.size),
            ),
          _UnlockStatus.working => (
              Icons.autorenew,
              scheme.primary,
              '正在脱壳…',
            ),
          _UnlockStatus.done => (
              Icons.check_circle_outline,
              const Color(0xFF2E7D32),
              '完成：${e.output?.split(Platform.pathSeparator).last}',
            ),
          _UnlockStatus.failed => (
              Icons.error_outline,
              scheme.error,
              '失败：${e.error ?? '未知错误'}',
            ),
        };
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(line, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: _UnlockStatus.working == e.status
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _busy
                      ? null
                      : () => setState(() => _entries.removeAt(i)),
                ),
        );
      },
    );
  }
}

