class MasterComponent {
  final String id;
  final String name;
  final String rootNodeId;
  final String category;
  final String? description;

  const MasterComponent({
    required this.id,
    required this.name,
    required this.rootNodeId,
    this.category = 'General',
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rootNodeId': rootNodeId,
    'category': category,
    if (description != null) 'description': description,
  };

  factory MasterComponent.fromJson(Map<String, dynamic> json) =>
      MasterComponent(
        id: json['id'] as String,
        name: json['name'] as String,
        rootNodeId: json['rootNodeId'] as String,
        category: json['category'] as String? ?? 'General',
        description: json['description'] as String?,
      );
}

class ComponentInstanceData {
  final String masterComponentId;
  final Map<String, dynamic> overrides;

  const ComponentInstanceData({
    required this.masterComponentId,
    this.overrides = const {},
  });

  ComponentInstanceData copyWith({
    String? masterComponentId,
    Map<String, dynamic>? overrides,
  }) {
    return ComponentInstanceData(
      masterComponentId: masterComponentId ?? this.masterComponentId,
      overrides: overrides ?? this.overrides,
    );
  }

  Map<String, dynamic> toJson() => {
    'masterComponentId': masterComponentId,
    'overrides': overrides,
  };

  factory ComponentInstanceData.fromJson(Map<String, dynamic> json) =>
      ComponentInstanceData(
        masterComponentId: json['masterComponentId'] as String,
        overrides: json['overrides'] as Map<String, dynamic>? ?? {},
      );
}
