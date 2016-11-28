// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observable/observable.dart';
import 'package:test/test.dart';

main() {
  group('$ObservableList', () {
    group('list api', _runListTests);
    _runObservableListTests();
    _runDeprecatedTests();
  });
}

bool _hasListChanges(List<ChangeRecord> c) {
  return c.any((r) => r is ListChangeRecord);
}

bool _hasPropChanges(List<ChangeRecord> c) {
  return c.any((r) => r is PropertyChangeRecord);
}

bool _onlyListChanges(ChangeRecord c) => c is ListChangeRecord;

bool _onlyPropRecords(ChangeRecord c) => c is PropertyChangeRecord;

_runListTests() {
  // TODO(matanl): Can we run the List-API tests from the SDK?
  // Any methods actually implemented by ObservableList are below, otherwise I
  // am relying on the test suite for DelegatingList.
  test('index set operator', () {
    final list = new ObservableList<String>(1)..[0] = 'value';
    expect(list, ['value']);
  });

  test('add', () {
    final list = new ObservableList<String>()..add('value');
    expect(list, ['value']);
  });

  test('addAll', () {
    final list = new ObservableList<String>()..addAll(['a', 'b', 'c']);
    expect(list, ['a', 'b', 'c']);
  });

  test('clear', () {
    final list = new ObservableList<String>.from(['a', 'b', 'c'])..clear();
    expect(list, isEmpty);
  });

  test('fillRange', () {
    final list = new ObservableList<String>(5)..fillRange(0, 5, 'a');
    expect(list, ['a', 'a', 'a', 'a', 'a']);
  });

  test('insert', () {
    final list = new ObservableList<String>.from(['a', 'c'])..insert(1, 'b');
    expect(list, ['a', 'b', 'c']);
  });

  test('insertAll', () {
    final list = new ObservableList<String>.from(['c']);
    list.insertAll(0, ['a', 'b']);
    expect(list, ['a', 'b', 'c']);
  });

  test('length', () {
    final list = new ObservableList<String>()..length = 3;
    expect(list, [null, null, null]);
    list.length = 1;
    expect(list, [null]);
    list.length = 0;
    expect(list, isEmpty);
  });

  test('remove', () {
    final list = new ObservableList<String>.from(['a', 'b', 'c']);
    expect(list.remove('b'), isTrue);
    expect(list, ['a', 'c']);
  });

  test('removeAt', () {
    final list = new ObservableList<String>.from(['a', 'b', 'c']);
    expect(list.removeAt(1), 'b');
    expect(list, ['a', 'c']);
  });

  test('removeLast', () {
    final list = new ObservableList<String>.from(['a', 'b', 'c']);
    expect(list.removeLast(), 'c');
  });

  test('removeRange', () {
    final list = new ObservableList<String>.from(['a', 'b', 'c']);
    list.removeRange(0, 2);
    expect(list, ['c']);
  });

  test('removeWhere', () {
    final list = new ObservableList<String>.from(['a', 'b', 'a', 'b']);
    list.removeWhere((v) => v == 'a');
    expect(list, ['b', 'b']);
  });

  test('retainWhere', () {
    final list = new ObservableList<String>.from(['a', 'b', 'a', 'b']);
    list.retainWhere((v) => v == 'a');
    expect(list, ['a', 'a']);
  });

  test('setAll', () {
    final list = new ObservableList<String>.from(['a', 'b', 'c']);
    list.setAll(1, ['d', 'f']);
    expect(list, ['a', 'd', 'f']);
  });

  test('setRange', () {
    final list = new ObservableList<String>.from(['a', 'b', 'c']);
    list.setRange(0, 2, ['d', 'e']);
    expect(list, ['d', 'e', 'c']);
    list.setRange(1, 3, ['f', 'g', 'h'], 1);
    expect(list, ['d', 'g', 'h']);
  });
}

