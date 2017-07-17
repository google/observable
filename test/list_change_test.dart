// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observable/observable.dart';
import 'package:test/test.dart';

import 'observable_test_utils.dart';

// This file contains code ported from:
// https://github.com/rafaelw/ChangeSummary/blob/master/tests/test.js

// TODO(jmesserly): port or write array fuzzer tests
void main() {
  StreamSubscription sub;
  ObservableList model;

  tearDown(() async {
    await sub?.cancel();
    model = null;
  });

  _delta(int i, List r, int a) =>
      new ListChangeRecord(model, i, removed: r, addedCount: a);

  test('sequential adds', () async {
    model = toObservable([]) as ObservableList;
    model.add(0);

    var summary;
    sub = model.listChanges.listen((r) => summary = r);

    model.add(1);
    model.add(2);

    expect(summary, null);
    await newMicrotask();
    expectChanges(summary, [_delta(1, [], 2)]);
  });

  test('List Splice Truncate And Expand With Length', () async {
    model = toObservable(['a', 'b', 'c', 'd', 'e']) as ObservableList;

    var summary;
    sub = model.listChanges.listen((r) => summary = r);

    model.length = 2;

    await newMicrotask();
    expectChanges(summary, [
      _delta(2, ['c', 'd', 'e'], 0)
    ]);
    summary = null;
    model.length = 5;

    await newMicrotask();

    expectChanges(summary, [_delta(2, [], 3)]);
  });

  group('List deltas can be applied', () {
    Future applyAndCheckDeltas(model, List copy, Future changes) async {
      var summary = await changes;
      // apply deltas to the copy
      for (ListChangeRecord delta in summary) {
        delta.apply(copy);
      }

      expect('$copy', '$model', reason: 'summary $summary');
    }

    test('Contained', () async {
      var model = toObservable(['a', 'b']) as ObservableList;
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(1);
      model.insertAll(0, ['c', 'd', 'e']);
      model.removeRange(1, 3);
      model.insert(1, 'f');

      await applyAndCheckDeltas(model, copy, changes);
    });

    test('Delete Empty', () async {
      var model = toObservable([1]) as ObservableList;
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(0);
      model.insertAll(0, ['a', 'b', 'c']);

      await applyAndCheckDeltas(model, copy, changes);
    });

    test('Right Non Overlap', () async {
      var model = toObservable(['a', 'b', 'c', 'd']) as ObservableList;
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeRange(0, 1);
      model.insert(0, 'e');
      model.removeRange(2, 3);
      model.insertAll(2, ['f', 'g']);

      await applyAndCheckDeltas(model, copy, changes);
    });

    test('Left Non Overlap', () async {
      var model = toObservable(['a', 'b', 'c', 'd']) as ObservableList;
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeRange(3, 4);
      model.insertAll(3, ['f', 'g']);
      model.removeRange(0, 1);
      model.insert(0, 'e');

      await applyAndCheckDeltas(model, copy, changes);
    });

    test('Right Adjacent', () async {
      var model = toObservable(['a', 'b', 'c', 'd']) as ObservableList;
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeRange(1, 2);
      model.insert(3, 'e');
      model.removeRange(2, 3);
      model.insertAll(0, ['f', 'g']);

      await applyAndCheckDeltas(model, copy, changes);
    });

    test('Left Adjacent', () async {
      var model = toObservable(['a', 'b', 'c', 'd']) as ObservableList;
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeRange(2, 4);
      model.insert(2, 'e');

      model.removeAt(1);
      model.insertAll(1, ['f', 'g']);

      await applyAndCheckDeltas(model, copy, changes);
    });

    test('Right Overlap', () async {
      var model = toObservable(['a', 'b', 'c', 'd']) as ObservableList;
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(1);
      model.insert(1, 'e');
      model.removeAt(1);
      model.insertAll(1, ['f', 'g']);

      await applyAndCheckDeltas(model, copy, changes);
    });

    test('Left Overlap', () async {
      var model = toObservable(['a', 'b', 'c', 'd']) as ObservableList;
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(2);
      model.insertAll(2, ['e', 'f', 'g']);
      // a b [e f g] d
      model.removeRange(1, 3);
      model.insertAll(1, ['h', 'i', 'j']);
      // a [h i j] f g d

      await applyAndCheckDeltas(model, copy, changes);
    });

    test('Prefix And Suffix One In', () async {
      var model = toObservable(['a', 'b', 'c', 'd']) as ObservableList;
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.insert(0, 'z');
      model.add('z');

      await applyAndCheckDeltas(model, copy, changes);
    });

    test('Remove First', () async {
      var model = toObservable([16, 15, 15]) as ObservableList;
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(0);

      await applyAndCheckDeltas(model, copy, changes);
    });

    test('Update Remove', () async {
      var model = toObservable(['a', 'b', 'c', 'd']) as ObservableList;
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(2);
      model.insertAll(2, ['e', 'f', 'g']); // a b [e f g] d
      model[0] = 'h';
      model.removeAt(1);

      await applyAndCheckDeltas(model, copy, changes);
    });

    test('Remove Mid List', () async {
      var model = toObservable(['a', 'b', 'c', 'd']) as ObservableList;
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(2);

      await applyAndCheckDeltas(model, copy, changes);
    });
  });

  group('edit distance', () {
    Future assertEditDistance(
        orig, Future<List<ListChangeRecord>> changes, expectedDist) async {
      var summary = await changes;
      var actualDistance = 0;
      for (var delta in summary) {
        actualDistance += delta.addedCount + delta.removed.length;
      }

      expect(actualDistance, expectedDist);
    }

    test('add items', () async {
      var model = toObservable([]) as ObservableList;
      var changes = model.listChanges.first;
      model.addAll([1, 2, 3]);
      await assertEditDistance(model, changes, 3);
    });

    test('trunacte and add, sharing a contiguous block', () async {
      var model =
          toObservable(['x', 'x', 'x', 'x', '1', '2', '3']) as ObservableList;
      var changes = model.listChanges.first;
      model.length = 0;
      model.addAll(['1', '2', '3', 'y', 'y', 'y', 'y']);
      await assertEditDistance(model, changes, 8);
    });

    test('truncate and add, sharing a discontiguous block', () async {
      var model = toObservable(['1', '2', '3', '4', '5']) as ObservableList;
      var changes = model.listChanges.first;
      model.length = 0;
      model.addAll(['a', '2', 'y', 'y', '4', '5', 'z', 'z']);
      await assertEditDistance(model, changes, 7);
    });

    test('insert at beginning and end', () async {
      var model = toObservable([2, 3, 4]) as ObservableList;
      var changes = model.listChanges.first;
      model.insert(0, 5);
      model[2] = 6;
      model.add(7);
      await assertEditDistance(model, changes, 4);
    });
  });
}
