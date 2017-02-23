[![Build Status](https://travis-ci.org/dart-lang/observable.svg?branch=master)](https://travis-ci.org/dart-lang/observable)

Support for detecting and being notified when an object is mutated.

An observable is a way to be notified of a continuous stream of events over time.

Some suggested uses for this library:

* Observe objects for changes, and log when a change occurs
* Optimize for observable collections in your own APIs and libraries instead of diffing
* Implement simple data-binding by listening to streams

You may want to look at the former TC39 proposal [Observe.observe](https://github.com/tc39/proposal-observable), which was deprecated.

### Usage

There are two general ways to detect changes:

* Listen to `Observable.changes` and be notified when an object changes
* Use `Differ.diff` to determine changes between two objects

### Examples

Operations on Lists:

```dart
import 'package:observable/observable.dart';

void main() {
  var changes;

  ObservableList<String> list = new ObservableList<String>.from(['a', 'b', 'c']);
  StreamSubscription sub = list.listChanges.listen((c) => changes = c);

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

  list.insertAll(1, ['y', 'z']); // changes == [_delta(1, addedCount: 2)]
}
```

Diffing two maps:

```dart
import 'package:observable/observable.dart';

void main() {
  final map1 = {
    'key-a': 'value-a',
    'key-b': 'value-b-old',
  };

  final map2 = {
    'key-a': 'value-a',
    'key-b': 'value-b-new',
  };

  var diffResult = diff(map1,
      map2); // [ new MapChangeRecord('key-b', 'value-b-old', 'value-b-new')]
}
```

Diffing two sets:

```dart
import 'package:observable/observable.dart';

void main() {
  diff(
    new Set<String>.from(['a', 'b']),
    new Set<String>.from(['a']),
  ); // [ new SetChangeRecord.remove('b') ]
}
```