// These are the tests we will keep after deprecations occur.
_runObservableListTests() {
  group('content changes', () {
    Completer<List<ListChangeRecord>> completer;
    List<String> previousState;

    ObservableList<String> list;
    Stream<List<ChangeRecord>> stream;
    StreamSubscription sub;

    Future next() {
      completer = new Completer<List<ListChangeRecord>>.sync();
      return completer.future;
    }

    Future<Null> expectChanges(List<ListChangeRecord> changes) {
      // Applying these change records in order should make the new list.
      for (final change in changes) {
        change.apply(previousState);
      }
      expect(list, previousState);

      // If these fail, it might be safe to update if optimized/changed.
      return next().then((actualChanges) {
        expect(actualChanges, changes);
      });
    }

    setUp(() {
      previousState = ['a', 'b', 'c'];
      list = new ObservableList<String>.from(previousState);
      stream = list.changes.where(_hasListChanges);
      sub = stream.listen((c) {
        if (completer?.isCompleted == false) {
          completer.complete(c.where(_onlyListChanges).toList());
        }
        previousState = list.toList();
      });
    });

    tearDown(() => sub.cancel());

    ListChangeRecord _delta(
      int index, {
      List removed: const [],
      int addedCount: 0,
    }) {
      return new ListChangeRecord(
        list,
        index,
        removed: removed,
        addedCount: addedCount,
      );
    }

    test('operator[]=', () async {
      list[0] = 'd';
      await expectChanges([
        _delta(0, removed: ['a'], addedCount: 1),
      ]);
    });

    test('add', () async {
      list.add('d');
      await expectChanges([
        _delta(3, addedCount: 1),
      ]);
    });

    test('addAll', () async {
      list.addAll(['d', 'e']);
      await expectChanges([
        _delta(3, addedCount: 2),
      ]);
    });

    test('clear', () async {
      list.clear();
      await expectChanges([
        _delta(0, removed: ['a', 'b', 'c']),
      ]);
    });

    test('fillRange', () async {
      list.fillRange(1, 3, 'd');
      await expectChanges([
        _delta(1, removed: ['b', 'c'], addedCount: 2),
      ]);
    });

    test('insert', () async {
      list.insert(1, 'd');
      await expectChanges([
        _delta(1, addedCount: 1),
      ]);
    });

    test('insertAll', () async {
      list.insertAll(1, ['d', 'e']);
      await expectChanges([
        _delta(1, addedCount: 2),
      ]);
    });

    test('length', () async {
      list.length = 5;
      await expectChanges([
        _delta(3, addedCount: 2),
      ]);
      list.length = 1;
      await expectChanges([
        _delta(1, removed: ['b', 'c', null, null])
      ]);
    });

    test('remove', () async {
      list.remove('b');
      await expectChanges([
        _delta(1, removed: ['b'])
      ]);
    });

    test('removeAt', () async {
      list.removeAt(1);
      await expectChanges([
        _delta(1, removed: ['b'])
      ]);
    });

    test('removeRange', () async {
      list.removeRange(0, 2);
      await expectChanges([
        _delta(0, removed: ['a', 'b'])
      ]);
    });

    test('removeWhere', () async {
      list.removeWhere((s) => s == 'b');
      await expectChanges([
        _delta(1, removed: ['b'])
      ]);
    });

    test('replaceRange', () async {
      list.replaceRange(0, 2, ['d', 'e']);
      await expectChanges([
        // Normally would be
        //   _delta(0, removed: ['a', 'b']),
        //   _delta(0, addedCount: 2),
        // But projectListSplices(...) optimizes to single record
        _delta(0, removed: ['a', 'b'], addedCount: 2),
      ]);
    });

    test('retainWhere', () async {
      list.retainWhere((s) => s == 'b');
      await expectChanges([
        _delta(0, removed: ['a']),
        _delta(1, removed: ['c']),
      ]);
    });

    test('setAll', () async {
      list.setAll(1, ['d', 'e']);
      await expectChanges([
        _delta(1, removed: ['b', 'c'], addedCount: 2),
      ]);
    });

    test('setRange', () async {
      list.setRange(0, 2, ['d', 'e']);
      await expectChanges([
        _delta(0, removed: ['a', 'b'], addedCount: 2),
      ]);
      list.setRange(1, 3, ['f', 'g', 'h'], 1);
      await expectChanges([
        _delta(1, removed: ['e', 'c'], addedCount: 2),
      ]);
    });
  });
}

// These are tests we will remove after deprecations occur.
_runDeprecatedTests() {
  group('length changes', () {
    Completer<List<ListChangeRecord>> completer;
    ObservableList<String> list;
    Stream<List<ChangeRecord>> stream;
    StreamSubscription sub;

    Future next() {
      completer = new Completer<List<ListChangeRecord>>.sync();
      return completer.future;
    }

    setUp(() {
      list = new ObservableList<String>.from(['a', 'b', 'c']);
      stream = list.changes.where(_hasPropChanges);
      sub = stream.listen((c) {
        if (completer?.isCompleted == false) {
          completer.complete(c.where(_onlyPropRecords).toList());
        }
      });
    });

    tearDown(() => sub.cancel());

    PropertyChangeRecord _length(int oldLength, int newLength) {
      return new PropertyChangeRecord(list, #length, oldLength, newLength);
    }

    PropertyChangeRecord _isEmpty(bool oldValue, bool newValue) {
      return new PropertyChangeRecord(list, #isEmpty, oldValue, newValue);
    }

    PropertyChangeRecord _isNotEmpty(bool oldValue, bool newValue) {
      return new PropertyChangeRecord(list, #isNotEmpty, oldValue, newValue);
    }

    test('add', () async {
      list.add('d');
      expect(await next(), [
        _length(3, 4),
      ]);
    });

    test('addAll', () async {
      list.addAll(['d', 'e']);
      expect(await next(), [
        _length(3, 5),
      ]);
    });

    test('clear', () async {
      list.clear();
      expect(await next(), [
        _length(3, 0),
        _isEmpty(false, true),
        _isNotEmpty(true, false),
      ]);
    });

    test('insert', () async {
      list.insert(0, 'd');
      expect(await next(), [
        _length(3, 4),
      ]);
    });

    test('insertAll', () async {
      list.insertAll(0, ['d', 'e']);
      expect(await next(), [
        _length(3, 5),
      ]);
    });

    test('length', () async {
      list.length = 5;
      expect(await next(), [
        _length(3, 5),
      ]);

      list.length = 0;
      expect(await next(), [
        _length(5, 0),
        _isEmpty(false, true),
        _isNotEmpty(true, false),
      ]);

      list.length = 1;
      expect(await next(), [
        _length(0, 1),
        _isEmpty(true, false),
        _isNotEmpty(false, true),
      ]);
    });

    test('remove', () async {
      list.remove('a');
      expect(await next(), [
        _length(3, 2),
      ]);
    });

    test('removeAt', () async {
      list.removeAt(0);
      expect(await next(), [
        _length(3, 2),
      ]);
    });

    test('removeLast', () async {
      list.removeLast();
      expect(await next(), [
        _length(3, 2),
      ]);
    });

    test('removeRange', () async {
      list.removeRange(0, 2);
      expect(await next(), [
        _length(3, 1),
      ]);
    });

    test('removeWhere', () async {
      list.removeWhere((s) => s == 'a');
      expect(await next(), [
        _length(3, 2),
      ]);
    });

    test('retainWhere', () async {
      list.retainWhere((s) => s == 'a');
      expect(await next(), [
        _length(3, 1),
      ]);
    });
  });
}
