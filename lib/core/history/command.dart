import 'package:flutter/material.dart';
import '../../domain/models/project_model.dart';
import '../../domain/models/node_model.dart';
import '../../domain/models/page_model.dart';

abstract class Command {
  String get description;
  ProjectModel execute(ProjectModel project);
  ProjectModel undo(ProjectModel project);
  ProjectModel redo(ProjectModel project) => execute(project);
}

/// Composite command for batching multiple operations (e.g. continuous drag transform).
class BatchCommand extends Command {
  final List<Command> commands;
  final String _description;

  BatchCommand(this.commands, {String description = 'Batch Action'})
    : _description = description;

  @override
  String get description => _description;

  @override
  ProjectModel execute(ProjectModel project) {
    ProjectModel current = project;
    for (final cmd in commands) {
      current = cmd.execute(current);
    }
    return current;
  }

  @override
  ProjectModel undo(ProjectModel project) {
    ProjectModel current = project;
    for (final cmd in commands.reversed) {
      current = cmd.undo(current);
    }
    return current;
  }
}

/// Command to add a node to a page and parent.
class AddNodeCommand extends Command {
  final String pageId;
  final DesignNode node;

  AddNodeCommand({required this.pageId, required this.node});

  @override
  String get description => 'Add ${node.name}';

  @override
  ProjectModel execute(ProjectModel project) {
    final page = project.getPage(pageId);
    if (page == null) return project;

    final updatedNodes = Map<String, DesignNode>.from(project.nodes);
    updatedNodes[node.id] = node;

    List<PageModel> updatedPages = List.from(project.pages);
    if (node.parentId == null) {
      final updatedPage = page.copyWith(
        rootNodeIds: [...page.rootNodeIds, node.id],
      );
      updatedPages = project.pages
          .map((p) => p.id == pageId ? updatedPage : p)
          .toList();
    } else {
      final parent = updatedNodes[node.parentId!];
      if (parent != null) {
        updatedNodes[parent.id] = parent.copyWith(
          childrenIds: [...parent.childrenIds, node.id],
        );
      }
    }

    return project.copyWith(
      nodes: updatedNodes,
      pages: updatedPages,
      updatedAt: DateTime.now(),
    );
  }

  @override
  ProjectModel undo(ProjectModel project) {
    final page = project.getPage(pageId);
    if (page == null) return project;

    final updatedNodes = Map<String, DesignNode>.from(project.nodes)
      ..remove(node.id);
    List<PageModel> updatedPages = List.from(project.pages);

    if (node.parentId == null) {
      final updatedRootIds = List<String>.from(page.rootNodeIds)
        ..remove(node.id);
      final updatedPage = page.copyWith(rootNodeIds: updatedRootIds);
      updatedPages = project.pages
          .map((p) => p.id == pageId ? updatedPage : p)
          .toList();
    } else {
      final parent = updatedNodes[node.parentId!];
      if (parent != null) {
        final updatedChildren = List<String>.from(parent.childrenIds)
          ..remove(node.id);
        updatedNodes[parent.id] = parent.copyWith(childrenIds: updatedChildren);
      }
    }

    return project.copyWith(
      nodes: updatedNodes,
      pages: updatedPages,
      updatedAt: DateTime.now(),
    );
  }
}

/// Command to delete nodes.
class DeleteNodesCommand extends Command {
  final String pageId;
  final List<DesignNode> nodesToDelete;
  final Map<String, String?> originalParents = {};
  final Map<String, int> originalIndices = {};

  DeleteNodesCommand({required this.pageId, required this.nodesToDelete});

  @override
  String get description => 'Delete ${nodesToDelete.length} item(s)';

