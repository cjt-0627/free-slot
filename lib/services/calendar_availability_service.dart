import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';

import '../models/busy_block.dart';

/// Reads the signed-in user's Google Calendar and exposes the busy time of the
/// next seven days.
class CalendarAvailabilityService extends ChangeNotifier {
  static const List<String> _scopes = <String>[
    'https://www.googleapis.com/auth/calendar.freebusy',
  ];

  List<BusyBlock> _busyBlocks = const [];
  List<BusyBlock> get busyBlocks => _busyBlocks;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  set errorMessage(String? value) {
    if (_errorMessage == value) return;

    _errorMessage = value;
    notifyListeners();
  }

  Future<void> requestAccessAndLoadNextSevenDays() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final api = await _authorizedApi();

      if (api != null) {
        await _loadNextSevenDays(api);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs the user in when needed and returns a Calendar client authorized for
  /// [_scopes], or null with [errorMessage] describing why it could not.
  Future<CalendarApi?> _authorizedApi() async {
    try {
      final signIn = GoogleSignIn.instance;

      GoogleSignInAccount? user = await signIn
          .attemptLightweightAuthentication();
      user ??= await signIn.authenticate();

      var authorization = await user.authorizationClient.authorizationForScopes(
        _scopes,
      );
      authorization ??= await user.authorizationClient.authorizeScopes(_scopes);

      return CalendarApi(authorization.authClient(scopes: _scopes));
    } on GoogleSignInException catch (error) {
      _errorMessage = 'Google sign-in failed: ${error.code.name}';
      return null;
    }
  }

  Future<void> _loadNextSevenDays(CalendarApi api) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 7));

    await _loadBusyBlocks(api, from: start, to: end);
  }

  Future<void> _loadBusyBlocks(
    CalendarApi api, {
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await api.freebusy.query(
      FreeBusyRequest(
        timeMin: from.toUtc(),
        timeMax: to.toUtc(),
        items: [FreeBusyRequestItem(id: 'primary')],
      ),
    );

    final blocks = <BusyBlock>[];

    for (final calendar
        in response.calendars?.values ?? const <FreeBusyCalendar>[]) {
      for (final period in calendar.busy ?? const <TimePeriod>[]) {
        final start = period.start?.toLocal();
        final end = period.end?.toLocal();

        if (start == null || end == null || !end.isAfter(start)) continue;

        blocks.add(BusyBlock(start: start, end: end));
      }
    }

    blocks.sort((lhs, rhs) => lhs.start.compareTo(rhs.start));

    _busyBlocks = _mergeOverlapping(blocks);
  }

  List<BusyBlock> _mergeOverlapping(List<BusyBlock> blocks) {
    if (blocks.isEmpty) return const [];

    var current = blocks.first;
    final merged = <BusyBlock>[];

    for (final block in blocks.skip(1)) {
      if (!block.start.isAfter(current.end)) {
        current = BusyBlock(
          start: current.start,
          end: block.end.isAfter(current.end) ? block.end : current.end,
        );
      } else {
        merged.add(current);
        current = block;
      }
    }

    merged.add(current);
    return merged;
  }
}
