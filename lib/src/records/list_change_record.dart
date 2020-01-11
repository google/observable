// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable.src.records;

/// A [ChangeRecord] that denotes adding or removing nodes at [index].
///
/// It should be assumed that elements are [removed] *before* being added.
///
/// A [List<ListChangeRecord>] can be "played back" against the [List] using
/// the final list positions to figure out which item was added - this removes
/// the need to incur costly GC on the most common operation (adding).
class ListChangeRecord<E> implements ChangeRecord {
  /// How many elements were added at [index] (after removing elements).
  final int addedCount;

  /// Index of where the change occurred.
  final int index;

  /// List that changed.
  final List<E> object;

  /// Elements that were removed starting at [index] (before adding elements).
  final List<E> removed;

  factory ListChangeRecord(
    List<E> object,
    int index, {
    List<E> removed,
    int addedCount = 0,
  }) {
    return ListChangeRecord._(
        object, index, removed ?? UnmodifiableListView([]), addedCount);
  }

  /// Records an `add` operation at `object[index]` of [addedCount] elements.
  ListChangeRecord.add(this.object, this.index, this.addedCount)
      : removed = UnmodifiableListView([]) {
    _assertValidState();
  }

  /// Records a `remove` operation at `object[index]` of [removed] elements.
  ListChangeRecord.remove(this.object, this.index, List<E> removed)
      : removed = freezeInDevMode<E>(removed),
        addedCount = 0 {
    _assertValidState();
  }

  /// Records a `replace` operation at `object[index]` of [removed] elements.
  ///
  /// If [addedCount] is not specified it defaults to `removed.length`.
  ListChangeRecord.replace(this.object, this.index, List<E> removed,
      [int addedCount])
      : removed = freezeInDevMode<E>(removed),
        addedCount = addedCount ?? removed.length {
    _assertValidState();
  }

  ListChangeRecord._(
    this.object,
    this.index,
    this.removed,
    this.addedCount,
  ) {
    _assertValidState();
  }

  /// What elements were added to [object].
  Iterable<E> get added {
    return addedCount == 0
        ? const []
        : object.getRange(index, index + addedCount);
  }

  /// Apply this change record to [list].
  void apply(List<E> list) {
    list
      ..removeRange(index, index + removed.length)
      ..insertAll(index, object.getRange(index, index + addedCount));
  }

  void _assertValidState() {
    assert(() {
      if (object == null) {
        throw ArgumentError.notNull('object');
      }
      if (index == null) {
        throw ArgumentError.notNull('index');
      }
      if (removed == null) {
        throw ArgumentError.notNull('removed');
      }
      if (addedCount == null || addedCount < 0) {
        throw ArgumentError('Invalid `addedCount`: $addedCount');
      }
      return true;
    }());
  }

  /// Returns whether [reference] index was changed in this operation.
  bool indexChanged(int reference) {
    // If reference was before the change then it wasn't changed.
    if (reference < index) return false;

    // If this was a shift operation anything after index is changed.
    if (addedCount != removed.length) return true;

    // Otherwise anything in the update range was changed.
    return reference < index + addedCount;
  }

  @override
  bool operator ==(Object o) {
    if (o is ListChangeRecord<E>) {
      return identical(object, o.object) &&
          index == o.index &&
          addedCount == o.addedCount &&
          const ListEquality().equals(removed, o.removed);
    }
    return false;
  }

  @override
  int get hashCode {
    return hash4(object, index, addedCount, const ListEquality().hash(removed));
  }

  @override
  String toString() => ''
      '#<$ListChangeRecord index: $index, '
      'removed: $removed, '
      'addedCount: $addedCount>';
}
