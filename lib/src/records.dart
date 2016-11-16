library observable.src.records;

import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

part 'records/list_change_record.dart';

/// Result of a change to an observed object.
class ChangeRecord {
  /// Signifies a change occurred, but without details of the specific change.
  ///
  /// May be used to produce lower-GC-pressure records where more verbose change
  /// records will not be used directly.
  static const List<ChangeRecord> ANY = const [const ChangeRecord()];

  /// Signifies no changes occurred.
  static const List<ChangeRecord> NONE = const [];

  const ChangeRecord();
}
