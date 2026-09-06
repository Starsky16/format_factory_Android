import 'package:flutter_test/flutter_test.dart';
import 'package:format_factory/app.dart';

/// 冒烟测试：应用能正常启动并渲染首页。
void main() {
  testWidgets('启动并显示首页标题', (WidgetTester tester) async {
    await tester.pumpWidget(const FormatFactoryApp());
    // 首页 AppBar 标题"格式工厂"应出现
    expect(find.text('格式工厂'), findsOneWidget);
    // 三个媒体入口都在
    expect(find.text('视频转换'), findsOneWidget);
    expect(find.text('音频转换'), findsOneWidget);
    expect(find.text('图片转换'), findsOneWidget);
  });
}