  @override
  ProjectModel execute(ProjectModel project) {
    final page = project.getPage(pageId);
    if (page == null) return project;

    final updatedNodes = Map<String, DesignNode>.from(project.nodes);
    final deleteIds = nodesToDelete.map((n) => n.id).toSet();

    // Store original locations for undo
    for (final node in nodesToDelete) {
      originalParents[node.id] = node.parentId;
      if (node.parentId == null) {
        originalIndices[node.id] = page.rootNodeIds.indexOf(node.id);
      } else {
        final parent = project.nodes[node.parentId];
        if (parent != null) {
          originalIndices[node.id] = parent.childrenIds.indexOf(node.id);
        }
      }
    }

    // Remove from nodes map
    for (final id in deleteIds) {
      updatedNodes.remove(id);
    }

    // Remove from roots
    final updatedRootIds = page.rootNodeIds
        .where((id) => !deleteIds.contains(id))
        .toList();
    final updatedPages = project.pages.map((p) {
      if (p.id == pageId) return p.copyWith(rootNodeIds: updatedRootIds);
      return p;
    }).toList();

    // Remove from parents
    for (final entry in updatedNodes.entries) {
      final node = entry.value;
      if (node.childrenIds.any((id) => deleteIds.contains(id))) {
        updatedNodes[entry.key] = node.copyWith(
          childrenIds: node.childrenIds
              .where((id) => !deleteIds.contains(id))
              .toList(),
        );
      }
    }

    return project.copyWith(
      nodes: updatedNodes,
      pages: updatedPages,
      updatedAt: DateTime.now(),
    );
  }

  @override
  ProjectModel undo(ProjectModel project) {
    final page = project.getPage(pageId);
    if (page == null) return project;

    final updatedNodes = Map<String, DesignNode>.from(project.nodes);
    for (final node in nodesToDelete) {
      updatedNodes[node.id] = node;
    }

    final updatedRootIds = List<String>.from(page.rootNodeIds);
    for (final node in nodesToDelete) {
      if (node.parentId == null) {
        final idx = originalIndices[node.id] ?? updatedRootIds.length;
        final safeIdx = idx.clamp(0, updatedRootIds.length);
        updatedRootIds.insert(safeIdx, node.id);
      } else {
        final parent = updatedNodes[node.parentId!];
        if (parent != null) {
          final parentChildren = List<String>.from(parent.childrenIds);
          final idx = originalIndices[node.id] ?? parentChildren.length;
          final safeIdx = idx.clamp(0, parentChildren.length);
          parentChildren.insert(safeIdx, node.id);
          updatedNodes[parent.id] = parent.copyWith(
            childrenIds: parentChildren,
          );
        }
      }
    }

    final updatedPages = project.pages.map((p) {
      if (p.id == pageId) return p.copyWith(rootNodeIds: updatedRootIds);
      return p;
    }).toList();

    return project.copyWith(
      nodes: updatedNodes,
      pages: updatedPages,
      updatedAt: DateTime.now(),
    );
  }
}

/// Command to update a node's properties.
class UpdateNodeCommand extends Command {
  final DesignNode previousNode;
  final DesignNode updatedNode;
  final String _description;

  UpdateNodeCommand({
    required this.previousNode,
    required this.updatedNode,
    String description = 'Update Properties',
  }) : _description = description;

  @override
  String get description => _description;

  @override
  ProjectModel execute(ProjectModel project) {
    final updatedNodes = Map<String, DesignNode>.from(project.nodes);
    updatedNodes[updatedNode.id] = updatedNode;
    return project.copyWith(nodes: updatedNodes, updatedAt: DateTime.now());
  }

  @override
  ProjectModel undo(ProjectModel project) {
    final updatedNodes = Map<String, DesignNode>.from(project.nodes);
    updatedNodes[previousNode.id] = previousNode;
    return project.copyWith(nodes: updatedNodes, updatedAt: DateTime.now());
  }
}

/// Command to move multiple nodes by a delta.
class MoveNodesCommand extends Command {
  final Map<String, Offset> originalPositions;
  final Map<String, Offset> newPositions;

  MoveNodesCommand({
    required this.originalPositions,
    required this.newPositions,
  });

  @override
  String get description => 'Move ${originalPositions.length} object(s)';

  @override
  ProjectModel execute(ProjectModel project) {
    final updatedNodes = Map<String, DesignNode>.from(project.nodes);
    for (final entry in newPositions.entries) {
      final node = updatedNodes[entry.key];
      if (node != null) {
        updatedNodes[entry.key] = node.copyWith(
          x: entry.value.dx,
          y: entry.value.dy,
        );
      }
    }
    return project.copyWith(nodes: updatedNodes, updatedAt: DateTime.now());
  }

  @override
  ProjectModel undo(ProjectModel project) {
    final updatedNodes = Map<String, DesignNode>.from(project.nodes);
    for (final entry in originalPositions.entries) {
      final node = updatedNodes[entry.key];
      if (node != null) {
        updatedNodes[entry.key] = node.copyWith(
          x: entry.value.dx,
          y: entry.value.dy,
        );
      }
    }
    return project.copyWith(nodes: updatedNodes, updatedAt: DateTime.now());
  }
}
