import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helloword/features/call/views/call_panel.dart';

/// 통화 패널 높이 계산 확인.
///
/// 브라우저로 열 때와 홈 화면에 추가한 앱으로 열 때 모양이 달라지던 문제가
/// 있었다. 브라우저는 주소창이 화면 높이를 깎아먹는데, 높이를 기준으로
/// 크기를 잡으면 그만큼 칸이 납작해져 영상이 이상한 비율로 보였다.
/// 그래서 '폭'을 기준으로 잡도록 고쳤고, 그게 유지되는지 확인한다.
Future<double> _heightFor(
  WidgetTester tester, {
  required Size size,
  double keyboard = 0,
  bool compact = false,
}) async {
  late double result;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        viewInsets: EdgeInsets.only(bottom: keyboard),
      ),
      child: ScreenUtilInit(
        designSize: const Size(402, 874),
        useInheritedMediaQuery: true,
        builder: (context, _) => Builder(
          builder: (context) {
            result = CallPanel.preferredHeight(context, compact: compact);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return result;
}

void main() {
  group('CallPanel.preferredHeight', () {
    testWidgets('주소창 때문에 화면 높이가 달라도 같은 높이가 나온다', (tester) async {
      // 같은 폰을 브라우저로 열 때(주소창이 높이를 깎음)와
      // 홈 화면 앱으로 열 때. 폭은 같고 높이만 다르다.
      final browser = await _heightFor(
        tester,
        size: const Size(393, 660),
      );
      final installedApp = await _heightFor(
        tester,
        size: const Size(393, 800),
      );

      expect(browser, moreOrLessEquals(installedApp, epsilon: 0.5));
    });

    testWidgets('폭이 넓어지면 높이도 같이 커진다', (tester) async {
      final small = await _heightFor(tester, size: const Size(360, 800));
      final large = await _heightFor(tester, size: const Size(430, 800));

      expect(large, greaterThan(small));
    });

    testWidgets('키보드가 올라오면 낮아진다', (tester) async {
      final open = await _heightFor(
        tester,
        size: const Size(393, 800),
        keyboard: 300,
        compact: true,
      );
      final closed = await _heightFor(tester, size: const Size(393, 800));

      expect(open, lessThan(closed));
    });

    testWidgets('자리가 아주 좁으면 화면을 다 잡아먹지 않는다', (tester) async {
      // 작은 폰 + 키보드. 남은 높이의 절반을 넘지 않아야 한다.
      const size = Size(360, 620);
      const keyboard = 300.0;
      final height = await _heightFor(
        tester,
        size: size,
        keyboard: keyboard,
        compact: true,
      );

      expect(height, lessThan((size.height - keyboard) * 0.5));
    });
  });
}
