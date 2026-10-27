# Forma Studio

A mobile-first, Figma-inspired UI/UX design application in Flutter and Dart, crafted with a soft blue-gray tactile neumorphic design system inspired by the visual reference dashboard (`#E6ECF5` surface, `#2B3445` dark slate typography, `#8A99AD` muted accents, dual light/dark soft shadows, and crisp canvas elements).

---

## 🎨 Visual Design & Neumorphic System

Forma Studio implements an original tactile design system mirroring the aesthetics of the reference HTML dashboard:
- **Background & Panels**: `#E6ECF5` (Light mode) and `#181C24` / `#1E242F` (Dark mode)
- **Primary Text**: `#2B3445` (rich dark slate) / `#E8EEF5` (dark mode)
- **Muted Text**: `#8A99AD` / `#808F9F`
- **Dual Neumorphic Shadows**:
  - Light Highlight: `Offset(-5, -5)`, blur `12px`, `#FFFFFF`
  - Dark Shadow: `Offset(5, 5)`, blur `12px`, `#C8D3E2`
- **Neumorphic Primitives (`lib/app/theme/neumorphic.dart`)**:
  - `NeuCard`: Raised/inset container with customizable border radius (14px–28px).
  - `NeuButton`: Tactile button with active depression and hover states.
  - `NeuIconButton`: Circular / rounded square icon button with subtle shadows.
  - `NeuWell`: Inset surface well for inputs and stat cards.
  - `NeuPill`: Soft pill toggle badge.
  - `NeuTextField`: Inset input field with label and icons.

---

## 🏗️ Architecture & Modules

The codebase is organized into clean, modular layers:

