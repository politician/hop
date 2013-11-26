library hop.util;

import 'dart:collection';
import 'package:bot/bot.dart';
import 'package:bot_io/completion.dart';

const _RESERVED_TASKS = const[COMPLETION_COMMAND_NAME];
final RegExp _validNameRegExp = new RegExp(r'^[a-z]([a-z0-9_\-]*[a-z0-9])?$');

class TaskFailError extends Error {
  final String message;

  TaskFailError(this.message);

  String toString() => "TaskFailError: $message";
}

void validateTaskName(String name) {
  requireArgumentNotNullOrEmpty(name, 'name');
  requireArgumentContainsPattern(_validNameRegExp, name, 'name');
  requireArgument(!_RESERVED_TASKS.contains(name), 'task',
  'The provided task has a reserved name');
}

List topoSort(Map<dynamic, Iterable<dynamic>> dependencies) {
  requireArgumentNotNull(dependencies, 'dependencies');

  var graph = new _Graph(dependencies);

  var items = new LinkedHashSet();

  int targetCount = graph._map.length;

  while(items.length < targetCount) {

    var zeros = graph._map.values
        .where((_GraphNode node) {
          return !items.contains(node.value) &&
              node.outNodes
              .where((node) => !items.contains(node.value))
              .isEmpty;
        })
        .map((node) => node.value)
        .toList();

    if(zeros.isEmpty) throw new ArgumentError('There is a loop in the map');

    for(var item in zeros) {
      var added = items.add(item);
      assert(added);
    }
  }

  return items.toList();
}

class _Graph<T> {
  final LinkedHashMap<T, _GraphNode<T>> _map;

  factory _Graph(Map<T, Iterable<T>> items) {

    var map = new LinkedHashMap<T, _GraphNode<T>>();

    _GraphNode<T> getNode(T value) {
      return map.putIfAbsent(value, () => new _GraphNode<T>(value));
    };

    items.forEach((T item, Iterable<T> outLinks) {
      var node = getNode(item);
      outLinks.forEach((T outLink) {

        var newItem = node.outNodes.add(getNode(outLink));
        if(!newItem) throw new ArgumentError('Outlinks must not contain dupes');
      });


    });

    return new _Graph.core(map);
  }

  _Graph.core(this._map);

  String toString() {
    var sb = new StringBuffer();
    sb.writeln('{');
    _map.values.forEach((_GraphNode<T> value) {
      var outNodeStr = value.outNodes
          .map((gn) => gn.value)
          .join(', ');

      sb.writeln('  ${value.value} => {$outNodeStr}');
    });

    sb.writeln('}');
    return sb.toString();
  }

}

class _GraphNode<T> {
  final T value;
  final LinkedHashSet<_GraphNode> outNodes = new LinkedHashSet<_GraphNode<T>>();

  _GraphNode(this.value);

  bool operator ==(Object other) =>
      other is _GraphNode<T> && other.value == value;

  int get hashCode => value.hashCode;
}
