// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable.src.records;

/// A [ChangeRecord] that denotes adding, removing, or updating a map.
class MapChangeRecord<K, V> implements ChangeRecord {
  /// The map key that changed.
  final K key;

  /// The previous value associated with this key.
  ///
  /// Is always `null` if [isInsert].
  final V oldValue;

  /// The new value associated with this key.
  ///
  /// Is always `null` if [isRemove].
  final V newValue;

  /// True if this key was inserted.
  final bool isInsert;

  /// True if this key was removed.
  final bool isRemove;

  /// Create an update record of [key] from [oldValue] to [newValue].
  const MapChangeRecord(this.key, this.oldValue, this.newValue)
      : isInsert = false,
        isRemove = false;

  /// Create an insert record of [key] and [newValue].
  const MapChangeRecord.insert(this.key, this.newValue)
      : isInsert = true,
        isRemove = false,
        oldValue = null;

  /// Create a remove record of [key] with a former [oldValue].
  const MapChangeRecord.remove(this.key, this.oldValue)
      : isInsert = false,
        isRemove = true,
        newValue = null;

  /// Apply this change record to [map].
  void apply(Map<K, V> map) {
    if (isRemove) {
      map.remove(key);
    } else {
      map[key] = newValue;
    }
  }

  @override
  bool operator ==(Object o) {
    if (o is MapChangeRecord<K, V>) {
      return key == o.key &&
          oldValue == o.oldValue &&
          newValue == o.newValue &&
          isInsert == o.isInsert &&
          isRemove == o.isRemove;
    }
    return false;
  }

  @override
  int get hashCode {
    return hashObjects([
      key,
      oldValue,
      newValue,
      isInsert,
      isRemove,
    ]);
  }

  @override
  String toString() {
    final kind = isInsert ? 'insert' : isRemove ? 'remove' : 'set';
    return '#<MapChangeRecord $kind $key from $oldValue to $newValue>';
  }
}
