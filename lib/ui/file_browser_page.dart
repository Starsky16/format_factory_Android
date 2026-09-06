import 'dart:io';

import 'package:flutter/material.dart';

import 'picked_media.dart';

/// "文件管理权限"读取方式下的自建文件浏览器。
/// 允许在目录间跳转、多选支持格式的文件，确定后把选中文件的路径 pop 回上一页。
class FileBrowserPage extends StatefulWidget {
  const FileBrowserPage({super.key, required this.extensions});

  /// 允许选择的扩展名（小写，不带点）。
  final List<String> extensions;

  @override
  State<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends State<FileBrowserPage> {
  /// 打开时直接进入主存储（照片/下载/Music 通常都在这里）
  Directory _current = Directory('/storage/emulated/0');
  final List<String> _stack = [];
  final Set<String> _selected = {};

  bool get _atStorageRoot => _current.path == '/storage';
  bool get _atPrimary => _current.path == '/storage/emulated/0';

  /// 进入子目录（把当前目录压栈，便于返回）
  void _enter(Directory d) {
    _stack.add(_current.path);
    setState(() => _current = d);
  }

  /// 一键返回主存储
  void _jumpPrimary() {
    _stack.clear();
    setState(() => _current = Directory('/storage/emulated/0'));
  }

  /// 返回上级：主存储 → 分区选择；更深目录 → 上一级
  void _goUp() {
    if (_atStorageRoot) return;
    if (_atPrimary) {
      _stack.clear();
      setState(() => _current = Directory('/storage'));
      return;
    }
    setState(() => _current = Directory(_stack.removeLast()));
  }

  bool _match(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return false;
    return widget.extensions.contains(name.substring(dot + 1).toLowerCase());
  }

  void _toggle(String path) {
    setState(() {
      if (!_selected.remove(path)) _selected.add(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _atStorageRoot
              ? '选择分区'
              : _atPrimary
                  ? '主存储 (emulated/0)'
                  : _current.path.split('/').last,
        ),
        leading: _atStorageRoot
            ? null // 分区选择页：返回键=退出浏览器
            : IconButton(icon: const Icon(Icons.arrow_upward), onPressed: _goUp),
        actions: [
          if (_atStorageRoot)
            TextButton(onPressed: _jumpPrimary, child: const Text('进入主存储'))
          else if (_atPrimary)
            TextButton(onPressed: _goUp, child: const Text('切换分区'))
          else
            TextButton(onPressed: _jumpPrimary, child: const Text('主存储')),
        ],
      ),
      body: _atStorageRoot
          ? _rootView(theme)
          : FutureBuilder<List<FileSystemEntity>>(
              future: _listSafe(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '无法读取该目录（可能没有访问权限或目录已不可用）：\n${snap.error}\n\n'
                        '请确认已开启"文件管理权限"，再返回上一级目录重试。',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  );
                }
                return _fileList(theme, snap.data ?? const []);
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.of(context).pop(_selected.toList()),
            icon: const Icon(Icons.check),
            label: Text('确定添加 (${_selected.length})'),
          ),
        ),
      ),
    );
  }

  Future<List<FileSystemEntity>> _listSafe() async {
    final list = _current.list().toList();
    return list;
  }

  /// 根目录：列出主存储与其它顶层目录。
  Widget _rootView(ThemeData theme) {
    final storage = Directory('/storage');
    final roots = <Directory>[];
    try {
      roots.addAll(storage.listSync().whereType<Directory>());
    } catch (_) {}
    if (roots.isEmpty) {
      return const Center(child: Text('未找到可访问的存储目录'));
    }
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('快捷进入主存储，或选择其它分区（可多选文件）',
              style: theme.textTheme.bodySmall),
        ),
        ListTile(
          leading: const Icon(Icons.folder_special),
          title: const Text('主存储 · /storage/emulated/0'),
          subtitle: const Text('照片 / 下载 / Music 等默认目录',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => _enter(Directory('/storage/emulated/0')),
        ),
        for (final d in roots)
          if (d.path != '/storage/emulated')
            ListTile(
              leading: const Icon(Icons.folder),
              title: Text(d.path),
              onTap: () => _enter(d),
            ),
      ],
    );
  }

  Widget _fileList(ThemeData theme, List<FileSystemEntity> entries) {
    final dirs = <Directory>[];
    final files = <File>[];
    for (final e in entries) {
      if (e is Directory) dirs.add(e);
      if (e is File && _match(e.path)) files.add(e);
    }
    dirs.sort((a, b) => a.path.compareTo(b.path));
    files.sort((a, b) => a.path.compareTo(b.path));

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(_current.path,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ),
        for (final d in dirs)
          ListTile(
            dense: true,
            leading: const Icon(Icons.folder_outlined),
            title: Text(d.path.split(Platform.pathSeparator).last,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => _enter(d),
          ),
        for (final f in files)
          ListTile(
            dense: true,
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(f.uri.pathSegments.last,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(formatBytes(_sizeOf(f))),
            trailing: Icon(
              _selected.contains(f.path)
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: _selected.contains(f.path)
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            onTap: () => _toggle(f.path),
          ),
        if (dirs.isEmpty && files.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('此目录没有可转换的文件')),
          ),
      ],
    );
  }

  static int _sizeOf(File f) {
    try {
      return f.lengthSync();
    } catch (_) {
      return 0;
    }
  }
}
