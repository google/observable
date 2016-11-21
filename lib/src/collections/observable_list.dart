import 'dart:async';

import 'package:collection/collection.dart';
import 'package:observable/observable.dart';
import 'package:observable/src/differs.dart';

abstract class ObservableList<E> implements List<E>, Observable {
  /// Applies [changes] to [previous] based on the [current] values.
  ///
  /// ## Deprecated
  ///
  /// If you need this functionality, copy it into your own library. The only
  /// known usage is in `package:template_binding` - ill be upgraded before
  /// removing this method.
  @Deprecated('')
  static void applyChangeRecords/*<T>*/(
    List/*<T>*/ previous,
    List/*<T>*/ current,
    List<ListChangeRecord/*<T>*/ > changes,
  ) {
    if (identical(previous, current)) {
      throw new ArgumentError("Can't use same list for previous and current");
    }
    for (final change in changes) {
      final addEnd = change.index + change.addedCount;
      final removeEnd = change.index + change.removed.length;
      final addedItems = current.getRange(change.index, addEnd);
      previous.replaceRange(change.index, removeEnd, addedItems);
    }
  }

  /// Calculates change records between [previous] and [current].
  ///
  /// ## Deprecated
  ///
  /// This was moved into `ListDiffer.diff`.
  @Deprecated('Use `ListDiffer.diff` instead')
  static List<ListChangeRecord/*<T>*/ > calculateChangeRecords/*<T>*/(
    List/*<T>*/ previous,
    List/*<T>*/ current,
  ) {
    return const ListDiffer/*<T>*/().diff(previous, current);
  }

  /// Creates an observable list of the given [length].
  factory ObservableList([int length]) {
    final list = length != null ? new List<E>(length) : <E>[];
    return new _ObservableDelegatingList(list);
  }

  /// Create a new observable list.
  ///
  /// Optionally define a [list] to use as a backing store.
  factory ObservableList.delegate([List<E> list]) {
    return new _ObservableDelegatingList(list ?? <E>[]);
  }

  /// Create a new observable list from [elements].
  factory ObservableList.from(Iterable<E> elements) {
    return new _ObservableDelegatingList(elements.toList());
  }

  /// Creates a new observable list of the given [length].
  @Deprecated('Use the default constructor')
  factory ObservableList.withLength(int length) {
    return new ObservableList<E>(length);
  }

  @Deprecated('No longer supported. Just use deliverChanges')
  bool deliverListChanges();

  @Deprecated('No longer supported')
  void discardListChanges();

  @Deprecated('The `changes` stream emits ListChangeRecord now')
  bool get hasListObservers;

  /// A stream of summarized list changes, delivered asynchronously.
  Stream<List<ListChangeRecord<E>>> get listChanges;

  @Deprecated('Should no longer be used external from ObservableList')
  void notifyListChange(
    int index, {
    List<E> removed: const [],
    int addedCount: 0,
  });
}

