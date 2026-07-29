import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/busy_block.dart';
import '../services/calendar_availability_service.dart';
import 'availability_calendar_view.dart';

enum DisplayMode {
  list('List'),
  calendar('Calendar');

  const DisplayMode(this.label);

  final String label;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final DateFormat _dateFormat = DateFormat(
    'M/d (EEE) HH:mm',
    'zh_Hant_TW',
  );

  DisplayMode _displayMode = DisplayMode.list;
  bool _isShowingError = false;
  late final CalendarAvailabilityService _calendarService;

  @override
  void initState() {
    super.initState();
    _calendarService = context.read<CalendarAvailabilityService>();
    _calendarService.addListener(_handleServiceChange);
  }

  @override
  void dispose() {
    _calendarService.removeListener(_handleServiceChange);
    super.dispose();
  }

  void _handleServiceChange() {
    if (_calendarService.errorMessage == null || _isShowingError) return;

    _isShowingError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showErrorDialog());
  }

  Future<void> _showErrorDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cannot Sync'),
        content: Text(_calendarService.errorMessage ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    _isShowingError = false;
    _calendarService.errorMessage = null;
  }

  @override
  Widget build(BuildContext context) {
    final calendarService = context.watch<CalendarAvailabilityService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Free Time'),
        actions: [
          TextButton(
            onPressed: calendarService.requestAccessAndLoadNextSevenDays,
            child: const Text('Sync'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<DisplayMode>(
              segments: [
                for (final mode in DisplayMode.values)
                  ButtonSegment(value: mode, label: Text(mode.label)),
              ],
              selected: {_displayMode},
              onSelectionChanged: (selection) {
                setState(() => _displayMode = selection.first);
              },
            ),
          ),
          Expanded(child: _content(calendarService)),
        ],
      ),
    );
  }

  Widget _content(CalendarAvailabilityService calendarService) {
    if (calendarService.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Calculating your busy slot...'),
          ],
        ),
      );
    }

    if (calendarService.busyBlocks.isEmpty) {
      return _emptyState();
    }

    if (_displayMode == DisplayMode.list) {
      return _busyList(calendarService.busyBlocks);
    }

    return AvailabilityCalendarView(busyBlocks: calendarService.busyBlocks);
  }

  Widget _emptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month,
              size: 52,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              "Haven't loaded your busy slots.",
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with Google and only your busy slots show up here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _busyList(List<BusyBlock> blocks) {
    return ListView.separated(
      itemCount: blocks.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final block = blocks[index];

        return ListTile(
          leading: const Icon(Icons.event_busy, color: Colors.orangeAccent),
          title: Text('Busy', style: Theme.of(context).textTheme.titleSmall),
          subtitle: Text(
            _timeText(block),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  String _timeText(BusyBlock block) {
    final start = _dateFormat.format(block.start);
    final end = _dateFormat.format(block.end);

    return '$start - $end';
  }
}
