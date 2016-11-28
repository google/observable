// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observable/observable.dart';
import 'package:test/test.dart';

main() {
  group('$ObservableSet', () {
    group('set api', _runSetTests);
    _runObservableSetTests();
  });
}

_runSetTests() {
  // TODO(matanl): Can we run the Set-API tests from the SDK?
  // Any methods actually implemented by ObservableSet are below, otherwise I am
  // relying on the test suite for DelegatingSet.
  test('add', () {
    final set = new ObservableSet<String>();
    expect(set.add('item'), isTrue);
    expect(set, ['item']);
    expect(set.add('item'), isFalse);
    expect(set, ['item']);
  });

  test('addAll', () {
    final set = new ObservableSet<String>.linked();
    set.addAll(['1', '2', '3']);
    expect(set, ['1', '2', '3']);
    set.addAll(['3', '4']);
    expect(set, ['1', '2', '3', '4']);
  });

  test('remove', () {
    final set = new ObservableSet<String>();
    expect(set.remove('item'), isFalse);
    expect(set, isEmpty);
    set.add('item');
    expect(set, isNotEmpty);
    expect(set.remove('item'), isTrue);
    expect(set, isEmpty);
  });

  test('removeAll', () {
    final set = new ObservableSet<String>.from(['1', '2', '3']);
    set.removeAll(['1', '3']);
    expect(set, ['2']);
  });

  test('removeWhere', () {
    final set = new ObservableSet<String>.from(['1', '2', '3']);
    set.removeWhere((s) => s != '2');
    expect(set, ['2']);
  });

  test('retainAll', () {
    final set = new ObservableSet<String>.from(['1', '2', '3']);
    set.retainAll(['2']);
    expect(set, ['2']);
  });

  test('retainWhere', () {
    final set = new ObservableSet<String>.from(['1', '2', '3']);
    set.retainWhere((s) => s == '2');
    expect(set, ['2']);
  });
}

_runObservableSetTests() {
  group('observable changes', () {
    Completer<List<SetChangeRecord>> completer;
    Set<String> previousState;

    ObservableSet<String> set;
    StreamSubscription sub;

    Future next() {
      completer = new Completer<List<SetChangeRecord>>.sync();
      return completer.future;
    }

    Future<Null> expectChanges(List<SetChangeRecord> changes) {
      // Applying these change records in order should make the new list.
      for (final change in changes) {
        change.apply(previousState);
      }

      expect(set, previousState);

      // If these fail, it might be safe to update if optimized/changed.
      return next().then((actualChanges) {
        for (final change in changes) {
          expect(actualChanges, contains(change));
        }
      });
    }

    setUp(() {
      set = new ObservableSet.from(['a', 'b', 'c']);
      previousState = set.toSet();
      sub = set.changes.listen((c) {
        if (completer?.isCompleted == false) {
          completer.complete(c);
        }
        previousState = set.toSet();
      });
    });

    tearDown(() => sub.cancel());

    test('add', () async {
      set.add('value');
      await expectChanges([
        new SetChangeRecord.add('value'),
      ]);
    });

    test('addAll', () async {
      set.addAll(['1', '2']);
      await expectChanges([
        new SetChangeRecord.add('1'),
        new SetChangeRecord.add('2'),
      ]);
    });

    test('remove', () async {
      set.remove('a');
      await expectChanges([
        new SetChangeRecord.remove('a'),
      ]);
    });

    Future expectOnlyItem() {
      return expectChanges([
        new SetChangeRecord.remove('a'),
        new SetChangeRecord.remove('c'),
      ]);
    }

    test('removeAll', () async {
      set.removeAll(['a', 'c']);
      await expectOnlyItem();
    });

    test('removeWhere', () async {
      set.removeWhere((s) => s != 'b');
      await expectOnlyItem();
    });

    test('retainAll', () async {
      set.retainAll(['b']);
      await expectOnlyItem();
    });

    test('retainWhere', () async {
      set.retainWhere((s) => s == 'b');
      await expectOnlyItem();
    });
  });
}
