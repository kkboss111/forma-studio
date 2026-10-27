enum NodeType {
  frame,
  group,
  rectangle,
  roundedRectangle,
  ellipse,
  line,
  arrow,
  polygon,
  star,
  freehandPath,
  vectorPath,
  text,
  image,
  svg,
  componentInstance,
  annotationSection,
}

extension NodeTypeExtension on NodeType {
  String get displayName {
    switch (this) {
      case NodeType.frame:
        return 'Frame';
      case NodeType.group:
        return 'Group';
      case NodeType.rectangle:
        return 'Rectangle';
      case NodeType.roundedRectangle:
        return 'Rounded Rect';
      case NodeType.ellipse:
        return 'Ellipse';
      case NodeType.line:
        return 'Line';
      case NodeType.arrow:
        return 'Arrow';
      case NodeType.polygon:
        return 'Polygon';
      case NodeType.star:
        return 'Star';
      case NodeType.freehandPath:
        return 'Pen Draw';
      case NodeType.vectorPath:
        return 'Vector Path';
      case NodeType.text:
        return 'Text';
      case NodeType.image:
        return 'Image';
      case NodeType.svg:
        return 'SVG Vector';
      case NodeType.componentInstance:
        return 'Component';
      case NodeType.annotationSection:
        return 'Section';
    }
  }

  bool get isContainer =>
      this == NodeType.frame ||
      this == NodeType.group ||
      this == NodeType.annotationSection;
}
