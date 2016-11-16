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
newMicrotask(_) => new Future.value();

// TODO(jmesserly): use matchers when we have a way to compare ChangeRecords.
// For now just use the toString.
void expectChanges(actual, expected, {String reason}) =>
    expect('$actual', '$expected', reason: reason);

List<ListChangeRecord> getListChangeRecords(
        List<ListChangeRecord> changes, int index) =>
    new List.from(changes.where((ListChangeRecord c) => c.indexChanged(index)));

List<PropertyChangeRecord> getPropertyChangeRecords(
        List<ChangeRecord> changes, Symbol property) =>
    new List.from(changes.where(
        (ChangeRecord c) => c is PropertyChangeRecord && c.name == property));
