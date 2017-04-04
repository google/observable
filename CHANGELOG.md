## 0.20.4+1

* Support the latest release of `pkg/quiver`.

## 0.20.4

* Bug fix: Additional fix around `ObservableList.listChanges`

## 0.20.3

* Bug fix: Avoid emitting an empty list via `ObservableList.listChanges`

## 0.20.2

* Bug fix: Avoid emitting a no-op `MapChangeRecord`
* Bug fix: Restore `ObservableList.discardListChanges` functionality

## 0.20.1

* Add `Observable<List|Set|Map>.unmodifiable` for immutable collections
* Add `Observable<List|Set|Map>.EMPTY` for empty immutable collections
    * This can be used as an optimization for libraries that always
      need to return an observable collection, but don't want to
      allocate a new instance to represent an empty immutable.

## 0.20.0

* Add `ObservableSet`, `SetChangeRecord`, and `SetDiffer`

## 0.19.0

* Refactor and deprecate `ObservableMap`-specific API
    * `ObservableMap` no longer emits `#keys` and `#values` change records
    * `ObservableMap.spy` is deprecated, becomes `.delegate` instead
* Potentially breaking: `ObservableMap` may no longer be extended

It is also considered deprecated to be notified of `length` changes.

## 0.18.1

* Bug fix: Do not throw when `Observable<T>.notifyChange` is used

## 0.18.0

* Refactor and deprecate `ObservableList`-specific API
    * `ObservableList.applyChangeRecords`
    * `ObservableList.calculateChangeRecords`
    * `ObservableList.withLength`
    * `ObservableList.deliverListChanges`
    * `ObservableList.discardListChanges`
    * `ObservableList.hasListChanges`
    * `ObservableList.listChanges`
    * `ObservableList.notifyListChange`
* Potentially breaking: `ObservableList` may no longer be extended

It is also considered deprecated to be notified of `length`, `isEmpty`
and `isNotEmpty` `PropertyChangeRecord`s on `ObservableList` - in a
future release `ObservableList.changes` will be
`Stream<List<ListChangeRecord>>`.

## 0.17.0+1

* Revert `PropertyChangeMixin`, which does not work in dart2js

## 0.17.0

This is a larger change with a goal of no runtime changes for current
customers, but in the future `Observable` will [become][issue_10] a very
lightweight interface, i.e.:

```dart
abstract class Observable<C extends ChangeRecord> {
  Stream<List<C>> get changes;
}
```

[issue_10]: https://github.com/dart-lang/observable/issues/10

* Started deprecating the wide `Observable` interface
    * `ChangeNotifier` should be used as a base class for these methods:
        * `Observable.observed`
        * `Observable.unobserved`
        * `Observable.hasObservers`
        * `Observable.deliverChanges`
        * `Observable.notifyChange`
    * `PropertyChangeNotifier` should be used for these methods:
        * `Observable.notifyPropertyChange`
    * Temporarily, `Observable` _uses_ `ChangeNotifier`
        * Existing users of anything but `implements Observable` should
          move to implementing or extending `ChangeNotifier`. In a
          future release `Observable` will reduce API surface down to
          an abstract `Stream<List<C>> get changes`.
* Added the `ChangeNotifier` and `PropertyChangeNotifier` classes
    * Can be used to implement `Observable` in a generic manner
* Observable is now `Observable<C extends ChangeRecord>`
    * When passing a generic type `C`, `notifyPropertyChange` is illegal

## 0.16.0

* Refactored `MapChangeRecord`
    * Added equality and hashCode checks
    * Added `MapChangeRecord.apply` to apply a change record
* Added `MapDiffer`, which implements `Differ` for a `Map`

## 0.15.0+2

* Fix a bug in `ListDiffer` that caused a `RangeError`

## 0.15.0+1

* Fix analysis errors caused via missing `/*<E>*/` syntax in `0.15.0`

## 0.15.0

* Added the `Differ` interface, as well as `EqualityDiffer`
* Refactored list diffing into a `ListDiffer`
* Added concept of `ChangeRecord.ANY` and `ChangeRecord.NONE`
    * Low-GC ways to expression "something/nothing" changed
* Refactored `ListChangeRecord`
    * Added named constructors for common use cases
    * Added equality and hashCode checks
    * Added `ListChangeRecord.apply` to apply a change record
* Added missing `@override` annotations to satisfy `annotate_overrides`

## 0.14.0+1

* Add a missing dependency on `pkg/meta`.
