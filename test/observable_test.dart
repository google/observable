// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observable/observable.dart';
import 'package:test/test.dart';

import 'observable_test_utils.dart';

void main() => observableTests();

void observableTests() {
  // Track the subscriptions so we can clean them up in tearDown.
  List subs;

  setUp(() {
    subs = [];
  });

  tearDown(() {
    for (var sub in subs) {
      sub.cancel();
    }
  });

  test('handle future result', () {
    var callback = expectAsync0(() {});
    return Future(callback);
  });

  test('no observers', () {
    var t = createModel(123);
    expect(t.value, 123);
    t.value = 42;
    expect(t.value, 42);
    expect(t.hasObservers, false);
  });

  test('listen adds an observer', () {
    var t = createModel(123);
    expect(t.hasObservers, false);

    subs.add(t.changes.listen((n) {}));
    expect(t.hasObservers, true);
  });

  test('changes delived async', () {
    var t = createModel(123);
    var called = 0;

    subs.add(t.changes.listen(expectAsync1((records) {
      called++;
      expectPropertyChanges(records, 2);
    })));

    t.value = 41;
    t.value = 42;
    expect(called, 0);
  });

  test('cause changes in handler', () {
    var t = createModel(123);
    var called = 0;

    subs.add(t.changes.listen(expectAsync1((records) {
      called++;
      expectPropertyChanges(records, 1);
      if (called == 1) {
        // Cause another change
        t.value = 777;
      }
    }, count: 2)));

    t.value = 42;
  });

  test('multiple observers', () {
    var t = createModel(123);

    void verifyRecords(records) {
      expectPropertyChanges(records, 2);
    }

    subs.add(t.changes.listen(expectAsync1(verifyRecords)));
    subs.add(t.changes.listen(expectAsync1(verifyRecords)));

    t.value = 41;
    t.value = 42;
  });

  test('async processing model', () {
    var t = createModel(123);
    var records = [];
    subs.add(t.changes.listen((r) {
      records.addAll(r);
    }));
    t.value = 41;
    t.value = 42;
    expect(records, [], reason: 'changes delived async');

    return Future(() {
      expectPropertyChanges(records, 2);
      records.clear();

      t.value = 777;
      expect(records, [], reason: 'changes delived async');
    }).then(newMicrotask).then((_) {
      expectPropertyChanges(records, 1);
    });
  });

  test('cancel listening', () {
    var t = createModel(123);
    var sub;
    sub = t.changes.listen(expectAsync1((records) {
      expectPropertyChanges(records, 1);
      sub.cancel();
      t.value = 777;
    }));
    t.value = 42;
  });

  test('cancel and reobserve', () {
    var t = createModel(123);
    var sub;
    sub = t.changes.listen(expectAsync1((records) {
      expectPropertyChanges(records, 1);
      sub.cancel();

      scheduleMicrotask(() {
        subs.add(t.changes.listen(expectAsync1((records) {
          expectPropertyChanges(records, 1);
        })));
        t.value = 777;
      });
    }));
    t.value = 42;
  });

  test('cannot modify changes list', () {
    var t = createModel(123);
    var records;
    subs.add(t.changes.listen((r) {
      records = r;
    }));
    t.value = 42;

    return Future(() {
      expectPropertyChanges(records, 1);

      // Verify that mutation operations on the list fail:

      expect(() {
        records[0] = PropertyChangeRecord(t, #value, 0, 1);
      }, throwsUnsupportedError);

      expect(() {
        records.clear();
      }, throwsUnsupportedError);

      expect(() {
        records.length = 0;
      }, throwsUnsupportedError);
    });
  });

  test('notifyChange', () {
    var t = createModel(123);
    var records = [];
    subs.add(t.changes.listen((r) {
      records.addAll(r);
    }));
    t.notifyChange(PropertyChangeRecord(t, #value, 123, 42));

    return Future(() {
      expectPropertyChanges(records, 1);
      expect(t.value, 123, reason: 'value did not actually change.');
    });
  });

  test('notifyPropertyChange', () {
    var t = createModel(123);
    var records;
    subs.add(t.changes.listen((r) {
      records = r;
    }));
    expect(t.notifyPropertyChange(#value, t.value, 42), 42,
        reason: 'notifyPropertyChange returns newValue');

    return Future(() {
      expectPropertyChanges(records, 1);
      expect(t.value, 123, reason: 'value did not actually change.');
    });
  });
}

void expectPropertyChanges(records, int number) {
  expect(records.length, number, reason: 'expected $number change records');
  for (var record in records) {
    expect(record is PropertyChangeRecord, true,
        reason: 'record should be PropertyChangeRecord');
    expect((record as PropertyChangeRecord).name, #value,
        reason: 'record should indicate a change to the "value" property');
  }
}

ObservableSubclass createModel(int number) => ObservableSubclass(number);

class ObservableSubclass<T> extends PropertyChangeNotifier {
  ObservableSubclass([T initialValue]) : _value = initialValue;

  T get value => _value;
  set value(T newValue) {
    var oldValue = _value;
    _value = newValue;
    notifyPropertyChange(#value, oldValue, newValue);
  }

  T _value;

  @override
  String toString() => '#<$runtimeType value: $value>';
}
