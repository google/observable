// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable.src.differs;

/// Determines differences between two lists, returning [ListChangeRecord]s.
///
/// While [ListChangeRecord] has more information and can be replayed they carry
/// a more significant cost to calculate and create and should only be used when
/// the details in the record will actually be used.
///
/// See also [EqualityDiffer] for a simpler comparison.
class ListDiffer<E> implements Differ<List<E>> {
  final Equality<E> _equality;

  const ListDiffer([this._equality = const DefaultEquality()]);

  @override
  List<ListChangeRecord<E>> diff(List<E> e1, List<E> e2) {
    return _calcSplices<E>(
      e2,
      _equality,
      0,
      e2.length,
      e1,
      0,
      e1.length,
    );
  }
}

enum _Edit {
  leave,
  update,
  add,
  delete,
}

// Note: This function is *based* on the computation of the Levenshtein
// "edit" distance. The one change is that "updates" are treated as two
// edits - not one. With List splices, an update is really a delete
// followed by an add. By retaining this, we optimize for "keeping" the
// maximum array items in the original array. For example:
//
//   'xxxx123' -> '123yyyy'
//
// With 1-edit updates, the shortest path would be just to update all seven
// characters. With 2-edit updates, we delete 4, leave 3, and add 4. This
// leaves the substring '123' intact.
List<List<int>> _calcEditDistance<E>(
  List<E> current,
  int currentStart,
  int currentEnd,
  List<E> old,
  int oldStart,
  int oldEnd,
) {
  // 'Deletion' columns.
  final rowCount = oldEnd - oldStart + 1;
  final columnCount = currentEnd - currentStart + 1;
  final distances = List<List<int>>(rowCount);

  // 'Addition' rows. Initialize null column.
  for (var i = 0; i < rowCount; i++) {
    distances[i] = List<int>(columnCount);
    distances[i][0] = i;
  }

  // Initialize null row.
  for (var j = 0; j < columnCount; j++) {
    distances[0][j] = j;
  }

  for (var i = 1; i < rowCount; i++) {
    for (var j = 1; j < columnCount; j++) {
      if (old[oldStart + i - 1] == current[currentStart + j - 1]) {
        distances[i][j] = distances[i - 1][j - 1];
      } else {
        final north = distances[i - 1][j] + 1;
        final west = distances[i][j - 1] + 1;
        distances[i][j] = math.min(north, west);
      }
    }
  }

  return distances;
}

// This starts at the final weight, and walks "backward" by finding
// the minimum previous weight recursively until the origin of the weight
// matrix.
Iterable<_Edit> _spliceOperationsFromEditDistances(List<List<int>> distances) {
  var i = distances.length - 1;
  var j = distances[0].length - 1;
  var current = distances[i][j];
  final edits = <_Edit>[];
  while (i > 0 || j > 0) {
    if (i == 0) {
      edits.add(_Edit.add);
      j--;
      continue;
    }
    if (j == 0) {
      edits.add(_Edit.delete);
      i--;
      continue;
    }
    final northWest = distances[i - 1][j - 1];
    final west = distances[i - 1][j];
    final north = distances[i][j - 1];

    final min = math.min(math.min(west, north), northWest);
    if (min == northWest) {
      if (northWest == current) {
        edits.add(_Edit.leave);
      } else {
        edits.add(_Edit.update);
        current = northWest;
      }
      i--;
      j--;
    } else if (min == west) {
      edits.add(_Edit.delete);
      i--;
      current = west;
    } else {
      edits.add(_Edit.add);
      j--;
      current = north;
    }
  }

  return edits.reversed;
}

int _sharedPrefix<E>(
  Equality<E> equality,
  List<E> e1,
  List<E> e2,
  int searchLength,
) {
  for (var i = 0; i < searchLength; i++) {
    if (!equality.equals(e1[i], e2[i])) {
      return i;
    }
  }
  return searchLength;
}

int _sharedSuffix<E>(
  Equality<E> equality,
  List<E> e1,
  List<E> e2,
  int searchLength,
) {
  var index1 = e1.length;
  var index2 = e2.length;
  var count = 0;
  while (count < searchLength && equality.equals(e1[--index1], e2[--index2])) {
    count++;
  }
  return count;
}