class _ObservableDelegatingList<E> extends DelegatingList<E>
    implements ObservableList<E> {
  final _listChanges = new ChangeNotifier<ListChangeRecord<E>>();
  final _propChanges = new ChangeNotifier<PropertyChangeRecord>();

  StreamController<List<ChangeRecord>> _allChanges;

  _ObservableDelegatingList(List<E> store) : super(store);

  // Observable

  @override
  Stream<List<ChangeRecord>> get changes {
    if (_allChanges == null) {
      StreamSubscription listSub;
      StreamSubscription propSub;
      _allChanges = new StreamController<List<ChangeRecord>>.broadcast(
        sync: true,
        onListen: () {
          listSub = _listChanges.changes.listen((records) {
            // We optimize the edit distances of list change records.
            _allChanges.add(projectListSplices(this, records));
          });
          propSub = _propChanges.changes.listen(_allChanges.add);
        },
        onCancel: () {
          listSub.cancel();
          propSub.cancel();
        }
      );
    }
    return _allChanges.stream;
  }

  // ChangeNotifier (deprecated for ObservableList)

  @override
  bool deliverChanges() {
    final deliveredListChanges = _listChanges.deliverChanges();
    final deliveredPropChanges = _propChanges.deliverChanges();
    return deliveredListChanges || deliveredPropChanges;
  }

  @override
  void discardListChanges() {
    // This used to do something, but now we just make it a no-op.
  }

  @override
  bool get hasObservers {
    return _listChanges.hasObservers || _propChanges.hasObservers;
  }

  @override
  void notifyChange([ChangeRecord change]) {
    if (change is ListChangeRecord<E>) {
      _listChanges.notifyChange(change);
    } else if (change is PropertyChangeRecord) {
      _propChanges.notifyChange(change);
    }
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
      _propChanges.notifyChange(
        new PropertyChangeRecord/*<T>*/(this, field, oldValue, newValue),
      );
    }
    return newValue;
  }

  @override
  void observed() {}

  @override
  void unobserved() {}

  // ObservableList (deprecated)

  @override
  bool deliverListChanges() => _listChanges.deliverChanges();

  @override
  bool get hasListObservers => _listChanges.hasObservers;

  @override
  Stream<List<ListChangeRecord<E>>> get listChanges => _listChanges.changes;

  @override
  void notifyListChange(
    int index, {
    List<E> removed: const [],
    int addedCount: 0,
  }) {
    _listChanges.notifyChange(new ListChangeRecord<E>(
      this,
      index,
      removed: removed,
      addedCount: addedCount,
    ));
  }

  void _notifyChangeLength(int oldLength, int newLength) {
    notifyPropertyChange(#length, oldLength, newLength);
    notifyPropertyChange(#isEmpty, oldLength == 0, newLength == 0);
    notifyPropertyChange(#isNotEmpty, oldLength != 0, newLength != 0);
  }

  // List

  @override
  operator []=(int index, E newValue) {
    final oldValue = this[index];
    if (hasObservers && oldValue != newValue) {
      notifyListChange(index, removed: [oldValue], addedCount: 1);
    }
    super[index] = newValue;
  }

  @override
  void add(E value) {
    if (hasObservers) {
      notifyListChange(length, addedCount: 1);
      _notifyChangeLength(length, length + 1);
    }
    super.add(value);
  }

  @override
  void addAll(Iterable<E> values) {
    final oldLength = this.length;
    super.addAll(values);
    final newLength = this.length;
    final addedCount = newLength - oldLength;
    if (hasObservers && addedCount > 0) {
      notifyListChange(oldLength, addedCount: addedCount);
      _notifyChangeLength(oldLength, newLength);
    }
  }

  @override
  void clear() {
    if (hasObservers) {
      notifyListChange(0, removed: toList());
      _notifyChangeLength(length, 0);
    }
    super.clear();
  }

  @override
  void fillRange(int start, int end, [E value]) {
    if (hasObservers) {
      notifyListChange(
        start,
        addedCount: end - start,
        removed: getRange(start, end).toList(),
      );
    }
    super.fillRange(start, end, value);
  }

  @override
  void insert(int index, E element) {
    super.insert(index, element);
    if (hasObservers) {
      notifyListChange(index, addedCount: 1);
      _notifyChangeLength(length - 1, length);
    }
  }

  @override
  void insertAll(int index, Iterable<E> values) {
    final oldLength = this.length;
    super.insertAll(index, values);
    final newLength = this.length;
    final addedCount = newLength - oldLength;
    if (hasObservers && addedCount > 0) {
      notifyListChange(index, addedCount: addedCount);
      _notifyChangeLength(oldLength, newLength);
    }
  }

  @override
  set length(int newLength) {
    final currentLength = this.length;
    if (currentLength == newLength) {
      return;
    }
    if (hasObservers) {
      if (newLength < currentLength) {
        notifyListChange(
          newLength,
          removed: getRange(newLength, currentLength).toList(),
        );
      } else {
        notifyListChange(currentLength, addedCount: newLength - currentLength);
      }
    }
    super.length = newLength;
    if (hasObservers) {
      _notifyChangeLength(currentLength, newLength);
    }
  }

  @override
  bool remove(Object element) {
    if (!hasObservers) {
      return super.remove(element);
    }
    for (var i = 0; i < this.length; i++) {
      if (this[i] == element) {
        removeAt(i);
        return true;
      }
    }
    return false;
  }

  @override
  E removeAt(int index) {
    if (hasObservers) {
      final element = this[index];
      notifyListChange(index, removed: [element]);
      _notifyChangeLength(length, length - 1);
    }
    return super.removeAt(index);
  }

  @override
  E removeLast() {
    final element = super.removeLast();
    if (hasObservers) {
      notifyListChange(length, removed: [element]);
      _notifyChangeLength(length + 1, length);
    }
    return element;
  }

  @override
  void removeRange(int start, int end) {
    final rangeLength = end - start;
    if (hasObservers && rangeLength > 0) {
      final removed = getRange(start, end).toList();
      notifyListChange(start, removed: removed);
      _notifyChangeLength(length, length - removed.length);
    }
    super.removeRange(start, end);
  }

  @override
  void removeWhere(bool test(E element)) {
    // We have to re-implement this if we have observers.
    if (!hasObservers) return super.removeWhere(test);

    // Produce as few change records as possible - if we have multiple removals
    // in a sequence we want to produce a single record instead of a record for
    // every element removed.
    int firstRemovalIndex;

    for (var i = 0; i < length; i++) {
      var element = this[i];
      if (test(element)) {
        if (firstRemovalIndex == null) {
          // This is the first item we've removed for this sequence.
          firstRemovalIndex = i;
        }
      } else if (firstRemovalIndex != null) {
        // We have a previous sequence of removals, but are not removing more.
        removeRange(firstRemovalIndex, i--);
        firstRemovalIndex = null;
      }
    }

    // We have have a pending removal that was never finished.
    if (firstRemovalIndex != null) {
      removeRange(firstRemovalIndex, length);
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    // This could be optimized not to emit two change records but would require
    // code duplication with these methods. Since this is not used extremely
    // often in my experience OK to just defer to these methods.
    removeRange(start, end);
    insertAll(start, newContents);
  }

  @override
  void retainWhere(bool test(E element)) {
    // This should be functionally the opposite of removeWhere.
    removeWhere((E element) => !test(element));
  }

  @override
  void setAll(int index, Iterable<E> elements) {
    if (!hasObservers) {
      super.setAll(index, elements);
      return;
    }
    // Manual invocation of this method is required to get nicer change events.
    var i = index;
    final removed = <E>[];
    for (var e in elements) {
      removed.add(this[i]);
      super[i++] = e;
    }
    if (removed.isNotEmpty) {
      notifyListChange(index, removed: removed, addedCount: removed.length);
    }
  }

  @override
  void setRange(int start, int end, Iterable<E> elements, [int skipCount = 0]) {
    if (!hasObservers) {
      super.setRange(start, end, elements, skipCount);
      return;
    }
    final iterator = elements.skip(skipCount).iterator..moveNext();
    final removed = <E>[];
    for (var i = start; i < end; i++) {
      removed.add(super[i]);
      super[i] = iterator.current;
      iterator.moveNext();
    }
    if (removed.isNotEmpty) {
      notifyListChange(start, removed: removed, addedCount: removed.length);
    }
  }
}
