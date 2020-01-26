// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observable.src.differs;

import 'dart:math' as math;

import 'package:collection/collection.dart';

import 'records.dart';

import 'internal.dart';

part 'differs/list_differ.dart';
part 'differs/map_differ.dart';

/// Generic comparisons between two comparable objects.
abstract class Differ<E> {
  /// Returns a list of change records between [oldValue] and [newValue].
  ///
  /// A return value of an empty [ChangeRecord.NONE] means no changes found.
  List<ChangeRecord> diff(E oldValue, E newValue);
}

/// Uses [Equality] to determine a simple [ChangeRecord.ANY] response.
class EqualityDiffer<E> implements Differ<E> {
  final Equality<E> _equality;

  const EqualityDiffer([this._equality = const DefaultEquality()]);

  const EqualityDiffer.identity() : _equality = const IdentityEquality();

  @override
  List<ChangeRecord> diff(E oldValue, E newValue) {
    return _equality.equals(oldValue, newValue)
        ? ChangeRecord.NONE
        : ChangeRecord.ANY;
  }
}
