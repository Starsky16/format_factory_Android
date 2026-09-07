import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../state/history_notifier.dart';
import '../state/task_queue.dart';
import 'convert_flow.dart';
import 'history_page.dart';
import 'settings_page.dart';
import 'task_list_page.dart';
import 'unlock_page.dart';

/// 应用外壳：底部两个标签页 —— 转换(首页) / 任务。
/// 首页的入口会 push 出 ConvertFlow，转换入队后自动切到"任务"标签。
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  Future<void> _openConvert(MediaKind kind) async {
    final added = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => ConvertFlow(kind: kind)),
    );
    if (added == null || added <= 0 || !mounted) return;
    setState(() => _index = 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已把 $added 个任务加入队列，正在后台转换')),
    );
  }

  /// 音乐脱壳：加入任务队列后自动切到"任务"页查看进度。
  Future<void> _openUnlock() async {
    final added = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const UnlockPage()),
    );
    if (added == null || added <= 0 || !mounted) return;
    setState(() => _index = 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已把 $added 个脱壳任务加入队列')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref
        .watch(taskQueueProvider)
        .where((t) => !t.status.isFinished)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_index) {
          0 => '格式工厂',
          1 => '转换任务',
          2 => '转码历史',
          _ => '设置',
        }),
        actions: _index == 1
            ? [
                TextButton.icon(
                  onPressed: () =>
                      ref.read(taskQueueProvider.notifier).clearFinished(),
                  icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                  label: const Text('清空已完成'),
                ),
              ]
            : _index == 2
                ? [
                    TextButton.icon(
                      onPressed: () => ref
                          .read(historyProvider.notifier)
                          .clearAll(),
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                      label: const Text('清空历史'),
                    ),
                  ]
                : null,
      ),
      body: IndexedStack(
        index: _index,
        children: [
          _HomeView(onConvert: _openConvert, onOpenUnlock: _openUnlock),
          const TasksPage(),
          const HistoryPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '转换',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.task_alt_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.task_alt),
            ),
            label: '任务',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '历史',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

/// 首页：三个媒体类别入口 + 简短说明。
class _HomeView extends StatelessWidget {
  const _HomeView({required this.onConvert, required this.onOpenUnlock});

  final void Function(MediaKind kind) onConvert;
  final VoidCallback onOpenUnlock;

  static const _colors = <Color>[
    Color(0xFF3F51B5), // 视频 靛蓝
    Color(0xFFE65100), // 音频 橙
    Color(0xFF2E7D32), // 图片 绿
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('把媒体转换成你想要的格式',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  '视频 · 音频 · 图片 三类互转，支持批量与后台队列',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final kind in MediaKind.values)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor:
                    _colors[kind.index].withValues(alpha: 0.14),
                child: Icon(
                  switch (kind) {
                    MediaKind.video => Icons.videocam_outlined,
                    MediaKind.audio => Icons.music_note,
                    MediaKind.image => Icons.image_outlined,
                  },
                  color: _colors[kind.index],
                ),
              ),
              title: Text('${kind.label}转换',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(switch (kind) {
                MediaKind.video => 'MP4 / MKV / AVI / WebM / GIF 等',
                MediaKind.audio => 'MP3 / FLAC / WAV / AAC / OGG 等',
                MediaKind.image => 'JPG / PNG / WebP / BMP / TIFF 等',
              }),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onConvert(kind),
            ),
          ),
        Text(
          '提示：批量任务会逐个串行转换，可随时取消。转码为 GPL 开源项目 FFmpeg 驱动。',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0x33B8860B),
              child: Icon(Icons.lock_open_outlined, color: Color(0xFF8D6E00)),
            ),
            title: const Text('音乐脱壳',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('网易云 .ncm、QQ .qmc/.mflac/.mgg、酷狗 .kgm/.kgma/.vpr 加密音乐还原为原始格式（不转码）'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenUnlock,
          ),
        ),
      ],
    );
  }
}
