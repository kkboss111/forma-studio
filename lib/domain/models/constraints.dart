enum HorizontalConstraint { left, right, center, stretch, scale }

enum VerticalConstraint { top, bottom, center, stretch, scale }

class LayoutConstraints {
  final HorizontalConstraint horizontal;
  final VerticalConstraint vertical;

  const LayoutConstraints({
    this.horizontal = HorizontalConstraint.left,
    this.vertical = VerticalConstraint.top,
  });

  LayoutConstraints copyWith({
    HorizontalConstraint? horizontal,
    VerticalConstraint? vertical,
  }) {
    return LayoutConstraints(
      horizontal: horizontal ?? this.horizontal,
      vertical: vertical ?? this.vertical,
    );
  }

  Map<String, dynamic> toJson() => {
    'horizontal': horizontal.name,
    'vertical': vertical.name,
  };

  factory LayoutConstraints.fromJson(Map<String, dynamic> json) {
    return LayoutConstraints(
      horizontal: HorizontalConstraint.values.firstWhere(
        (e) => e.name == json['horizontal'],
        orElse: () => HorizontalConstraint.left,
      ),
      vertical: VerticalConstraint.values.firstWhere(
        (e) => e.name == json['vertical'],
        orElse: () => VerticalConstraint.top,
      ),
    );
  }
}
