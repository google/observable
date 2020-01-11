// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observable.test.observable_test_utils;

import 'dart:async';

import 'package:observable/observable.dart';
import 'package:test/test.dart';

/// A small method to help readability. Used to cause the next "then" in a chain
/// to happen in the next microtask:
///
///     future.then(newMicrotask).then(...)
Future newMicrotask(_) => Future.value();

void expectChanges(List<ChangeRecord> actual, List<ChangeRecord> expected,
    {String reason}) {
  expect(actual, _EqualsMatcher(expected), reason: reason);
}

void expectNotChanges(List<ChangeRecord> actual, ChangeRecords expectedNot,
    {String reason}) {
  expect(actual, isNot(_EqualsMatcher(expectedNot)), reason: reason);
}

List<ListChangeRecord> getListChangeRecords(
        List<ListChangeRecord> changes, int index) =>
    List.from(changes.where((ListChangeRecord c) => c.indexChanged(index)));

List<PropertyChangeRecord> getPropertyChangeRecords(
        List<ChangeRecord> changes, Symbol property) =>
    List.from(changes.where(
        (ChangeRecord c) => c is PropertyChangeRecord && c.name == property));

List<Matcher> changeMatchers(List<ChangeRecord> changes) => changes
    .map((r) =>
        r is PropertyChangeRecord ? _PropertyChangeMatcher(r) : equals(r))
    .toList();

// Custom equality matcher is required, otherwise expect() infers ChangeRecords
// to be an iterable and does a deep comparison rather than use the == operator.
class _EqualsMatcher<ValueType> extends Matcher {
  final ValueType _expected;

  _EqualsMatcher(this._expected);

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);

  @override
  bool matches(dynamic item, Map matchState) =>
      item is ChangeRecords && _expected == item;
}

class _PropertyChangeMatcher<ValueType> extends Matcher {
  final PropertyChangeRecord<ValueType> _expected;

  _PropertyChangeMatcher(this._expected);

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);

  @override
  bool matches(dynamic other, Map matchState) =>
      identical(_expected, other) ||
      other is PropertyChangeRecord &&
          _expected.runtimeType == other.runtimeType &&
          _expected.name == other.name &&
          _expected.oldValue == other.oldValue &&
          _expected.newValue == other.newValue;
}
