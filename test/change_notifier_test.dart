import 'dart:async';

import 'package:observable/observable.dart';
import 'package:test/test.dart';

import 'observable_test_utils.dart';

void main() {
  group(ChangeRecords, () {
    test('any changes', () {
      expectChanges(const ChangeRecords<A>.any(), const ChangeRecords<A>.any());
      expectChanges(ChangeRecords<A>.any(), ChangeRecords<A>.any());
      expectNotChanges(ChangeRecords<A>.any(), ChangeRecords<A>.wrap([]));
      expectNotChanges(ChangeRecords<A>.any(), ChangeRecords<B>.any());
      expectNotChanges(ChangeRecords<B>.any(), ChangeRecords<C>.any());
    });

    test('some changes', () {
      expectChanges(ChangeRecords<A>.fromIterable([A()]),
          ChangeRecords<A>.fromIterable([A()]));
      expectChanges(ChangeRecords<A>.fromIterable([B(1), B(2)]),
          ChangeRecords<A>.fromIterable([B(1), B(2)]));
      expectNotChanges(ChangeRecords<A>.fromIterable([A()]),
          ChangeRecords<A>.fromIterable([A(), A()]));
      expectNotChanges(ChangeRecords<B>.fromIterable([B(1)]),
          ChangeRecords<A>.fromIterable([B(2)]));
      expectNotChanges(ChangeRecords<B>.fromIterable([B(1)]),
          ChangeRecords<A>.fromIterable([C()]));
    });
  });

  group(ChangeNotifier, () {
    Future<void> runTest<T extends ChangeRecord>(
        FutureOr<void> Function(ChangeNotifier<T> cn) runFn,
        FutureOr<void> Function(ChangeRecords<T> cr) testFn) async {
      final cn = ChangeNotifier<T>();

      cn.changes.listen((value) {
        expect(value, TypeMatcher<ChangeRecords<T>>());
        testFn(value);
      });

      await runFn(cn);

      return Future(() {});
    }

    test(
        'delivers any record when no change notified',
        () => runTest<A>((cn) {
              cn.notifyChange();
            }, (cr) {
              expectChanges(cr, ChangeRecords<A>.any());
            }));

    test(
        'delivers expectChangesed changes',
        () => runTest<B>((cn) {
              cn..notifyChange(B(1))..notifyChange(B(2))..notifyChange(B(3));
            }, (cr) {
              expectChanges(cr, ChangeRecords<B>.wrap([B(1), B(2), B(3)]));
            }));
  });
}

class A extends ChangeRecord {
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is A && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}

class B extends A {
  final int value;

  B(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is B &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class C extends A {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other && other is C && runtimeType == other.runtimeType;

  @override
  int get hashCode => 2;
}
