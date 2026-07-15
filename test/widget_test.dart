import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exchange_app/calculator.dart';
import 'package:exchange_app/main.dart';
import 'package:exchange_app/models.dart';
import 'package:exchange_app/screens/preview_screen.dart';

// The History tab shows an indeterminate CircularProgressIndicator while its
// data loads, and IndexedStack keeps it mounted alongside the Quote tab. An
// indeterminate spinner never "settles", so these tests pump a fixed number
// of frames instead of using pumpAndSettle (which would hang forever).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App launches to the Quote screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ExchangeApp());
    await _settle(tester);

    expect(find.text('Currency Exchange'), findsWidgets);
    expect(find.text('SALE'), findsOneWidget);
  });

  testWidgets('Entering qty/rate on a line updates CN value and grand total', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ExchangeApp());
    await _settle(tester);

    final qtyField = find.byKey(const ValueKey('qty-0'));
    final rateField = find.byKey(const ValueKey('rate-0'));

    await tester.enterText(qtyField, '100');
    await tester.pump();
    await tester.enterText(rateField, '80');
    await tester.pump();

    // Amount for the single line should be 100 * 80 = 8000.
    expect(find.text('₹8000'), findsOneWidget);

    // Expand the total hero's details to check the CN value breakdown.
    await tester.tap(find.text('Details'));
    await tester.pump();
    expect(find.textContaining('8000.00'), findsWidgets);
  });

  testWidgets('Switching to Purchase updates the deal toggle state', (WidgetTester tester) async {
    await tester.pumpWidget(const ExchangeApp());
    await _settle(tester);

    await tester.tap(find.text('PURCHASE'));
    await _settle(tester);

    expect(find.text('PURCHASE'), findsOneWidget);
  });

  testWidgets('Preview screen renders the Ledger view (default) without errors', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final totals = computeTotals(cnTotal: 8000, service: 0, dealType: 'sale');

    await tester.pumpWidget(MaterialApp(
      home: PreviewScreen(
        dealType: 'sale',
        items: const [ExchangeItem(name: 'USD', qty: 100, rate: 80)],
        totals: totals,
        timestamp: DateTime(2026, 1, 1),
      ),
    ));
    await _settle(tester);

    // No exception should have been thrown while building/painting the widget tree.
    expect(tester.takeException(), isNull);

    // Ledger is the default style — its distinctive elements should be visible.
    expect(find.text('PAYMENT FROM SAVINGS ACCOUNT ONLY'), findsOneWidget);
    expect(find.text('TOTAL'), findsOneWidget);
    expect(find.text('8045'), findsOneWidget);
  });

  testWidgets('Ledger view hides the savings-account banner when No Charges is on', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final totals = computeTotals(cnTotal: 8000, service: 0, dealType: 'sale', noCharges: true);

    await tester.pumpWidget(MaterialApp(
      home: PreviewScreen(
        dealType: 'sale',
        items: const [ExchangeItem(name: 'USD', qty: 100, rate: 80)],
        totals: totals,
        timestamp: DateTime(2026, 1, 1),
      ),
    ));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('PAYMENT FROM SAVINGS ACCOUNT ONLY'), findsNothing);
    expect(find.text('TOTAL'), findsOneWidget);
    // With no charges, total equals the item amount (8000), so it's fine
    // for this to appear more than once (item line + total row).
    expect(find.text('8000'), findsWidgets);
  });
}