```
forma_studio/
├── lib/
│   ├── main.dart                          // Application entry point with ProviderScope
│   ├── app/
│   │   ├── app.dart                       // MaterialApp, theme state & routing
│   │   └── theme/
│   │       ├── forma_colors.dart          // Neumorphic palette & canvas accents
│   │       ├── forma_theme.dart           // Light and dark ThemeData configurations
│   │       ├── neumorphic.dart            // Neumorphic widget library (NeuCard, NeuButton, etc.)
│   │       └── responsive_breakpoints.dart// Phone portrait, phone landscape, tablet/desktop
│   ├── core/
│   │   ├── geometry/
│   │   │   ├── transform2d.dart           // Canvas pan/zoom coordinate transformations & math
│   │   │   └── geometry_utils.dart        // Hit-testing, 9 handles, collective bounds, snapping
│   │   ├── history/
│   │   │   ├── command.dart               // Command pattern (Add, Delete, Move, Update, Batch)
│   │   │   └── history_manager.dart       // Undo/redo stacks, limits, and transactions
│   │   ├── persistence/
│   │   │   └── project_repository.dart    // Cross-platform debounced local storage & recovery
│   │   └── export/
│   │       ├── png_exporter.dart          // PictureRecorder offscreen rasterizer (1x, 2x, 3x)
│   │       ├── svg_exporter.dart          // Clean vector SVG XML exporter with escaping
│   │       ├── pdf_exporter.dart          // PDF document generation
│   │       └── code_exporter.dart         // CSS and Flutter widget snippet generators
│   ├── domain/
│   │   ├── models/
│   │   │   ├── project_model.dart         // Versioned project schema, nodes, pages, tokens, flows
│   │   │   ├── page_model.dart            // Page metadata, backgrounds, grid & snap settings
│   │   │   ├── node_model.dart            // DesignNode (geometry, fills, strokes, effects, etc.)
│   │   │   ├── node_types.dart            // 16 node types (frame, rect, oval, text, star, etc.)
│   │   │   ├── paint_styles.dart          // Fills, strokes, shadows, corner radii
│   │   │   ├── layout_config.dart         // AutoLayout configuration (flex, gaps, padding)
│   │   │   ├── constraints.dart           // Horizontal & vertical responsive constraints
│   │   │   ├── vector_data.dart           // Bézier anchors, handles, and path generation
│   │   │   ├── text_data.dart             // Typography data (font, weight, letter spacing)
│   │   │   ├── tokens_model.dart          // Design tokens (colors, spacing, radii)
│   │   │   ├── prototype_model.dart       // Prototype flows, interactions, and triggers
│   │   │   └── comment_model.dart         // Canvas annotations and threaded replies
│   │   └── services/
│   │       ├── node_render_service.dart   // Unified offscreen & canvas node renderer
│   │       └── layout_engine.dart         // Auto-layout and constraint resizing calculations
│   └── features/
│       ├── home/
│       │   └── screens/home_screen.dart   // Projects gallery, search, favorites, new project
│       ├── templates/
│       │   └── template_service.dart      // 12 editable real-object templates
│       └── editor/
│           ├── controllers/
│           │   ├── editor_state.dart      // Immutable editor state (tool, zoom, selection)
│           │   └── editor_controller.dart // StateNotifier controller with undoable operations
│           ├── screens/
│           │   └── editor_screen.dart     // Adaptive phone/tablet responsive workspace shell
│           └── widgets/
│               ├── canvas/
│               │   ├── canvas_painter.dart // CustomPainter for nodes, handles, grid, guides
│               │   └── canvas_viewport.dart// Gestures, pan/zoom, marquee, and top/left rulers
│               ├── panels/
│               │   ├── layers_panel.dart  // Hierarchical layer tree with locks and visibility
│               │   ├── properties_panel.dart // Geometry, auto-layout, fills, WCAG contrast
│               │   └── inspector_panel.dart// Live CSS & Flutter code snippet generator
│               ├── prototype/
│               │   └── prototype_player.dart// Device frame mockup player with orientation toggle
│               └── dialogs/
│                   ├── export_dialog.dart // PNG, SVG, PDF, Native JSON exporter dialog
│                   ├── command_palette.dart// Searchable quick-action command palette (Ctrl+K)
│                   └── color_picker_dialog.dart// Soft neumorphic HSL/RGB/HEX color picker
└── test/
    ├── unit/
    │   ├── document_model_test.dart       // Serialization & node data tests
    │   ├── geometry_test.dart             // Transform2D, bounding boxes, handles, snapping
    │   ├── history_command_test.dart      // Add, Move, Undo/Redo commands
    │   ├── layout_engine_test.dart        // Auto-layout computation & responsive constraints
    │   └── svg_export_test.dart           // Valid SVG XML generation tests
    └── widget/
        ├── editor_interaction_test.dart   // Editor canvas, layers, and properties widget test
        └── widget_test.dart               // App initialization smoke test
```

---

## 📱 Responsive Layouts

Forma Studio dynamically adapts to screen constraints:
- **Portrait Mobile (<600px width)**:
  - Compact header with project title and quick actions.
  - Full-screen pannable & zoomable canvas.
  - Floating bottom dock with tool selection.
  - Slide-up bottom sheets for Layers and Properties panels.
- **Landscape Mobile**:
  - Expanded canvas with compact tool rail and contextual drawer.
- **Tablet / Desktop (≥800px width)**:
  - Professional 3-pane layout:
    - Left: Collapsible hierarchical Layers & Pages panel.
    - Center: Interactive Canvas with coordinate rulers, smart guides, and selection overlays.
    - Right: Contextual Properties Inspector & Live Dev Inspector.
    - Top: Full toolbar with tools, zoom presets, prototype player, and export options.

---

## 🚀 Running the App

### Running on Chrome or Edge (Web)
```bash
flutter run -d chrome
```

### Running on Windows Desktop (requires Visual Studio C++ toolchain)
```bash
flutter run -d windows
```

### Running on Connected Android or iOS Devices
```bash
flutter run -d <device-id>
```

### Running Tests
```bash
flutter test
```

### Static Analysis
```bash
flutter analyze
```

---

## 📄 License & Attribution
Free and open-source UI/UX design tool built with Flutter and Dart. Designed with a soft blue-gray neumorphic aesthetic inspired by modern minimalist design dashboards.
