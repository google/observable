Support for detecting and being notified when an object is mutated.

An observable, simply put, is a continuous stream of events over time.

### What's for

You can use this library to process asynchronous streams of data for logging, data binding or custom changes to them. You can think of it as the former TC39 proposal Object.observe() feature that got deprecated.

### How

There are two general ways to detect changes:

* Listen to `Observable.changes` and be notified when an object changes
* Use `Differ.diff` to determine changes between two objects

### Examples

Operations on Lists:

```dart
import 'package:observable/observable.dart';

void main() {
  // .addAll()
  final list = new ObservableList<String>()
    ..addAll(['a', 'b', 'c']); // ['a', 'b', 'c']

  // .fillRange()
  final list2 = new ObservableList<String>(5)
    ..fillRange(0, 5, 'a'); // ['a', 'a', 'a', 'a', 'a']
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
