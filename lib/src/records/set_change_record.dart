// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable.src.records;

/// A [ChangeRecord] that denotes adding or removing values from a [Set].
class SetChangeRecord<E> implements ChangeRecord {
  /// Whether this is a removal operation.
  final bool isRemove;

  /// Element added or removed in the operation.
  final E element;

  const SetChangeRecord.add(this.element) : isRemove = false;
  const SetChangeRecord.remove(this.element) : isRemove = true;

  /// Whether this is an add operation.
  bool get isAdd => !isRemove;

  /// Apply the change operation to [set].
  void apply(Set<E> set) {
    if (isRemove) {
      set.remove(element);
    } else {
      set.add(element);
    }
  }

  @override
  bool operator ==(Object o) =>
      o is SetChangeRecord<E> && element == o.element && isRemove == o.isRemove;

  @override
  int get hashCode => hash2(element, isRemove);

  @override
  String toString() {
    return '#<SetChangeRecord ${isRemove ? 'remove' : 'add'} $element>';
  }
}
