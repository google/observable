// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observable.src.to_observable;

import 'dart:collection';

import 'package:dart_internal/extract_type_arguments.dart';

import 'observable.dart' show Observable;
import 'observable_list.dart' show ObservableList;
import 'observable_map.dart' show ObservableMap;

/// Converts the [Iterable] or [Map] to an [ObservableList] or [ObservableMap],
/// respectively. This is a convenience function to make it easier to convert
/// literals into the corresponding observable collection type.
///
/// For better static typing, use either [toObservableList] or
/// [toObservableMap] instead of this function.
///
/// If [value] is not one of those collection types, or is already [Observable],
/// it will be returned unmodified.
///
/// If [value] is a [Map], the resulting value will use the appropriate kind of
/// backing map: either [HashMap], [LinkedHashMap], or [SplayTreeMap].
///
/// By default this performs a deep conversion, but you can set [deep] to false
/// for a shallow conversion. This does not handle circular data structures.
/// If a conversion is peformed, mutations are only observed to the result of
/// this function. Changing the original collection will not affect it.
// TODO(jmesserly): ObservableSet?
dynamic toObservable(dynamic value, {bool deep = true}) =>
    deep ? _toObservableDeep(value) : _toObservableShallow(value);

/// Converts the [Iterable] to an [ObservableList].
///
/// If [value] is already [Observable], it will be returned unmodified.
///
/// By default this performs a deep conversion, but you can set [deep] to false
/// for a shallow conversion. This does not handle circular data structures.
/// If a conversion is peformed, mutations are only observed to the result of
/// this function. Changing the original collection will not affect it.
ObservableList<T> toObservableList<T>(Iterable<T> value, {bool deep = true}) {
  if (value is Observable) return value;
  return deep ? _toObservableDeepIterable(value) : _toObservableShallow(value);
}

/// Converts the [Map] to an [ObservableMap].
///
/// If [value] is already [Observable], it will be returned unmodified.
///
/// The returned value will use the appropriate kind of backing map: either
/// [HashMap], [LinkedHashMap], or [SplayTreeMap].
///
/// By default this performs a deep conversion, but you can set [deep] to false
/// for a shallow conversion. This does not handle circular data structures.
/// If a conversion is peformed, mutations are only observed to the result of
/// this function. Changing the original collection will not affect it.
ObservableMap<K, V> toObservableMap<K, V>(Map<K, V> value, {bool deep = true}) {
  if (value is Observable) return value;
  return deep ? _toObservableDeepMap(value) : _toObservableShallow(value);
}

dynamic _toObservableShallow(dynamic value) {
  if (value is Observable) return value;

  if (value is Map) {
    return extractMapTypeArguments(
        value, <K, V>() => ObservableMap<K, V>.from(value));
  }

  if (value is Iterable) {
    return extractIterableTypeArgument(
        value, <T>() => ObservableList<T>.from(value));
  }

  return value;
}

dynamic _toObservableDeep(dynamic value) {
  if (value is Observable) return value;

  if (value is Map) return _toObservableDeepMap(value);

  if (value is Iterable) return _toObservableDeepIterable(value);

  return value;
}

ObservableMap _toObservableDeepMap(Map<dynamic, dynamic> value) {
  return extractMapTypeArguments(value, <K, V>() {
    var result = ObservableMap<K, V>.createFromType(value);
    value.forEach((k, v) {
      result[_toObservableDeep(k)] = _toObservableDeep(v);
    });
    return result;
  });
}

ObservableList _toObservableDeepIterable(Iterable<dynamic> value) {
  return extractIterableTypeArgument(value, <T>() {
    var result = ObservableList<T>();
    for (var element in value) {
      result.add(_toObservableDeep(element));
    }
    return result;
  });
}
