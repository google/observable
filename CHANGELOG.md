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
