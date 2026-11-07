import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'forma_colors.dart';
import 'forma_theme.dart';

enum NeuStyle { raised, inset, flat }

/// Helper for generating tactile, elevated, and crisp surface decorations.
/// Dynamically adapts to all 4 Forma themes (Light, Dark, Liquid Glass, Cosmic Glassmorphism):
/// - Light Mode: Pure white surfaces, 1px Slate-200 border, delicate dual-layer diffuse shadows.
/// - Dark Mode: Slate-900 surfaces, 1px Slate-800 border, specular rim highlight, deep ambient elevation.
/// - Liquid Glass: Frosted translucent white fluid glass, luminous specular white borders, cyan active glow.
/// - Cosmic Glassmorphism: Starlight frosted dark glass, luminous starlight borders, nebula violet/gold glow.
class NeuBoxDecoration {
  static BoxDecoration box({
    required BuildContext context,
    NeuStyle style = NeuStyle.raised,
    double radius = 16.0,
    BorderRadius? borderRadius,
    Color? color,
    Border? border,
    bool isSelected = false,
    double intensity = 1.0,
  }) {
    final tokens = FormaTheme.tokensOf(context);
    final surfaceColor = color ?? tokens.surface;
    final resolvedRadius = borderRadius ?? BorderRadius.circular(radius);

    // 1. Frosted Glass Decorations (Liquid Glass & Cosmic Glassmorphism)
    if (tokens.isGlass) {
      if (style == NeuStyle.inset) {
        return BoxDecoration(
          color: color ?? tokens.wellBg,
          borderRadius: resolvedRadius,
          border: border ??
              Border.all(
                color: tokens.border,
                width: 1.0,
              ),
        );
      }

      if (style == NeuStyle.flat) {
        return BoxDecoration(
          color: surfaceColor,
          borderRadius: resolvedRadius,
          border: border ??
              Border.all(
                color: tokens.border,
                width: 1.0,
              ),
        );
      }

      // Raised Glass (Frosted glass card with specular rim and ambient elevation)
      return BoxDecoration(
        color: surfaceColor,
        borderRadius: resolvedRadius,
        border: border ??
            (isSelected
                ? Border.all(color: tokens.accent, width: 1.5)
                : Border.all(color: tokens.border, width: 1.0)),
        boxShadow: isSelected
            ? [
                ...tokens.cardShadow,
                BoxShadow(
                  color: tokens.activeGlow,
                  offset: Offset.zero,
                  blurRadius: 10 * intensity,
                  spreadRadius: 1,
                ),
              ]
            : tokens.cardShadow,
      );
    }

    // 2. Solid Inset Well
    if (style == NeuStyle.inset) {
      return BoxDecoration(
        color: color ?? tokens.wellBg,
        borderRadius: resolvedRadius,
        border: border ??
            Border.all(
              color: tokens.border,
              width: 1.0,
            ),
        boxShadow: [
          BoxShadow(
            color: tokens.isDark
                ? Colors.black.withValues(alpha: 0.25 * intensity)
                : const Color(0x0A0F172A),
            offset: const Offset(0, 1.5),
            blurRadius: 3 * intensity,
            spreadRadius: -0.5,
          ),
        ],
      );
    }

    // 3. Solid Flat Surface
    if (style == NeuStyle.flat) {
      return BoxDecoration(
        color: surfaceColor,
        borderRadius: resolvedRadius,
        border: border ??
            Border.all(
              color: tokens.border,
              width: 1.0,
            ),
      );
    }

    // 4. Solid Raised Surface (Obsidian Dark or Modern Studio Light)
    if (tokens.isDark) {
      return BoxDecoration(
        color: surfaceColor,
        borderRadius: resolvedRadius,
        border: border ??
            (isSelected
                ? Border.all(color: FormaColors.primaryBlue, width: 1.5)
                : Border.all(color: tokens.border, width: 1.0)),
        boxShadow: [
          // Specular top rim
          const BoxShadow(
            color: Color(0x0FFFFFFF), // 6% top white specular
            offset: Offset(0, 1),
            blurRadius: 0,
            spreadRadius: 0,
          ),
          // Deep ambient elevation
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35 * intensity),
            offset: const Offset(0, 4),
            blurRadius: 12 * intensity,
            spreadRadius: -1,
          ),
          if (isSelected)
            BoxShadow(
              color: FormaColors.primaryBlue.withValues(alpha: 0.3),
              offset: Offset.zero,
              blurRadius: 10 * intensity,
              spreadRadius: 1,
            ),
        ],
      );
    } else {
      // Light Mode
      return BoxDecoration(
        color: surfaceColor,
        borderRadius: resolvedRadius,
        border: border ??
            (isSelected
                ? Border.all(color: FormaColors.primaryBlue, width: 1.5)
                : Border.all(color: tokens.border, width: 1.0)),
        boxShadow: [
          // Crisp micro-shadow
          BoxShadow(
            color: const Color(0x0A0F172A).withValues(alpha: 0.05 * intensity),
            offset: const Offset(0, 1),
            blurRadius: 3 * intensity,
          ),
          // Soft ambient drop
          BoxShadow(
            color: const Color(0x080F172A).withValues(alpha: 0.04 * intensity),
            offset: const Offset(0, 6),
            blurRadius: 16 * intensity,
            spreadRadius: -2,
          ),
          if (isSelected)
            BoxShadow(
              color: FormaColors.primaryBlue.withValues(alpha: 0.22),
              offset: Offset.zero,
              blurRadius: 8 * intensity,
              spreadRadius: 1,
            ),
        ],
      );
    }
  }
}

