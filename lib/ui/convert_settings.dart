import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../formats.dart';
import '../formats_data.dart';
import '../models.dart';
import '../services/file_store.dart';
import '../state/task_queue.dart';
import 'picked_media.dart';

/// 转换流程第二步：选择"输出格式 + 参数"，点按钮后把所有文件加入任务队列。
/// 返回给上一页的是成功入队的任务数量。
class ConvertSettingsPage extends ConsumerStatefulWidget {
  const ConvertSettingsPage({
    super.key,
    required this.kind,
    required this.files,
  });

  final MediaKind kind;
  final List<PickedMedia> files;

  @override
  ConsumerState<ConvertSettingsPage> createState() =>
      _ConvertSettingsPageState();
}

class _ConvertSettingsPageState extends ConsumerState<ConvertSettingsPage> {
  late FormatPreset _preset;
  late Map<SettingKey, String> _values;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _preset = presetsFor(widget.kind).first;
    _resetDefaults();
  }

  /// 每个参数默认取第一个选项。
  void _resetDefaults() {
    _values = {
      for (final f in _preset.fields) f.key: f.options.first,
    };
  }

  void _selectPreset(FormatPreset p) {
    if (p.id == _preset.id) return;
    setState(() {
      _preset = p;
      _resetDefaults();
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final tasks = <ConvertTask>[];
    final now = DateTime.now();
    for (final f in widget.files) {
      final outPath = await FileStore.uniqueOutputPath(
        widget.kind,
        f.name,
        _preset.extension,
      );
      tasks.add(ConvertTask(
        id: TaskQueue.newId(),
        kind: widget.kind,
        inputPath: f.path,
        inputName: f.name,
        presetId: _preset.id,
        presetName: _preset.name,
        settings: ConvertSettings(Map.of(_values)),
        outputPath: outPath,
        createdAt: now,
        inputDurationSeconds: f.info?.durationSeconds,
      ));
    }
    if (!mounted) return;
    ref.read(taskQueueProvider.notifier).enqueue(tasks);
    Navigator.of(context).pop(tasks.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('选择输出格式')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('输出格式'),
          _presetChips(theme),
          const SizedBox(height: 8),
          Text(
            _preset.description,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (_preset.fields.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('参数'),
            ..._preset.fields.map(_fieldDropdown),
          ],
          const SizedBox(height: 16),
          _sectionTitle('待转换文件（${widget.files.length} 个）'),
          _fileSummary(),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('输出到哪里？'),
              subtitle: const Text(
                '输出文件保存在应用专属目录，转换完成后可在"任务"页把文件分享 / 保存到任何位置。',
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: const Icon(Icons.playlist_add),
            label: Text('开始转换 ${widget.files.length} 个文件'),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _presetChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in presetsFor(widget.kind))
          ChoiceChip(
            label: Text(p.name),
            selected: p.id == _preset.id,
            onSelected: (_) => _selectPreset(p),
          ),
      ],
    );
  }

  Widget _fieldDropdown(OptionField field) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: DropdownButtonFormField<String>(
          initialValue: _values[field.key],
          decoration: InputDecoration(
            labelText: field.label,
            border: InputBorder.none,
          ),
          items: [
            for (final opt in field.options)
              DropdownMenuItem(value: opt, child: Text(opt)),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _values = {..._values, field.key: v});
          },
        ),
      ),
    );
  }

  Widget _fileSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            for (final f in widget.files)
              ListTile(
                dense: true,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(f.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('→ ${_preset.extension.toUpperCase()}'),
              ),
          ],
        ),
      ),
    );
  }
}
