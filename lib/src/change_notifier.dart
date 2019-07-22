import 'dart:async';

import 'package:meta/meta.dart';

import 'internal.dart';
import 'observable.dart';
import 'records.dart';

/// Supplies [changes] and various hooks to implement [Observable].
///
/// May use [notifyChange] to queue a change record; they are asynchronously
/// delivered at the end of the VM turn.
///
/// [ChangeNotifier] may be extended, mixed in, or used as a delegate.
class ChangeNotifier<C extends ChangeRecord> implements Observable<C> {
  StreamController<List<C>> _changes;

  bool _scheduled = false;
  List<C> _queue;

  /// Emits a list of changes when the state of the object changes.
  ///
  /// Changes should produced in order, if significant.
  @override
  Stream<List<C>> get changes {
    return (_changes ??= StreamController<List<C>>.broadcast(
      sync: true,
      onListen: observed,
      onCancel: unobserved,
    ))
        .stream;
  }

  /// May override to be notified when [changes] is first observed.
  @override
  @protected
  @mustCallSuper
  void observed() {}

  /// May override to be notified when [changes] is no longer observed.
  @override
  @protected
  @mustCallSuper
  void unobserved() {
    _changes = _queue = null;
  }

  /// If [hasObservers], synchronously emits [changes] that have been queued.
  ///
  /// Returns `true` if changes were emitted.
  @override
  @mustCallSuper
  bool deliverChanges() {
    if (_scheduled && hasObservers) {
      final changes = _queue == null
          ? ChangeRecords<C>.any()
          : ChangeRecords.wrap(freezeInDevMode(_queue));
      _queue = null;
      _scheduled = false;
      _changes.add(changes);
      return true;
    }
    return false;
  }

  /// Whether [changes] has at least one active listener.
  ///
  /// May be used to optimize whether to produce change records.
  @override
  bool get hasObservers => _changes?.hasListener == true;

  /// Schedules [change] to be delivered.
  ///
  /// If [change] is omitted then [ChangeRecord.ANY] will be sent.
  ///
  /// If there are no listeners to [changes], this method does nothing.
  @override
  void notifyChange([C change]) {
    if (!hasObservers) {
      return;
    }
    if (change != null) {
      (_queue ??= <C>[]).add(change);
    }
    if (!_scheduled) {
      scheduleMicrotask(deliverChanges);
      _scheduled = true;
    }
  }

  @Deprecated('Exists to make migrations off Observable easier')
  @override
  @protected
  T notifyPropertyChange<T>(
    Symbol field,
    T oldValue,
    T newValue,
  ) {
    throw UnsupportedError('Not supported by ChangeNotifier');
  }
}

/// Supplies property `changes` and various hooks to implement [Observable].
///
/// May use `notifyChange` or `notifyPropertyChange` to queue a property change
/// record; they are asynchronously delivered at the end of the VM turn.
///
/// [PropertyChangeNotifier] may be extended or used as a delegate. To use as
/// a mixin, instead use with [PropertyChangeMixin]:
///     with ChangeNotifier<PropertyChangeRecord>, PropertyChangeMixin
class PropertyChangeNotifier extends ChangeNotifier {
  @override
  T notifyPropertyChange<T>(
    Symbol field,
    T oldValue,
    T newValue,
  ) {
    if (hasObservers && oldValue != newValue) {
      notifyChange(
        PropertyChangeRecord<T>(
          this,
          field,
          oldValue,
          newValue,
        ),
      );
    }
    return newValue;
  }
}
