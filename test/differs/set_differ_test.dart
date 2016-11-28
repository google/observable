// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observable/observable.dart';
import 'package:test/test.dart';

main() {
  group('$SetDiffer', () {
    final diff = const SetDiffer<String>().diff;

    test('should emit no changes for identical maps', () {
      final set = new Set<String>.from(
        new Iterable.generate(10, (i) => '$i'),
      );
      expect(diff(set, set), ChangeRecord.NONE);
    });

    test('should emit no changes for maps with identical content', () {
      final set1 = new Set<String>.from(
        new Iterable.generate(10, (i) => '$i'),
      );
      final set2 = new Set<String>.from(
        new Iterable.generate(10, (i) => '$i'),
      );
      expect(diff(set1, set2), ChangeRecord.NONE);
    });

    test('should detect insertions', () {
      expect(
        diff(
          new Set<String>.from(['a']),
          new Set<String>.from(['a', 'b']),
        ),
        [
          new SetChangeRecord.add('b'),
        ],
      );
    });

    test('should detect removals', () {
      expect(
        diff(
          new Set<String>.from(['a', 'b']),
          new Set<String>.from(['a']),
        ),
        [
          new SetChangeRecord.remove('b'),
        ],
      );
    });
  });

  group('$SetChangeRecord', () {
    test('should reply an insertion', () {
      final set1 = new Set<String>.from(['a', 'b']);
      final set2 = new Set<String>.from(['a', 'b', 'c']);
      new SetChangeRecord.add('c').apply(set1);
      expect(set1, set2);
    });

    test('should replay a removal', () {
      final set1 = new Set<String>.from(['a', 'b', 'c']);
      final set2 = new Set<String>.from(['a', 'b']);
      new SetChangeRecord.remove('c').apply(set1);
      expect(set1, set2);
    });
  });
}
