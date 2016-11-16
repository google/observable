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
