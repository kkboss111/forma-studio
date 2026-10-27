import 'package:flutter/material.dart';
import 'forma_colors.dart';

enum NeuStyle { raised, inset, flat }

/// Helper for generating soft neumorphic BoxShadows.
class NeuBoxDecoration {
  static BoxDecoration box({
    required BuildContext context,
    NeuStyle style = NeuStyle.raised,
    double radius = 18.0,
    BorderRadius? borderRadius,
    Color? color,
    Border? border,
    bool isSelected = false,
    double intensity = 1.0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        color ?? (isDark ? FormaColors.darkSurface : FormaColors.lightSurface);
    final shadowDark =
        (isDark ? FormaColors.darkShadowDark : FormaColors.lightShadowDark)
            .withValues(alpha: isDark ? 0.9 : 0.85);
    final shadowLight =
        (isDark ? FormaColors.darkShadowLight : FormaColors.lightShadowLight)
            .withValues(alpha: isDark ? 0.35 : 0.95);

    final resolvedRadius = borderRadius ?? BorderRadius.circular(radius);

    if (style == NeuStyle.inset) {
      // In Flutter, inner shadows can be simulated with gradient borders / subtle inset box-shadow
      return BoxDecoration(
        color: surfaceColor,
        borderRadius: resolvedRadius,
        border:
            border ??
            Border.all(
              color: isDark ? const Color(0xFF161A22) : const Color(0xFFD6DFEC),
              width: 1.0,
            ),
        boxShadow: [
          BoxShadow(
            color: shadowDark.withValues(alpha: 0.25 * intensity),
            offset: const Offset(2, 2),
            blurRadius: 4 * intensity,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: shadowLight.withValues(alpha: 0.5 * intensity),
            offset: const Offset(-2, -2),
            blurRadius: 4 * intensity,
            spreadRadius: -1,
          ),
        ],
      );
    }

    if (style == NeuStyle.flat) {
      return BoxDecoration(
        color: surfaceColor,
        borderRadius: resolvedRadius,
        border:
            border ??
            Border.all(
              color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
              width: 1.0,
            ),
      );
    }

    // Default: Raised
    final offsetDark = Offset(5 * intensity, 5 * intensity);
    final offsetLight = Offset(-5 * intensity, -5 * intensity);
    final blur = 12.0 * intensity;

    return BoxDecoration(
      color: surfaceColor,
      borderRadius: resolvedRadius,
      border:
          border ??
          (isSelected
              ? Border.all(
                  color: FormaColors.primaryBlue.withValues(alpha: 0.6),
                  width: 1.5,
                )
              : null),
      boxShadow: [
        BoxShadow(color: shadowDark, offset: offsetDark, blurRadius: blur),
        BoxShadow(color: shadowLight, offset: offsetLight, blurRadius: blur),
      ],
    );
  }
}

/// A tactile neumorphic container with soft rounded corners and dual shadows.
class NeuCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final NeuStyle style;
  final Color? color;
  final Border? border;
  final double? width;
  final double? height;
  final bool isSelected;
  final VoidCallback? onTap;

  const NeuCard({
    super.key,
    required this.child,
    this.radius = 20.0,
    this.borderRadius,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.style = NeuStyle.raised,
    this.color,
    this.border,
    this.width,
    this.height,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: NeuBoxDecoration.box(
        context: context,
        style: style,
        radius: radius,
        borderRadius: borderRadius,
        color: color,
        border: border,
        isSelected: isSelected,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }
}

/// A neumorphic tactile button with active/pressed state feedback.
class NeuButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool isActive;
  final Color? color;
  final double? width;
  final double? height;
  final String? tooltip;

  const NeuButton({
    super.key,
    required this.child,
    this.onPressed,
    this.radius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
    this.isActive = false,
    this.color,
    this.width,
    this.height,
    this.tooltip,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final style = (_isPressed || widget.isActive)
        ? NeuStyle.inset
        : NeuStyle.raised;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget btn = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.onPressed != null
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.onPressed != null
            ? (_) => setState(() => _isPressed = false)
            : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: NeuBoxDecoration.box(
            context: context,
            style: style,
            radius: widget.radius,
            color:
                widget.color ??
                (_isHovered && !widget.isActive
                    ? (isDark
                          ? const Color(0xFF232A37)
                          : const Color(0xFFEDF3FC))
                    : null),
            isSelected: widget.isActive,
            intensity: _isPressed ? 0.6 : 1.0,
          ),
          child: Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}

/// Neumorphic Icon Button, matching the style of the reference buttons.
class NeuIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final bool isActive;
  final String? tooltip;
  final Color? iconColor;
  final double radius;

  const NeuIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 40.0,
    this.iconSize = 18.0,
    this.isActive = false,
    this.tooltip,
    this.iconColor,
    this.radius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isActive
        ? FormaColors.primaryBlue
        : (isDark ? FormaColors.darkTextMain : FormaColors.lightTextMain);

    return NeuButton(
      width: size,
      height: size,
      radius: radius,
      padding: EdgeInsets.zero,
      isActive: isActive,
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(icon, size: iconSize, color: iconColor ?? defaultColor),
    );
  }
}

/// Inset well panel (like stat cards and property input background).
class NeuWell extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double? width;
  final double? height;

  const NeuWell({
    super.key,
    required this.child,
    this.radius = 14.0,
    this.padding = const EdgeInsets.all(12.0),
    this.color,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: NeuBoxDecoration.box(
        context: context,
        style: NeuStyle.inset,
        radius: radius,
        color: color,
      ),
      child: child,
    );
  }
}

/// Neumorphic Pill badge or interactive toggle chip.
class NeuPill extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsetsGeometry padding;

  const NeuPill({
    super.key,
    required this.child,
    this.isSelected = false,
    this.onTap,
    this.radius = 20.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: padding,
        decoration: NeuBoxDecoration.box(
          context: context,
          style: isSelected ? NeuStyle.inset : NeuStyle.raised,
          radius: radius,
          isSelected: isSelected,
          intensity: 0.7,
        ),
        child: child,
      ),
    );
  }
}

/// Neumorphic Text Field with smooth inset well.
class NeuTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final double radius;
  final TextInputType? keyboardType;

  const NeuTextField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.radius = 12.0,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? FormaColors.darkTextMain
        : FormaColors.lightTextMain;
    final hintColor = isDark
        ? FormaColors.darkTextMuted
        : FormaColors.lightTextMuted;

    return NeuWell(
      radius: radius,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      child: Row(
        children: [
          if (prefixIcon != null) ...[prefixIcon!, const SizedBox(width: 8)],
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              keyboardType: keyboardType,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              cursorColor: FormaColors.primaryBlue,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: hintColor,
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
          if (suffixIcon != null) ...[const SizedBox(width: 6), suffixIcon!],
        ],
      ),
    );
  }
}