/// A tactile container with soft rounded corners, crisp borders, and subtle elevation.
/// When in a glass theme, automatically applies BackdropFilter blur.
class NeuCard extends StatefulWidget {
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
    this.radius = 16.0,
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
  State<NeuCard> createState() => _NeuCardState();
}

class _NeuCardState extends State<NeuCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = FormaTheme.tokensOf(context);
    final resolvedRadius = widget.borderRadius ?? BorderRadius.circular(widget.radius);

    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      decoration: NeuBoxDecoration.box(
        context: context,
        style: widget.style,
        radius: widget.radius,
        borderRadius: widget.borderRadius,
        color: widget.color,
        border: widget.border,
        isSelected: widget.isSelected,
        intensity: _isHovered ? 1.25 : 1.0,
      ),
      child: widget.child,
    );

    if (tokens.isGlass && tokens.cardBlur > 0) {
      cardContent = ClipRRect(
        borderRadius: resolvedRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: tokens.cardBlur,
            sigmaY: tokens.cardBlur,
          ),
          child: cardContent,
        ),
      );
    }

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      margin: widget.margin,
      transform: (widget.onTap != null && _isHovered)
          ? Matrix4.translationValues(0, -2.0, 0)
          : Matrix4.identity(),
      child: cardContent,
    );

    if (widget.onTap != null) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: card,
        ),
      );
    }
    return card;
  }
}

/// A tactile button with interactive spring press feedback (/animate).
/// When in a glass theme, renders as a frosted translucent glass pill.
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
    this.radius = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 14.0, vertical: 9.0),
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
    final tokens = FormaTheme.tokensOf(context);

    Color? resolvedColor = widget.color;
    if (widget.isActive) {
      resolvedColor = tokens.accent.withValues(alpha: tokens.isDark ? 0.25 : 0.15);
    } else if (_isHovered && widget.onPressed != null) {
      resolvedColor = tokens.isGlass
          ? (tokens.isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.95))
          : (tokens.isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9));
    }

    Widget buttonContent = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      decoration: NeuBoxDecoration.box(
        context: context,
        style: widget.isActive ? NeuStyle.inset : NeuStyle.raised,
        radius: widget.radius,
        color: resolvedColor,
        isSelected: widget.isActive,
        intensity: _isPressed ? 0.6 : (_isHovered ? 1.2 : 1.0),
      ),
      child: Center(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: widget.child,
      ),
    );

    if (tokens.isGlass && tokens.cardBlur > 0) {
      buttonContent = ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: tokens.cardBlur * 0.75,
            sigmaY: tokens.cardBlur * 0.75,
          ),
          child: buttonContent,
        ),
      );
    }

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
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovered && widget.onPressed != null ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: buttonContent,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}

/// Tactile Icon Button with 40-44px touch targets.
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
    final tokens = FormaTheme.tokensOf(context);
    final defaultColor = isActive
        ? tokens.accent
        : (tokens.isDark ? tokens.textMain : tokens.textMain);

    return NeuButton(
      width: size,
      height: size,
      radius: radius,
      padding: EdgeInsets.zero,
      isActive: isActive,
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor ?? defaultColor,
      ),
    );
  }
}

/// Inset well panel for property fields and preview containers.
class NeuWell extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double? width;
  final double? height;
  final Border? border;

  const NeuWell({
    super.key,
    required this.child,
    this.radius = 12.0,
    this.padding = const EdgeInsets.all(12.0),
    this.color,
    this.width,
    this.height,
    this.border,
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
        border: border,
      ),
      child: child,
    );
  }
}

/// Tactile interactive pill badge.
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
    final tokens = FormaTheme.tokensOf(context);

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
          color: isSelected
              ? tokens.accent.withValues(alpha: tokens.isDark ? 0.22 : 0.15)
              : null,
        ),
        child: child,
      ),
    );
  }
}

/// Tactile input text field with subtle inset well background and crisp borders.
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
    final tokens = FormaTheme.tokensOf(context);

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
                color: tokens.textMain,
              ),
              cursorColor: tokens.accent,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: tokens.textMuted,
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
