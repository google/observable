// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observable.src.records;

import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

import 'internal.dart';

part 'records/list_change_record.dart';
part 'records/map_change_record.dart';
part 'records/property_change_record.dart';

/// Result of a change to an observed object.
class ChangeRecord {
  /// Signifies a change occurred, but without details of the specific change.
  ///
  /// May be used to produce lower-GC-pressure records where more verbose change
  /// records will not be used directly.
  static const ANY = ChangeRecords<ChangeRecord>.any();

  /// Signifies no changes occurred.
  static const NONE = ChangeRecords<ChangeRecord>.none();

  const ChangeRecord();
}

/// Represents a list of change records.
///
/// The motivation for implementing the list interface is to fix a typing
/// issue with ChangeRecord.ANY while maintaining backwards compatibility with
/// existing code.
class ChangeRecords<RecordType extends ChangeRecord>
    extends DelegatingList<RecordType> {
  // This is a covariant unfortunately because generics cannot be used in a
  // const constructor. Should be sound however since the equality check does
  // not do any mutations.
  static const _listEquals = ListEquality<ChangeRecord>();

  final bool _isAny;

  final List<RecordType> _delegate;

  /// Represents any change where the list of changes is irrelevant.
  const ChangeRecords.any() : this._(const [], true);

  /// Represents a null change where nothing happened.
  const ChangeRecords.none() : this._(const [], false);

  /// Wraps around a list of records.
  ///
  /// Note: this wraps around a shallow copy of [list]. If [list] is modified,
  /// then it is modified within this change record as well. This is provide a
  /// const constructor for [ChangeRecords].
  const ChangeRecords.wrap(List<RecordType> list) : this._(list, false);

  /// Creates a change record list from a deep copy of [it].
  ChangeRecords.fromIterable(Iterable<RecordType> it)
      : this._(List.unmodifiable(it), false);

  const ChangeRecords._(this._delegate, this._isAny) : super(_delegate);

  @override
  int get hashCode => hash2(_delegate, _isAny);

  /// Equal if this and [other] have the same generic type and either both are
  /// any records or both are not any records and have the same list of entries.
  ///
  /// E.g.
  ///   ChangeRecords<CR1>.any() == ChangeRecords<CR1>.any()
  ///   ChangeRecords<CR1>.any() != ChangeRecords<CR2>.any()
  ///
  /// List of records checked with deep comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeRecords &&
          runtimeType == other.runtimeType &&
          ((_isAny && other._isAny) ||
              (!_isAny &&
                  !other._isAny &&
                  _listEquals.equals(_delegate, other._delegate)));

  @override
  String toString() =>
      _isAny ? 'ChangeRecords.any' : 'ChangeRecords($_delegate)';
}
