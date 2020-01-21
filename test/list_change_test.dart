// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observable/observable.dart';
import 'package:test/test.dart';

import 'observable_test_utils.dart';

// This file contains code ported from:
// https://github.com/rafaelw/ChangeSummary/blob/master/tests/test.js

void main() => listChangeTests();

// TODO(jmesserly): port or write array fuzzer tests
void listChangeTests() {
  StreamSubscription sub;
  var model;

  tearDown(() {
    sub?.cancel();
    model = null;
  });

  ListChangeRecord<E> _delta<E>(int i, List<E> r, int a,
          {ObservableList<E> typedModel}) =>
      ListChangeRecord(typedModel ?? model, i, removed: r, addedCount: a);

  test('sequential adds', () {
    final model = ObservableList();
    model.add(0);

    List<ListChangeRecord> summary;
    sub = model.listChanges.listen((r) => summary = r);

    model.add(1);
    model.add(2);

    expect(summary, null);
    return Future(() {
      expect(summary, [_delta(1, [], 2, typedModel: model)]);
      expect(summary[0].added, [1, 2]);
      expect(summary[0].removed, []);
    });
  });

  test('List Splice Truncate And Expand With Length', () {
    final model = ObservableList<String>.from(['a', 'b', 'c', 'd', 'e']);

    List<ListChangeRecord<String>> summary;
    sub = model.listChanges.listen((r) => summary = r);

    model.length = 2;
    return Future(() {
      expect(summary, [
        _delta(2, ['c', 'd', 'e'], 0, typedModel: model)
      ]);
      expect(summary[0].added, []);
      expect(summary[0].removed, ['c', 'd', 'e']);
      summary = null;
      model.length = 5;
    }).then(newMicrotask).then((_) {
      expect(summary, [_delta(2, [], 3, typedModel: model)]);
      expect(summary[0].added, [null, null, null]);
      expect(summary[0].removed, []);
    });
  });

  group('List deltas can be applied', () {
    void applyAndCheckDeltas(model, copy, changes) => changes.then((summary) {
          // apply deltas to the copy
          for (ListChangeRecord delta in summary) {
            delta.apply(copy);
          }

          expect('$copy', '$model', reason: 'summary $summary');
        });

    test('Contained', () {
      var model = toObservable(['a', 'b']);
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(1);
      model.insertAll(0, ['c', 'd', 'e']);
      model.removeRange(1, 3);
      model.insert(1, 'f');

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Delete Empty', () {
      var model = toObservable(<dynamic>[1]);
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(0);
      model.insertAll(0, ['a', 'b', 'c']);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Right Non Overlap', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeRange(0, 1);
      model.insert(0, 'e');
      model.removeRange(2, 3);
      model.insertAll(2, ['f', 'g']);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Left Non Overlap', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeRange(3, 4);
      model.insertAll(3, ['f', 'g']);
      model.removeRange(0, 1);
      model.insert(0, 'e');

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Right Adjacent', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeRange(1, 2);
      model.insert(3, 'e');
      model.removeRange(2, 3);
      model.insertAll(0, ['f', 'g']);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Left Adjacent', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeRange(2, 4);
      model.insert(2, 'e');

      model.removeAt(1);
      model.insertAll(1, ['f', 'g']);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Right Overlap', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(1);
      model.insert(1, 'e');
      model.removeAt(1);
      model.insertAll(1, ['f', 'g']);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Left Overlap', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(2);
      model.insertAll(2, ['e', 'f', 'g']);
      // a b [e f g] d
      model.removeRange(1, 3);
      model.insertAll(1, ['h', 'i', 'j']);
      // a [h i j] f g d

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Prefix And Suffix One In', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.insert(0, 'z');
      model.add('z');

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Remove First', () {
      var model = toObservable([16, 15, 15]);
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(0);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Update Remove', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(2);
      model.insertAll(2, ['e', 'f', 'g']); // a b [e f g] d
      model[0] = 'h';
      model.removeAt(1);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Remove Mid List', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      var changes = model.listChanges.first;

      model.removeAt(2);

      return applyAndCheckDeltas(model, copy, changes);
    });
  });

  group('edit distance', () {
    void assertEditDistance(orig, changes, expectedDist) =>
        changes.then((summary) {
          var actualDistance = 0;
          for (var delta in summary) {
            actualDistance += delta.addedCount + delta.removed.length;
          }

          expect(actualDistance, expectedDist);
        });

    test('add items', () {
      var model = toObservable([]);
      var changes = model.listChanges.first;
      model.addAll([1, 2, 3]);
      return assertEditDistance(model, changes, 3);
    });

    test('trunacte and add, sharing a contiguous block', () {
      var model = toObservable(['x', 'x', 'x', 'x', '1', '2', '3']);
      var changes = model.listChanges.first;
      model.length = 0;
      model.addAll(['1', '2', '3', 'y', 'y', 'y', 'y']);
      return assertEditDistance(model, changes, 8);
    });

    test('truncate and add, sharing a discontiguous block', () {
      var model = toObservable(['1', '2', '3', '4', '5']);
      var changes = model.listChanges.first;
      model.length = 0;
      model.addAll(['a', '2', 'y', 'y', '4', '5', 'z', 'z']);
      return assertEditDistance(model, changes, 7);
    });

    test('insert at beginning and end', () {
      var model = toObservable([2, 3, 4]);
      var changes = model.listChanges.first;
      model.insert(0, 5);
      model[2] = 6;
      model.add(7);
      return assertEditDistance(model, changes, 4);
    });
  });
}
