import 'package:observable/observable.dart';
import 'package:test/test.dart';

void main() {
  group('$MapDiffer', () {
    final diff = const MapDiffer<String, String>().diff;

    test('should emit no changes for identical maps', () {
      final map = Map<String, String>.fromIterable(
        Iterable.generate(10, (i) => '$i'),
      );
      expect(diff(map, map), isEmpty);
    });

    test('should emit no changes for maps with identical content', () {
      final map1 = Map<String, String>.fromIterable(
        Iterable.generate(10, (i) => '$i'),
      );
      final map2 = Map<String, String>.fromIterable(
        Iterable.generate(10, (i) => '$i'),
      );
      expect(diff(map1, map2), isEmpty);
    });

    test('should detect insertions', () {
      expect(
        diff({
          'key-a': 'value-a',
          'key-b': 'value-b',
        }, {
          'key-a': 'value-a',
          'key-b': 'value-b',
          'key-c': 'value-c',
        }),
        [
          MapChangeRecord.insert('key-c', 'value-c'),
        ],
      );
    });

    test('should detect removals', () {
      expect(
        diff({
          'key-a': 'value-a',
          'key-b': 'value-b',
          'key-c': 'value-c',
        }, {
          'key-a': 'value-a',
          'key-b': 'value-b',
        }),
        [
          MapChangeRecord.remove('key-c', 'value-c'),
        ],
      );
    });

    test('should detect updates', () {
      expect(
        diff({
          'key-a': 'value-a',
          'key-b': 'value-b-old',
        }, {
          'key-a': 'value-a',
          'key-b': 'value-b-new',
        }),
        [
          MapChangeRecord('key-b', 'value-b-old', 'value-b-new'),
        ],
      );
    });
  });

  group('$MapChangeRecord', () {
    test('should reply an insertion', () {
      final map1 = {
        'key-a': 'value-a',
        'key-b': 'value-b',
      };
      final map2 = {
        'key-a': 'value-a',
        'key-b': 'value-b',
        'key-c': 'value-c',
      };
      MapChangeRecord.insert('key-c', 'value-c').apply(map1);
      expect(map1, map2);
    });

    test('should replay a removal', () {
      final map1 = {
        'key-a': 'value-a',
        'key-b': 'value-b',
        'key-c': 'value-c',
      };
      final map2 = {
        'key-a': 'value-a',
        'key-b': 'value-b',
      };
      MapChangeRecord.remove('key-c', 'value-c').apply(map1);
      expect(map1, map2);
    });

    test('should replay an update', () {
      final map1 = {
        'key-a': 'value-a',
        'key-b': 'value-b-old',
      };
      final map2 = {
        'key-a': 'value-a',
        'key-b': 'value-b-new',
      };
      MapChangeRecord('key-b', 'value-b-old', 'value-b-new').apply(map1);
      expect(map1, map2);
    });
  });
}
