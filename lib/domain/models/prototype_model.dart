enum PrototypeTrigger { onTap, onHover, onKeyDown }

enum PrototypeTransition {
  instant,
  dissolve,
  slideLeft,
  slideRight,
  slideUp,
  slideDown,
}

class PrototypeInteraction {
  final String id;
  final String sourceNodeId;
  final String targetFrameId;
  final PrototypeTrigger trigger;
  final PrototypeTransition transition;
  final int durationMs;

  const PrototypeInteraction({
    required this.id,
    required this.sourceNodeId,
    required this.targetFrameId,
    this.trigger = PrototypeTrigger.onTap,
    this.transition = PrototypeTransition.slideLeft,
    this.durationMs = 300,
  });

  PrototypeInteraction copyWith({
    String? id,
    String? sourceNodeId,
    String? targetFrameId,
    PrototypeTrigger? trigger,
    PrototypeTransition? transition,
    int? durationMs,
  }) {
    return PrototypeInteraction(
      id: id ?? this.id,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      targetFrameId: targetFrameId ?? this.targetFrameId,
      trigger: trigger ?? this.trigger,
      transition: transition ?? this.transition,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceNodeId': sourceNodeId,
    'targetFrameId': targetFrameId,
    'trigger': trigger.name,
    'transition': transition.name,
    'durationMs': durationMs,
  };

  factory PrototypeInteraction.fromJson(Map<String, dynamic> json) {
    return PrototypeInteraction(
      id: json['id'] as String,
      sourceNodeId: json['sourceNodeId'] as String,
      targetFrameId: json['targetFrameId'] as String,
      trigger: PrototypeTrigger.values.firstWhere(
        (e) => e.name == json['trigger'],
        orElse: () => PrototypeTrigger.onTap,
      ),
      transition: PrototypeTransition.values.firstWhere(
        (e) => e.name == json['transition'],
        orElse: () => PrototypeTransition.slideLeft,
      ),
      durationMs: json['durationMs'] as int? ?? 300,
    );
  }
}

class PrototypeFlow {
  final String id;
  final String name;
  final String? startingFrameId;
  final List<PrototypeInteraction> interactions;

  const PrototypeFlow({
    required this.id,
    required this.name,
    this.startingFrameId,
    this.interactions = const [],
  });

  PrototypeFlow copyWith({
    String? id,
    String? name,
    String? startingFrameId,
    List<PrototypeInteraction>? interactions,
  }) {
    return PrototypeFlow(
      id: id ?? this.id,
      name: name ?? this.name,
      startingFrameId: startingFrameId ?? this.startingFrameId,
      interactions: interactions ?? this.interactions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (startingFrameId != null) 'startingFrameId': startingFrameId,
    'interactions': interactions.map((i) => i.toJson()).toList(),
  };

  factory PrototypeFlow.fromJson(Map<String, dynamic> json) {
    return PrototypeFlow(
      id: json['id'] as String,
      name: json['name'] as String,
      startingFrameId: json['startingFrameId'] as String?,
      interactions: (json['interactions'] as List? ?? [])
          .map((i) => PrototypeInteraction.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}
