import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:observable/observable.dart';

/// A [Map] that broadcasts [changes] to subscribers for efficient mutations.
///
/// When client code expects a read heavy/write light workload, it is often more
/// efficient to notify _when_ something has changed, instead of constantly
/// diffing lists to find a single change (like an updated key-value). You may
/// accept an observable map to be notified of mutations:
///     ```
///     set grades(Map<String, int> grades) {
///       buildBook(grades);
///       if (names is ObservableMap<String>, int) {
///         grades.changes.listen(updateBook);
///       }
///     }
///     ```
///
/// *See [MapDiffer] to manually diff two lists instead*
abstract class ObservableMap<K, V> implements Map<K, V>, Observable {
  /// Creates a new observable map.
  factory ObservableMap() {
    return new _ObservableDelegatingMap(new HashMap<K, V>());
  }

  /// Like [ObservableMap.from], but creates an empty type.
  factory ObservableMap.createFromType(Map<K, V> other) {
    ObservableMap<K, V> result;
    if (other is LinkedHashMap) {
      result = new ObservableMap<K, V>.linked();
    } else if (other is SplayTreeMap) {
      result = new ObservableMap<K, V>.sorted();
    } else {
      result = new ObservableMap<K, V>();
    }
    return result;
  }

  /// Create a new observable map using [map] as a backing store.
  factory ObservableMap.delegate(Map<K, V> map) {
    return new _ObservableDelegatingMap<K, V>(map);
  }

  /// Creates a new observable map that contains all entries in [other].
  ///
  /// It will attempt to use the same backing map if the other map is either a
  /// [LinkedHashMap], [SplayTreeMap], or [HashMap]. Otherwise it will fall
  /// back to using a [HashMap].
  factory ObservableMap.from(Map<K, V> other) {
    return new ObservableMap<K, V>.createFromType(other)..addAll(other);
  }

  /// Creates a new observable map using a [LinkedHashMap].
  factory ObservableMap.linked() {
    return new _ObservableDelegatingMap<K, V>(new LinkedHashMap<K, V>());
  }

  /// Creates a new observable map using a [SplayTreeMap].
  factory ObservableMap.sorted() {
    return new _ObservableDelegatingMap<K, V>(new SplayTreeMap<K, V>());
  }

  /// Creates a new observable map wrapping [other].
  @Deprecated('Use ObservableMap.delegate for API consistency')
  factory ObservableMap.spy(Map<K, V> other) = ObservableMap<K, V>.delegate;
}

class _ObservableDelegatingMap<K, V> extends DelegatingMap<K, V>
    implements ObservableMap<K, V> {
  final _allChanges = new ChangeNotifier();

  _ObservableDelegatingMap(Map<K, V> map) : super(map);

  // Observable

  @override
  Stream<List<ChangeRecord>> get changes => _allChanges.changes;

  // ChangeNotifier (deprecated for ObservableMap)

  @override
  bool deliverChanges() => _allChanges.deliverChanges();

  @override
  bool get hasObservers => _allChanges.hasObservers;

  @override
  void notifyChange([ChangeRecord change]) {
    _allChanges.notifyChange(change);
  }

  @override
  /*=T*/ notifyPropertyChange/*<T>*/(
    Symbol field,
    /*=T*/
    oldValue,
    /*=T*/
    newValue,
  ) {
    if (oldValue != newValue) {
      _allChanges.notifyChange(
        new PropertyChangeRecord/*<T>*/(this, field, oldValue, newValue),
      );
    }
    return newValue;
  }

  @override
  void observed() {}

  @override
  void unobserved() {}

  @override
  operator []=(K key, V newValue) {
    if (!hasObservers) {
      super[key] = newValue;
      return;
    }

    final oldLength = super.length;
    V oldValue = super[key];
    super[key] = newValue;

    if (oldLength != length) {
      notifyPropertyChange(#length, oldLength, length);
      notifyChange(new MapChangeRecord<K, V>.insert(key, newValue));
    } else {
      notifyChange(new MapChangeRecord<K, V>(key, oldValue, newValue));
    }
  }

  @override
  void addAll(Map<K, V> other) {
    if (!hasObservers) {
      super.addAll(other);
      return;
    }

    other.forEach((k, v) => this[k] = v);
  }

  @override
  V putIfAbsent(K key, V ifAbsent()) {
    final oldLength = length;
    final result = super.putIfAbsent(key, ifAbsent);
    if (hasObservers && oldLength != length) {
      notifyPropertyChange(#length, oldLength, length);
      notifyChange(new MapChangeRecord<K, V>.insert(key, result));
    }
    return result;
  }

  @override
  V remove(Object key) {
    final oldLength = length;
    final result = super.remove(key);
    if (hasObservers && oldLength != length) {
      notifyChange(new MapChangeRecord<K, V>.remove(key as K, result));
      notifyPropertyChange(#length, oldLength, length);
    }
    return result;
  }

  @override
  void clear() {
    if (!hasObservers || isEmpty) {
      super.clear();
      return;
    }
    final oldLength = length;
    forEach((k, v) {
      notifyChange(new MapChangeRecord<K, V>.remove(k, v));
    });
    notifyPropertyChange(#length, oldLength, 0);
    super.clear();
  }
}
