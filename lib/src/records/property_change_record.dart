// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable.src.records;

/// A change record to a field of a generic observable object.
class PropertyChangeRecord<T> implements ChangeRecord {
  /// Object that changed.
  final Object object;

  /// Name of the property that changed.
  final Symbol name;

  /// Previous value of the property.
  final T oldValue;

  /// New value of the property.
  final T newValue;

  const PropertyChangeRecord(
    this.object,
    this.name,
    this.oldValue,
    this.newValue,
  );

  @override
  bool operator ==(Object o) =>
      o is PropertyChangeRecord<T> &&
      identical(object, o.object) &&
      name == o.name &&
      oldValue == o.oldValue &&
      newValue == o.newValue;

  @override
  int get hashCode => hash4(object, name, oldValue, newValue);

  @override
  String toString() => ''
      '#<$PropertyChangeRecord $name from $oldValue to: $newValue>';
}
