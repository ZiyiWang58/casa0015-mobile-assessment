import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/walk_record.dart';

/// Calendar screen showing which days have recorded walks.
class CalendarScreen extends StatefulWidget {
  final List<WalkRecord> records;

  const CalendarScreen({
    super.key,
    required this.records,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  /// Normalize a date so only year/month/day are compared.
  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Group walk records by calendar day.
  Map<DateTime, List<WalkRecord>> buildEventsMap() {
    final Map<DateTime, List<WalkRecord>> events = {};

    for (final record in widget.records) {
      final date = normalizeDate(record.endTime);
      events.putIfAbsent(date, () => []);
      events[date]!.add(record);
    }

    return events;
  }

  /// Return all walk records for one selected day.
  List<WalkRecord> getRecordsForDay(DateTime day) {
    final events = buildEventsMap();
    return events[normalizeDate(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedRecords = selectedDay == null
        ? <WalkRecord>[]
        : getRecordsForDay(selectedDay!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk Calendar'),
      ),
      body: Column(
        children: [
          /// Main monthly calendar showing walk activity.
          TableCalendar<WalkRecord>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) {
              if (selectedDay == null) return false;
              return isSameDay(selectedDay, day);
            },
            eventLoader: (day) {
              return getRecordsForDay(day);
            },
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });
            },
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange.shade300,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 12),

          /// Summary area showing walk records for the chosen day.
          Expanded(
            child: selectedDay == null
                ? const Center(
              child: Text('Select a day to view walk records.'),
            )
                : selectedRecords.isEmpty
                ? const Center(
              child: Text('No walks recorded for this day.'),
            )
                : ListView.builder(
              itemCount: selectedRecords.length,
              itemBuilder: (context, index) {
                final record = selectedRecords[index];
                return ListTile(
                  leading: Icon(
                    record.goalReached
                        ? Icons.check_circle
                        : Icons.directions_walk,
                    color: record.goalReached
                        ? Colors.green
                        : Colors.blue,
                  ),
                  title: Text(
                    '${record.distanceKm.toStringAsFixed(2)} km',
                  ),
                  subtitle: Text(
                    '${record.startTime.hour.toString().padLeft(2, '0')}:'
                        '${record.startTime.minute.toString().padLeft(2, '0')}'
                        ' - '
                        '${record.endTime.hour.toString().padLeft(2, '0')}:'
                        '${record.endTime.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: Text(
                    record.goalReached ? 'Goal met' : 'Not met',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}