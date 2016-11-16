library observable.src.differs;

import 'dart:math' as math;

import 'package:collection/collection.dart';

import 'records.dart';

part 'differs/list_differ.dart';

/// Generic comparisons between two comparable objects.
abstract class Differ<E> {
  /// Returns a list of change records between [e1] and [e2].
  ///
  /// A return value of an empty [ChangeRecord.NONE] means no changes found.
  List<ChangeRecord> diff(E e1, E e2);
}

/// Uses [Equality] to determine a simple [ChangeRecord.ANY] response.
class EqualityDiffer<E> implements Differ<E> {
  final Equality<E> _equality;

  const EqualityDiffer([this._equality = const DefaultEquality()]);

  const EqualityDiffer.identity() : this._equality = const IdentityEquality();

  @override
  List<ChangeRecord> diff(E e1, E e2) {
    return _equality.equals(e1, e2) ? ChangeRecord.NONE : ChangeRecord.ANY;
  }
}
