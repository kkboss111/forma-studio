class CommentReply {
  final String id;
  final String author;
  final String message;
  final DateTime timestamp;

  const CommentReply({
    required this.id,
    required this.author,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };

  factory CommentReply.fromJson(Map<String, dynamic> json) => CommentReply(
    id: json['id'] as String,
    author: json['author'] as String,
    message: json['message'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class DesignComment {
  final String id;
  final String pageId;
  final double x;
  final double y;
  final String author;
  final String message;
  final DateTime timestamp;
  final bool isResolved;
  final List<CommentReply> replies;

  const DesignComment({
    required this.id,
    required this.pageId,
    required this.x,
    required this.y,
    required this.author,
    required this.message,
    required this.timestamp,
    this.isResolved = false,
    this.replies = const [],
  });

  DesignComment copyWith({
    String? id,
    String? pageId,
    double? x,
    double? y,
    String? author,
    String? message,
    DateTime? timestamp,
    bool? isResolved,
    List<CommentReply>? replies,
  }) {
    return DesignComment(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      x: x ?? this.x,
      y: y ?? this.y,
      author: author ?? this.author,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isResolved: isResolved ?? this.isResolved,
      replies: replies ?? this.replies,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageId': pageId,
    'x': x,
    'y': y,
    'author': author,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isResolved': isResolved,
    'replies': replies.map((r) => r.toJson()).toList(),
  };

  factory DesignComment.fromJson(Map<String, dynamic> json) {
    return DesignComment(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      author: json['author'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isResolved: json['isResolved'] as bool? ?? false,
      replies: (json['replies'] as List? ?? [])
          .map((r) => CommentReply.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
