import 'page_model.dart';
import 'node_model.dart';
import 'component_model.dart';
import 'tokens_model.dart';
import 'prototype_model.dart';
import 'comment_model.dart';

class ProjectModel {
  static const int currentSchemaVersion = 1;

  final String id;
  final String name;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final List<PageModel> pages;
  final Map<String, DesignNode> nodes;
  final List<MasterComponent> components;
  final DesignTokens tokens;
  final List<PrototypeFlow> flows;
  final List<DesignComment> comments;

  const ProjectModel({
    required this.id,
    required this.name,
    this.version = currentSchemaVersion,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.pages = const [],
    this.nodes = const {},
    this.components = const [],
    this.tokens = const DesignTokens(),
    this.flows = const [],
    this.comments = const [],
  });

  DesignNode? getNode(String id) => nodes[id];

  PageModel? getPage(String id) {
    for (final page in pages) {
      if (page.id == id) return page;
    }
    return pages.isNotEmpty ? pages.first : null;
  }

  List<DesignNode> getRootNodes(String pageId) {
    final page = getPage(pageId);
    if (page == null) return const [];
    return page.rootNodeIds
        .map((id) => nodes[id])
        .whereType<DesignNode>()
        .toList();
  }

  List<DesignNode> getChildren(String parentId) {
    final parent = nodes[parentId];
    if (parent == null) return const [];
    return parent.childrenIds
        .map((id) => nodes[id])
        .whereType<DesignNode>()
        .toList();
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    List<PageModel>? pages,
    Map<String, DesignNode>? nodes,
    List<MasterComponent>? components,
    DesignTokens? tokens,
    List<PrototypeFlow>? flows,
    List<DesignComment>? comments,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      pages: pages ?? this.pages,
      nodes: nodes ?? this.nodes,
      components: components ?? this.components,
      tokens: tokens ?? this.tokens,
      flows: flows ?? this.flows,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isFavorite': isFavorite,
    'pages': pages.map((p) => p.toJson()).toList(),
    'nodes': nodes.map((k, v) => MapEntry(k, v.toJson())),
    'components': components.map((c) => c.toJson()).toList(),
    'tokens': tokens.toJson(),
    'flows': flows.map((f) => f.toJson()).toList(),
    'comments': comments.map((c) => c.toJson()).toList(),
  };

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final schemaVer = json['version'] as int? ?? 1;

    // Safe schema migration handling
    final parsedNodes = <String, DesignNode>{};
    if (json['nodes'] is Map) {
      final rawNodes = json['nodes'] as Map;
      for (final entry in rawNodes.entries) {
        if (entry.value is Map) {
          parsedNodes[entry.key.toString()] = DesignNode.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    return ProjectModel(
      id:
          json['id'] as String? ??
          'proj-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Untitled Project',
      version: schemaVer,
      createdAt: json.containsKey('createdAt')
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json.containsKey('updatedAt')
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      pages: (json['pages'] as List? ?? [])
          .map((p) => PageModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      nodes: parsedNodes,
      components: (json['components'] as List? ?? [])
          .map((c) => MasterComponent.fromJson(c as Map<String, dynamic>))
          .toList(),
      tokens: json['tokens'] != null
          ? DesignTokens.fromJson(json['tokens'] as Map<String, dynamic>)
          : DesignTokens.defaultTokens(),
      flows: (json['flows'] as List? ?? [])
          .map((f) => PrototypeFlow.fromJson(f as Map<String, dynamic>))
          .toList(),
      comments: (json['comments'] as List? ?? [])
          .map((c) => DesignComment.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
