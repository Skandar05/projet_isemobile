import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/Pd_Providers.dart';
import 'package:test/Screens/Pedagogique/ClassLevelsPage.dart';

class FakePdProvider extends PdProvider {
  final List<dynamic> fakeClasses;

  FakePdProvider(this.fakeClasses);

  @override
  Future<List<dynamic>> getAllClasses() async {
    return fakeClasses;
  }
}

void main() {
  testWidgets('Class levels page loads classes and navigates to subclasses',
      (WidgetTester tester) async {
    final fakeClasses = [
      {'id': 151, 'nomclassefr': '1S1'},
      {'id': 161, 'nomclassefr': '1S2'},
      {'id': 152, 'nomclassefr': '2SC1'},
      {'id': 162, 'nomclassefr': '2SC2'},
      {'id': 169, 'nomclassefr': '3M1'},
      {'id': 174, 'nomclassefr': '3M2'},
      {'id': 148, 'nomclassefr': '7B1'},
      {'id': 156, 'nomclassefr': '7B2'},
      {'id': 157, 'nomclassefr': '7B3'},
      {'id': 163, 'nomclassefr': '7B4'},
    ];

    final fakeProvider = FakePdProvider(fakeClasses);

    await tester.pumpWidget(
      ChangeNotifierProvider<PdProvider>.value(
        value: fakeProvider,
        child: const MaterialApp(
          home: ClassLevelsPage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    expect(find.text('7B1'), findsNothing);
    expect(find.text('7B2'), findsNothing);

    await tester.tap(find.text('7'));
    await tester.pumpAndSettle();

    expect(find.text('7B1'), findsOneWidget);
    expect(find.text('7B2'), findsOneWidget);
    expect(find.text('7B3'), findsOneWidget);
    expect(find.text('7B4'), findsOneWidget);

    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
  });
}
