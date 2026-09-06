import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../services/ffmpeg_engine.dart';

/// 全局任务队列（Riverpod 状态）。
///
/// 职责：
///   1. 维护全部任务列表（state）
///   2. 串行执行（同时只转一个，避免把手机 CPU/内存打满）
///   3. 把 FFmpeg 的进度统计换算成 0~1 的 progress 写回任务
///   4. 支持取消当前任务 / 清空队列 / 失败重试
final taskQueueProvider =
    NotifierProvider<TaskQueue, List<ConvertTask>>(TaskQueue.new);

class TaskQueue extends Notifier<List<ConvertTask>> {
  /// 是否正在转码（串行锁）。
  bool _running = false;

  /// 当前正在执行的 FFmpeg 会话（用于取消）。
  FFmpegSession? _activeSession;

  /// 生成一个大概率不重复的任务 id。
  static String newId() =>
      't${DateTime.now().microsecondsSinceEpoch}';

  @override
  List<ConvertTask> build() => [];

  /// 按 id 修改列表中某个任务（找不到就忽略）。
  void _patch(String id, ConvertTask Function(ConvertTask) change) {
    final i = state.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final next = List<ConvertTask>.from(state);
    next[i] = change(state[i]);
    state = next;
  }

  // ---------- 队列控制 ----------

  /// 把一批任务加入队列，并尝试启动下一个。
  void enqueue(List<ConvertTask> tasks) {
    if (tasks.isEmpty) return;
    state = [...state, ...tasks];
    _pump();
  }

  /// 串行调度：若没在转码，就取第一个"排队中"的任务开跑。
  void _pump() {
    if (_running) return;
    final i = state.indexWhere((t) => t.status == TaskStatus.queued);
    if (i < 0) return;
    _running = true;
    _run(state[i]);
  }

  Future<void> _run(ConvertTask task) async {
    _patch(task.id, (t) => t.copyWith(status: TaskStatus.running, progress: 0));

    final command = FfmpegEngine.buildCommand(task);
    try {
      final session = await FFmpegKit.executeAsync(
        command,
        // 完成回调：根据返回码判定成功/失败/被取消
        (s) async {
          final rc = await s.getReturnCode();
          if (ReturnCode.isSuccess(rc)) {
            _finish(task, succeeded: true);
          } else if (ReturnCode.isCancel(rc)) {
            _finish(task, canceled: true);
          } else {
            // 返回码非 0：可能是编码错误或异常
            final stack = await s.getFailStackTrace();
            final logs = await _tail(s);
            _finish(
              task,
              succeeded: false,
              message: stack ?? logs ?? 'FFmpeg 执行失败（返回码 $rc）',
            );
          }
        },
        // 日志回调：这里只收集，不处理（出错时用 getAllLogsAsString 取尾巴）
        (log) {},
        // 统计回调：time 是已经处理到的视频时间(毫秒)，用它算百分比
        (stat) {
          final durationMs = (task.inputDurationSeconds ?? 0) * 1000;
          if (durationMs <= 0) return;
          final p = (stat.getTime() / durationMs).clamp(0.0, 1.0);
          _patch(task.id, (t) => t.copyWith(progress: p));
        },
      );
      _activeSession = session;
    } catch (e) {
      _finish(task, succeeded: false, message: '启动 FFmpeg 失败：$e');
    }
  }

  /// 结束当前任务并调度下一个。
  void _finish(
    ConvertTask task, {
    bool succeeded = false,
    bool canceled = false,
    String? message,
  }) {
    _activeSession = null;
    _running = false;

    final status =
        canceled ? TaskStatus.canceled : (succeeded ? TaskStatus.succeeded : TaskStatus.failed);

    _patch(task.id, (t) {
      final updated =
          t.copyWith(status: status, progress: succeeded ? 1.0 : t.progress, error: message);
      return updated;
    });

    // 失败/取消时清掉可能留下的半截输出文件
    if (!succeeded) {
      _deleteOutput(task.outputPath);
    }
    _pump();
  }

  static void _deleteOutput(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  static Future<String?> _tail(FFmpegSession s) async {
    try {
      final logs = await s.getAllLogsAsString(2000);
      if (logs == null) return null;
      final lines = logs.trim().split('\n');
      return lines.length > 8 ? lines.sublist(lines.length - 8).join('\n') : logs;
    } catch (_) {
      return null;
    }
  }

  // ---------- 供界面调用的操作 ----------

  /// 取消一个任务：正在转码的立刻中断，排队的直接标记取消。
  Future<void> cancel(String id) async {
    final task = state.where((t) => t.id == id).firstOrNull;
    if (task == null) return;
    if (task.status == TaskStatus.queued) {
      _patch(id, (t) => t.copyWith(status: TaskStatus.canceled));
      return;
    }
    if (task.status == TaskStatus.running) {
      await _activeSession?.cancel();
      // 完成回调会走到 _finish(canceled: true)，这里不用再处理
    }
  }

  /// 取消所有排队任务（正在转码的也一并中断）。
  Future<void> cancelAll() async {
    for (final t in state) {
      if (t.status == TaskStatus.queued) {
        _patch(t.id, (x) => x.copyWith(status: TaskStatus.canceled));
      }
    }
    await _activeSession?.cancel();
  }

  /// 失败/取消的任务重试（重新排队，清空错误）。
  void retry(String id) {
    _patch(id,
        (t) => t.copyWith(status: TaskStatus.queued, progress: 0, clearError: true));
    _pump();
  }

  /// 从列表删除一个任务（仅供已完成/失败等"不会再跑"的任务使用）。
  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  /// 清空所有"已经结束"的任务。
  void clearFinished() {
    state = state.where((t) => !t.status.isFinished).toList();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
