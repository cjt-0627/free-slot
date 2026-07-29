/// A single stretch of time that is already taken up by a calendar event.
///
/// Instances carry a unique [id] so that a list of blocks with identical
/// start/end times still keeps stable widget identities.
class BusyBlock {
  BusyBlock({required this.start, required this.end}) : id = _nextId();

  final String id;
  final DateTime start;
  final DateTime end;

  static int _counter = 0;

  static String _nextId() => 'busy-block-${_counter++}';

  @override
  bool operator ==(Object other) =>
      other is BusyBlock &&
      other.id == id &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(id, start, end);
}