// Lacking individual splice mutation information, the minimal set of
// splices can be synthesized given the previous state and final state of an
// array. The basic approach is to calculate the edit distance matrix and
// choose the shortest path through it.
//
// Complexity: O(l * p)
//   l: The length of the current array
//   p: The length of the old array
List<ListChangeRecord<E>> _calcSplices<E>(
  List<E> current,
  Equality<E> equality,
  int currentStart,
  int currentEnd,
  List<E> old,
  int oldStart,
  int oldEnd,
) {
  var prefixCount = 0;
  var suffixCount = 0;
  final minLength = math.min(currentEnd - currentStart, oldEnd - oldStart);
  if (currentStart == 0 && oldStart == 0) {
    prefixCount = _sharedPrefix(
      equality,
      current,
      old,
      minLength,
    );
  }
  if (currentEnd == current.length && oldEnd == old.length) {
    suffixCount = _sharedSuffix(
      equality,
      current,
      old,
      minLength - prefixCount,
    );
  }

  currentStart += prefixCount;
  oldStart += prefixCount;
  currentEnd -= suffixCount;
  oldEnd -= suffixCount;

  if (currentEnd - currentStart == 0 && oldEnd - oldStart == 0) {
    return const [];
  }

  if (currentStart == currentEnd) {
    final spliceRemoved = old.sublist(oldStart, oldEnd);
    return [
      ListChangeRecord<E>.remove(
        current,
        currentStart,
        spliceRemoved,
      ),
    ];
  }
  if (oldStart == oldEnd) {
    return [
      ListChangeRecord<E>.add(
        current,
        currentStart,
        currentEnd - currentStart,
      ),
    ];
  }

  final ops = _spliceOperationsFromEditDistances(
    _calcEditDistance(
      current,
      currentStart,
      currentEnd,
      old,
      oldStart,
      oldEnd,
    ),
  );

  var spliceIndex = -1;
  var spliceRemovals = <E>[];
  var spliceAddedCount = 0;

  bool hasSplice() => spliceIndex != -1;
  void resetSplice() {
    spliceIndex = -1;
    spliceRemovals = <E>[];
    spliceAddedCount = 0;
  }

  var splices = <ListChangeRecord<E>>[];

  var index = currentStart;
  var oldIndex = oldStart;
  for (final op in ops) {
    switch (op) {
      case _Edit.leave:
        if (hasSplice()) {
          splices.add(ListChangeRecord<E>(
            current,
            spliceIndex,
            removed: spliceRemovals,
            addedCount: spliceAddedCount,
          ));
          resetSplice();
        }
        index++;
        oldIndex++;
        break;
      case _Edit.update:
        if (!hasSplice()) {
          spliceIndex = index;
        }
        spliceAddedCount++;
        index++;
        spliceRemovals.add(old[oldIndex]);
        oldIndex++;
        break;
      case _Edit.add:
        if (!hasSplice()) {
          spliceIndex = index;
        }
        spliceAddedCount++;
        index++;
        break;
      case _Edit.delete:
        if (!hasSplice()) {
          spliceIndex = index;
        }
        spliceRemovals.add(old[oldIndex]);
        oldIndex++;
        break;
    }
  }
  if (hasSplice()) {
    splices.add(ListChangeRecord<E>(
      current,
      spliceIndex,
      removed: spliceRemovals,
      addedCount: spliceAddedCount,
    ));
  }
  assert(() {
    splices = List<ListChangeRecord<E>>.unmodifiable(splices);
    return true;
  }());
  return splices;
}

int _intersect(int start1, int end1, int start2, int end2) {
  return math.min(end1, end2) - math.max(start1, start2);
}

