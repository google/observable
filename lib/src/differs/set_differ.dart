// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable.src.differs;

/// Determines differences between two maps, returning [SetChangeRecord]s.
///
/// While [SetChangeRecord] has more information and can be replayed they carry
/// a more significant cost to calculate and create and should only be used when
/// the details in the record will actually be used.
///
/// See also [EqualityDiffer] for a simpler comparison.
class SetDiffer<E> implements Differ<Set<E>> {
  const SetDiffer();

  @override
  List<SetChangeRecord<E>> diff(Set<E> oldValue, Set<E> newValue) {
    if (identical(oldValue, newValue)) {
      return ChangeRecord.NONE;
    }
    final changes = <SetChangeRecord<E>>[];
    for (final added in newValue.difference(oldValue)) {
      changes.add(new SetChangeRecord<E>.add(added));
    }
    for (final removed in oldValue.difference(newValue)) {
      changes.add(new SetChangeRecord<E>.remove(removed));
    }
    return changes;
  }
}
