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
