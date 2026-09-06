import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models.dart';
import '../services/file_store.dart';
import '../services/storage_access.dart';
import '../state/app_settings.dart';

/// 设置页：输出位置（视频/音频/图片各自设置）+ 读取文件方式。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  /// "文件管理权限"模式当前的授权状态。
  PermissionStatus? _manageStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshPermission();
    });
  }

  static bool get _isAndroid11Plus {
    if (!Platform.isAndroid) return false;
    final v = int.tryParse(Platform.version.split('.').first) ?? 0;
    return v >= 30; // Android 11 = API 30
  }

  static Future<PermissionStatus> _permStatus() async {
    if (_isAndroid11Plus) return Permission.manageExternalStorage.status;
    return Permission.storage.status; // Android 10 及以下
  }

  Future<void> _refreshPermission() async {
    if (!Platform.isAndroid) return; // 仅 Android 才有文件权限概念
    final s = await _permStatus();
    if (mounted) setState(() => _manageStatus = s);
  }

  /// 请求"所有文件访问"权限。
  Future<void> _grantManage() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_isAndroid11Plus) {
      await Permission.manageExternalStorage.request();
    } else {
      await Permission.storage.request();
    }
    await _refreshPermission();
    final ok = await _permStatus().then((s) => s.isGranted);
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? '已获得所有文件访问权限' : '未授权。你可以在系统设置中开启后再试'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('输出位置（三类分别设置）'),
        for (final kind in MediaKind.values) _outputTile(kind),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '输出到"应用专属目录"无需任何权限；'
              '选择"自定义目录"后，转换完成会自动把文件保存到该目录。',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sectionTitle('读取文件方式'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'saf',
                      label: Text('系统文件选择器'),
                      icon: Icon(Icons.folder_open),
                    ),
                    ButtonSegment(
                      value: 'manage',
                      label: Text('文件管理权限'),
                      icon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                  ],
                  selected: {settings.pickerMode},
                  onSelectionChanged: (sel) {
                    ref.read(appSettingsProvider.notifier).setPickerMode(
                          sel.first,
                        );
                    _refreshPermission();
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  settings.pickerMode == 'saf'
                      ? '推荐：用系统文件选择器选文件，无需任何权限，隐私最好。'
                      : 'Android 11+ 需开启"所有文件访问"，可浏览整台设备的文件。',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        if (settings.pickerMode == 'manage') ...[
          const SizedBox(height: 8),
          _permissionCard(),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _outputTile(MediaKind kind) {
    final settings = ref.watch(appSettingsProvider);
    final target = settings.targetOf(kind);
    final isApp = target == AppSettings.targetApp;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            switch (kind) {
              MediaKind.video => Icons.videocam_outlined,
              MediaKind.audio => Icons.music_note,
              MediaKind.image => Icons.image_outlined,
            },
            size: 20,
          ),
        ),
        title: Text('${kind.label}输出位置'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isApp ? '应用专属目录' : '自定义目录'),
            if (isApp)
              FutureBuilder<String>(
                future: FileStore.appOutputDirText(),
                builder: (_, snap) => Text(
                  '${snap.data ?? ''}/${kind.dirName}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              Text(
                target,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: TextButton(
          onPressed: () => _chooseOutput(kind),
          child: const Text('更改'),
        ),
      ),
    );
  }

  /// 底部弹层选择输出位置：应用目录 / 自定义目录。
  Future<void> _chooseOutput(MediaKind kind) async {
    final notifier = ref.read(appSettingsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final current = ref.read(appSettingsProvider).targetOf(kind);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('${kind.label}输出位置'),
              subtitle: const Text('选择转换完成的文件保存到哪里'),
            ),
            ListTile(
              leading: const Icon(Icons.smartphone),
              title: const Text('应用专属目录'),
              subtitle: const Text('无需权限，卸载应用时会被删除'),
              trailing: current == AppSettings.targetApp
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.of(ctx).pop('app'),
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('选择自定义目录…'),
              subtitle: const Text('用系统目录选择器挑选保存位置'),
              onTap: () => Navigator.of(ctx).pop('pick'),
            ),
            if (current != AppSettings.targetApp)
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('改回应用专属目录'),
                onTap: () => Navigator.of(ctx).pop('app'),
              ),
          ],
        ),
      ),
    );

    if (action == null) return;
    if (action == 'app') {
      await notifier.setOutput(kind, AppSettings.targetApp);
      return;
    }
    // 打开系统目录选择器（原生 SAF）
    final uri = await StorageAccess.pickDirectory();
    if (uri == null) return; // 用户取消
    await notifier.setOutput(kind, uri);
    messenger.showSnackBar(const SnackBar(content: Text('已设置输出目录')));
  }

  Widget _permissionCard() {
    final theme = Theme.of(context);
    final granted = _manageStatus?.isGranted ?? false;
    final text = granted
        ? '已开启：可以浏览整台设备的文件。'
        : (_isAndroid11Plus
            ? 'Android 11+ 需要到系统设置里开启"所有文件访问"，才能用文件管理权限读取文件。'
            : '需要授予存储权限后才能浏览文件。');
    return Card(
      child: ListTile(
        leading: Icon(
          granted ? Icons.verified_user_outlined : Icons.lock_outline,
          color: granted ? const Color(0xFF2E7D32) : theme.colorScheme.error,
        ),
        title: Text(granted ? '文件管理权限已开启' : '文件管理权限未开启'),
        subtitle: Text(text),
        trailing: granted
            ? null
            : FilledButton.tonal(
                onPressed: _grantManage,
                child: const Text('去授权'),
              ),
      ),
    );
  }
}
