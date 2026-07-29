import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:free_time/main.dart';
import 'package:free_time/models/busy_block.dart';
import 'package:free_time/views/availability_calendar_view.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_Hant_TW');
  });

  testWidgets('shows the empty state before anything is synced', (
    tester,
  ) async {
    await tester.pumpWidget(const FreeTimeApp());

    expect(find.text('My Free Time'), findsOneWidget);
    expect(find.text("Haven't loaded your busy slots."), findsOneWidget);
    expect(find.text('Sync'), findsOneWidget);
  });

  testWidgets('timeline splits the working day into busy and free blocks', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvailabilityCalendarView(
            busyBlocks: [
              BusyBlock(
                start: today.add(const Duration(hours: 10)),
                end: today.add(const Duration(hours: 12)),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Busy'), findsOneWidget);
    // One free gap before the block (08:00-10:00) and one after (12:00-22:00).
    expect(find.text('Available'), findsNWidgets(2));
  });
}
