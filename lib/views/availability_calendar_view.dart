import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/busy_block.dart';

/// A single-day timeline showing which parts of the working day are free.
class AvailabilityCalendarView extends StatefulWidget {
  const AvailabilityCalendarView({super.key, required this.busyBlocks});

  final List<BusyBlock> busyBlocks;

  @override
  State<AvailabilityCalendarView> createState() =>
      _AvailabilityCalendarViewState();
}

class _AvailabilityCalendarViewState extends State<AvailabilityCalendarView> {
  static const int _startHour = 8;
  static const int _endHour = 22;
  static const double _hourHeight = 64;

  late DateTime _selectedDay = _startOfToday();

  static DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _changeDay(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              const Spacer(),
              Text(
                DateFormat.yMMMEd().format(_selectedDay),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _changeDay(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _timeLabels(context),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: _timelineHeight,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              _hourLines(context),
                              for (final block in _freeBlocks)
                                _blockView(
                                  context,
                                  block,
                                  color: Colors.greenAccent.withValues(
                                    alpha: 0.28,
                                  ),
                                  title: 'Available',
                                  width: constraints.maxWidth,
                                ),
                              for (final block in _visibleBusyBlocks)
                                _blockView(
                                  context,
                                  block,
                                  color: Colors.white.withValues(alpha: 0.16),
                                  title: 'Busy',
                                  width: constraints.maxWidth,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeLabels(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Column(
      children: [
        for (var hour = _startHour; hour < _endHour; hour++)
          SizedBox(
            width: 42,
            height: _hourHeight,
            child: Align(
              alignment: Alignment.topRight,
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: style,
              ),
            ),
          ),
      ],
    );
  }

  Widget _hourLines(BuildContext context) {
    return Column(
      children: [
        for (var hour = _startHour; hour < _endHour; hour++)
          SizedBox(
            height: _hourHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
      ],
    );
  }

  Widget _blockView(
    BuildContext context,
    BusyBlock block, {
    required Color color,
    required String title,
    required double width,
  }) {
    final height = _blockHeight(block) < 24.0 ? 24.0 : _blockHeight(block);

    return Positioned(
      left: 4,
      top: _yOffset(block),
      width: width - 8,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(6),
        alignment: Alignment.topLeft,
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  double get _timelineHeight => (_endHour - _startHour) * _hourHeight;

  DateTime get _workingStart => DateTime(
    _selectedDay.year,
    _selectedDay.month,
    _selectedDay.day,
    _startHour,
  );

  DateTime get _workingEnd => DateTime(
    _selectedDay.year,
    _selectedDay.month,
    _selectedDay.day,
    _endHour,
  );

  /// Busy blocks clipped to the visible part of the selected day.
  List<BusyBlock> get _visibleBusyBlocks {
    final start = _workingStart;
    final end = _workingEnd;

    final blocks =
        widget.busyBlocks
            .where(
              (block) => block.end.isAfter(start) && block.start.isBefore(end),
            )
            .map(
              (block) => BusyBlock(
                start: block.start.isAfter(start) ? block.start : start,
                end: block.end.isBefore(end) ? block.end : end,
              ),
            )
            .toList()
          ..sort((lhs, rhs) => lhs.start.compareTo(rhs.start));

    return blocks;
  }

  /// The gaps between the busy blocks — the free time to offer.
  List<BusyBlock> get _freeBlocks {
    final result = <BusyBlock>[];
    var cursor = _workingStart;

    for (final busyBlock in _visibleBusyBlocks) {
      if (cursor.isBefore(busyBlock.start)) {
        result.add(BusyBlock(start: cursor, end: busyBlock.start));
      }

      if (busyBlock.end.isAfter(cursor)) {
        cursor = busyBlock.end;
      }
    }

    if (cursor.isBefore(_workingEnd)) {
      result.add(BusyBlock(start: cursor, end: _workingEnd));
    }

    return result;
  }

  double _yOffset(BusyBlock block) {
    final seconds = block.start.difference(_workingStart).inSeconds;
    return seconds / 3600 * _hourHeight;
  }

  double _blockHeight(BusyBlock block) {
    final seconds = block.end.difference(block.start).inSeconds;
    return seconds / 3600 * _hourHeight;
  }

  void _changeDay(int value) {
    setState(() {
      // Rebuilding from components keeps the day at midnight across DST shifts.
      _selectedDay = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day + value,
      );
    });
  }
}
