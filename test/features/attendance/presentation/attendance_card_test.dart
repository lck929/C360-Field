import 'package:c360/core/theme/app_theme.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/rules/attendance_rules.dart';
import 'package:c360/features/attendance/presentation/widgets/attendance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 11, 10, 12);

  Future<AttendanceType?> pumpCard(WidgetTester tester, List<AttendanceRecord> records) async {
    AttendanceType? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: AttendanceCard(today: summarizeDay(records, now, now), now: now, onAction: (t) => tapped = t),
        ),
      ),
    );
    final action = find.byKey(const Key('attendanceAction'));
    if (action.evaluate().isNotEmpty) await tester.tap(action);
    return tapped;
  }

  testWidgets('offers check in when not checked in', (tester) async {
    expect(await pumpCard(tester, []), AttendanceType.checkIn);
    expect(find.text('Not checked in'), findsOneWidget);
  });

  testWidgets('shows a pending check-in and offers check out', (tester) async {
    final tapped = await pumpCard(tester, [testRecord('in')]);

    expect(find.text('Checked in at'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    expect(find.textContaining('Waiting to sync'), findsOneWidget);
    expect(tapped, AttendanceType.checkOut);
  });

  testWidgets('hides the action once the shift is complete', (tester) async {
    await pumpCard(tester, [
      testRecord('in', status: SyncStatus.verified),
      testRecord('out', type: AttendanceType.checkOut, hour: 11, status: SyncStatus.verified),
    ]);

    expect(find.text('Checked out at'), findsOneWidget);
    expect(find.byKey(const Key('attendanceAction')), findsNothing);
  });
}
