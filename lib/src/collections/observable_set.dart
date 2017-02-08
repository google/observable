// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:observable/observable.dart';

/// A [Set] that broadcasts [changes] to subscribers for efficient mutations.
///
/// When client code expects a read heavy/write light workload, it is often more
/// efficient to notify _when_ something has changed, instead of constantly
/// diffing lists to find a single change (like an inserted element). You may
/// accept an observable set to be notified of mutations:
/// ```
/// set emails(Set<String> emails) {
///   emailUsers(emails);
///   if (names is ObservableSet<String>) {
///     emails.changes.listen(updateEmailList);
///   }
/// }
/// ```
///
/// *See [SetDiffer] to manually diff two lists instead*
abstract class ObservableSet<E>
    implements Observable<SetChangeRecord<E>>, Set<E> {
  /// An empty observable set that never has changes.
  static const ObservableSet EMPTY = const _UnmodifiableObservableSet(
    const _UnmodifiableEmptySet(),
  );

  /// Create a new empty observable set.
  factory ObservableSet() => new _DelegatingObservableSet<E>(new HashSet<E>());

  /// Like [ObservableSet.from], but creates a new empty set.
  factory ObservableSet.createFromType(Iterable<E> other) {
    ObservableSet<E> result;
    if (other is LinkedHashSet) {
      result = new _DelegatingObservableSet<E>(new LinkedHashSet<E>());
    } else if (result is SplayTreeSet) {
      result = new _DelegatingObservableSet<E>(new SplayTreeSet<E>());
    } else {
      result = new _DelegatingObservableSet<E>(new HashSet<E>());
    }
    return result;
  }

  /// Create a new observable set using [set] as a backing store.
  factory ObservableSet.delegate(Set<E> set) = _DelegatingObservableSet<E>;

  /// Creates a new observable set that contains all elements in [other].
  ///
  /// It will attempt to use the same backing set type if the other set is
  /// either a [LinkedHashSet], [SplayTreeSet], or [HashSet]. Otherwise it will
  /// fall back to using a [HashSet].
  factory ObservableSet.from(Iterable<E> other) {
    return new ObservableSet<E>.createFromType(other)..addAll(other);
  }

  /// Creates a new observable map using a [LinkedHashSet].
  factory ObservableSet.linked() {
    return new _DelegatingObservableSet<E>(new LinkedHashSet<E>());
  }

  /// Creates a new observable map using a [SplayTreeSet].
  factory ObservableSet.sorted() {
    return new _DelegatingObservableSet<E>(new SplayTreeSet<E>());
  }

  /// Create a new unmodifiable set from [set].
  ///
  /// [ObservableSet.changes] always returns an empty stream, and mutating or
  /// adding change records throws an [UnsupportedError].
  factory ObservableSet.unmodifiable(Set<E> set) {
    if (set is! UnmodifiableSetView<E>) {
      set = new UnmodifiableSetView<E>(set);
    }
    return new _UnmodifiableObservableSet(set);
  }
}

class _DelegatingObservableSet<E> extends DelegatingSet<E>
    with ChangeNotifier<SetChangeRecord<E>>
    implements ObservableSet<E> {
  _DelegatingObservableSet(Set<E> set) : super(set);

  @override
  bool add(E value) {
    if (super.add(value)) {
      if (hasObservers) {
        notifyChange(new SetChangeRecord<E>.add(value));
      }
      return true;
    }
    return false;
  }

  @override
  void addAll(Iterable<E> values) {
    values.forEach(add);
  }

  @override
  bool remove(Object value) {
    if (super.remove(value)) {
      if (hasObservers) {
        notifyChange(new SetChangeRecord<E>.remove(value as E));
      }
      return true;
    }
    return false;
  }

  @override
  void removeAll(Iterable<Object> values) {
    values.toList().forEach(remove);
  }

  @override
  void removeWhere(bool test(E value)) {
    removeAll(super.where(test));
  }

  @override
  void retainAll(Iterable<Object> elements) {
    retainWhere(elements.toSet().contains);
  }

  @override
  void retainWhere(bool test(E element)) {
    removeWhere((e) => !test(e));
  }
}

class _UnmodifiableEmptySet<E> extends IterableBase<E> implements Set<E> {
  const _UnmodifiableEmptySet();

  @override
  bool add(E value) => false;

  @override
  void addAll(Iterable<E> elements) {}

  @override
  void clear() {}

  @override
  bool containsAll(Iterable<Object> other) => other.isEmpty;

  @override
  Set<E> difference(Set<Object> other) => other.toSet();

  @override
  Set<E> intersection(Set<Object> other) => this;

  @override
  Iterator<E> get iterator => const <Null>[].iterator;

  @override
  E lookup(Object object) => null;

  @override
  bool remove(Object value) => false;

  @override
  void removeAll(Iterable<Object> elements) {}

  @override
  void removeWhere(bool test(E element)) {}

  @override
  void retainAll(Iterable<Object> elements) {}

  @override
  void retainWhere(bool test(E element)) {}

  @override
  Set<E> union(Set<E> other) => other.toSet();
}

class _UnmodifiableObservableSet<E> extends DelegatingSet<E>
    implements ObservableSet<E> {
  const _UnmodifiableObservableSet(Set<E> set) : super(set);

  @override
  Stream<List<SetChangeRecord<E>>> get changes => const Stream.empty();

  @override
  bool deliverChanges() => false;

  // TODO: implement hasObservers
  @override
  final bool hasObservers = false;

  @override
  void notifyChange([ChangeRecord change]) {
    throw new UnsupportedError('Not modifiable');
  }

  @override
  /*=T*/ notifyPropertyChange/*<T>*/(
    Symbol field,
    /*=T*/
    oldValue,
    /*=T*/
    newValue,
  ) {
    throw new UnsupportedError('Not modifiable');
  }

  @override
  void observed() {}

  @override
  void unobserved() {}
}
