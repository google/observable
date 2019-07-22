// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable.src.differs;

/// Determines differences between two maps, returning [MapChangeRecord]s.
///
/// While [MapChangeRecord] has more information and can be replayed they carry
/// a more significant cost to calculate and create and should only be used when
/// the details in the record will actually be used.
///
/// See also [EqualityDiffer] for a simpler comparison.
class MapDiffer<K, V> implements Differ<Map<K, V>> {
  const MapDiffer();

  @override
  List<MapChangeRecord<K, V>> diff(Map<K, V> oldValue, Map<K, V> newValue) {
    if (identical(oldValue, newValue)) {
      return const [];
    }
    final changes = <MapChangeRecord<K, V>>[];
    oldValue.forEach((oldK, oldV) {
      final newV = newValue[oldK];
      if (newV == null && !newValue.containsKey(oldK)) {
        changes.add(MapChangeRecord<K, V>.remove(oldK, oldV));
      } else if (newV != oldV) {
        changes.add(MapChangeRecord<K, V>(oldK, oldV, newV));
      }
    });
    newValue.forEach((newK, newV) {
      if (!oldValue.containsKey(newK)) {
        changes.add(MapChangeRecord<K, V>.insert(newK, newV));
      }
    });
    return freezeInDevMode(changes);
  }
}