void _mergeSplices<E>(
  List<ListChangeRecord<E>> splices,
  ListChangeRecord<E> record,
) {
  var spliceIndex = record.index;
  var spliceRemoved = record.removed;
  var spliceAdded = record.addedCount;

  var inserted = false;
  var insertionOffset = 0;

  // I think the way this works is:
  // - the loop finds where the merge should happen
  // - it applies the merge in a particular splice
  // - then continues and updates the subsequent splices with any offset diff.
  for (var i = 0; i < splices.length; i++) {
    var current = splices[i];
    current = splices[i] = ListChangeRecord<E>(
      current.object,
      current.index + insertionOffset,
      removed: current.removed,
      addedCount: current.addedCount,
    );

    if (inserted) continue;

    var intersectCount = _intersect(
      spliceIndex,
      spliceIndex + spliceRemoved.length,
      current.index,
      current.index + current.addedCount,
    );
    if (intersectCount >= 0) {
      // Merge the two splices.
      splices.removeAt(i);
      i--;

      insertionOffset -= current.addedCount - current.removed.length;
      spliceAdded += current.addedCount - intersectCount;

      final deleteCount =
          spliceRemoved.length + current.removed.length - intersectCount;
      if (spliceAdded == 0 && deleteCount == 0) {
        // Merged splice is a no-op, discard.
        inserted = true;
      } else {
        final removed = current.removed.toList();
        if (spliceIndex < current.index) {
          // Some prefix of splice.removed is prepended to current.removed.
          removed.insertAll(
            0,
            spliceRemoved.getRange(0, current.index - spliceIndex),
          );
        }
        if (spliceIndex + spliceRemoved.length >
            current.index + current.addedCount) {
          // Some suffix of splice.removed is appended to current.removed.
          removed.addAll(spliceRemoved.getRange(
            current.index + current.addedCount - spliceIndex,
            spliceRemoved.length,
          ));
        }
        spliceRemoved = removed;
        if (current.index < spliceIndex) {
          spliceIndex = current.index;
        }
      }
    } else if (spliceIndex < current.index) {
      // Insert splice here.
      inserted = true;
      splices.insert(
        i,
        ListChangeRecord<E>(
          record.object,
          spliceIndex,
          removed: spliceRemoved,
          addedCount: spliceAdded,
        ),
      );
      i++;
      final offset = spliceAdded - spliceRemoved.length;
      current = splices[i] = ListChangeRecord<E>(
        current.object,
        current.index + offset,
        removed: current.removed,
        addedCount: current.addedCount,
      );
      insertionOffset += offset;
    }
  }
  if (!inserted) {
    splices.add(ListChangeRecord<E>(
      record.object,
      spliceIndex,
      removed: spliceRemoved,
      addedCount: spliceAdded,
    ));
  }
}

List<ListChangeRecord<E>> _createInitialSplices<E>(
  List<E> list,
  List<ListChangeRecord<E>> records,
) {
  final splices = <ListChangeRecord<E>>[];
  for (var i = 0; i < records.length; i++) {
    _mergeSplices(splices, records[i]);
  }
  return splices;
}

// We need to summarize change records. Consumers of these records want to
// apply the batch sequentially, and ensure that they can find inserted
// items by looking at that position in the list. This property does not
// hold in our record-as-you-go records. Consider:
//
//     var model = toObservable(['a', 'b']);
//     model.removeAt(1);
//     model.insertAll(0, ['c', 'd', 'e']);
//     model.removeRange(1, 3);
//     model.insert(1, 'f');
//
// Here, we inserted some records and then removed some of them.
// If someone processed these records naively, they would "play back" the
// insert incorrectly, because those items will be shifted.
List<ListChangeRecord<E>> projectListSplices<E>(
    List<E> list, List<ListChangeRecord<E>> records,
    [Equality<E> equality]) {
  equality ??= DefaultEquality<E>();
  if (records.length <= 1) return records;
  final splices = <ListChangeRecord<E>>[];
  final initialSplices = _createInitialSplices(list, records);
  for (final splice in initialSplices) {
    if (splice.addedCount == 1 && splice.removed.length == 1) {
      if (splice.removed[0] != list[splice.index]) {
        splices.add(splice);
      }
      continue;
    }
    splices.addAll(
      _calcSplices(
        list,
        equality,
        splice.index,
        splice.index + splice.addedCount,
        splice.removed,
        0,
        splice.removed.length,
      ),
    );
  }
  return splices;
}
