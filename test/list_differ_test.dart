import 'package:observable/observable.dart';
import 'package:test/test.dart';

void main() {
  group('$ListDiffer', () {
    final diff = const ListDiffer<String>().diff;

    test('should emit no changes for identical lists', () {
      final list = List<String>.generate(10, (i) => '$i');
      expect(diff(list, list), isEmpty);
    });

    test('should emit no changes for lists with identical content', () {
      final list1 = List<String>.generate(10, (i) => '$i');
      final list2 = List<String>.generate(10, (i) => '$i');
      expect(diff(list1, list2), isEmpty);
    });

    test('should detect insertions', () {
      final oldList = ['value-a', 'value-b'];
      final newList = ['value-a', 'value-b', 'value-c'];
      expect(
        diff(oldList, newList),
        [
          ListChangeRecord.add(newList, 2, 1),
        ],
      );
    });

    test('should detect removals', () {
      final oldList = ['value-a', 'value-b', 'value-c'];
      final newList = ['value-a', 'value-b'];
      expect(
        diff(oldList, newList),
        [
          ListChangeRecord.remove(newList, 2, ['value-c']),
        ],
      );
    });

    test('should detect updates', () {
      final oldList = ['value-a', 'value-b-old'];
      final newList = ['value-a', 'value-b-new'];
      expect(
        diff(oldList, newList),
        [
          ListChangeRecord(newList, 1, removed: ['value-b-old'], addedCount: 1),
        ],
      );
    });
  });
}
