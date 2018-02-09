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
