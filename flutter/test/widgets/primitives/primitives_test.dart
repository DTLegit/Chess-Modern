import 'package:chess/src/rust/api.dart' as rust;
import 'package:chess/src/theme/app_theme.dart';
import 'package:chess/src/widgets/primitives/app_button.dart';
import 'package:chess/src/widgets/primitives/app_dialog.dart';
import 'package:chess/src/widgets/primitives/app_list_row.dart';
import 'package:chess/src/widgets/primitives/app_switch.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _settings = rust.Settings(
  appTheme: rust.AppTheme.light,
  boardTheme: rust.BoardTheme.wood,
  pieceSet: rust.PieceSet.merida,
  accent: rust.Accent.walnut,
  soundEnabled: true,
  soundVolume: 0.6,
  showLegalMoves: true,
  showCoordinates: true,
  showLastMove: true,
);

Widget _wrap(Widget child) {
  return WidgetsApp(
    color: const Color(0xFFF4EDE0),
    builder: (_, __) => AppTheme(
      data: AppThemeData.fromSettings(_settings),
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'Inter'),
        child: Center(child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('AppButton renders label and fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(
      AppButton(label: 'Hit me', onPressed: () => taps++),
    ));
    expect(find.text('Hit me'), findsOneWidget);
    await tester.tap(find.text('Hit me'));
    expect(taps, 1);
  });

  testWidgets('AppButton respects disabled state', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppButton(label: 'Off', onPressed: null),
    ));
    final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacity.opacity, lessThan(1.0));
  });

  testWidgets('AppSwitch toggles', (tester) async {
    var on = false;
    await tester.pumpWidget(_wrap(
      StatefulBuilder(
        builder: (ctx, setState) => AppSwitch(
          value: on,
          onChanged: (v) => setState(() => on = v),
        ),
      ),
    ));
    await tester.tap(find.byType(AppSwitch));
    await tester.pump();
    expect(on, true);
  });

  testWidgets('AppListRow shows title and subtitle', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppListRow(title: 'Sound', subtitle: 'Volume 60%'),
    ));
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Volume 60%'), findsOneWidget);
  });

  testWidgets('AppDialog renders title and body', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppDialog(
        title: 'Settings',
        body: Text('contents'),
      ),
    ));
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('contents'), findsOneWidget);
  });
}
