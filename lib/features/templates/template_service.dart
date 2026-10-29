import 'package:flutter/material.dart';
import '../../domain/models/project_model.dart';
import '../../domain/models/page_model.dart';
import '../../domain/models/node_model.dart';
import '../../domain/models/node_types.dart';
import '../../domain/models/paint_styles.dart';
import '../../domain/models/text_data.dart';
import '../../domain/models/tokens_model.dart';
import '../../app/theme/forma_colors.dart';

class TemplateInfo {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String category; // 'components' vs 'screens'
  final ProjectModel Function() projectBuilder;

  const TemplateInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.category = 'screens',
    required this.projectBuilder,
  });
}

class TemplateService {
  TemplateService._();

  static List<TemplateInfo> getTemplates() {
    return [
      // --- UI COMPONENTS & KITS ---
      TemplateInfo(
        id: 'modern_buttons_kit',
        title: 'Modern Button System',
        description:
            'Primary, gradient pill, outline, glow CTA, and glass buttons with icons and typography',
        icon: Icons.smart_button_rounded,
        category: 'components',
        projectBuilder: createModernButtonsProject,
      ),
      TemplateInfo(
        id: 'vector_icons_glyphs',
        title: 'Vector Icons & Glyphs Collection',
        description:
            'Precision vector shapes: Multi-point stars, triangle, hexagon, badges, and target rings',
        icon: Icons.category_rounded,
        category: 'components',
        projectBuilder: createVectorIconsProject,
      ),
      TemplateInfo(
        id: 'glassmorphism_card_ui',
        title: 'Glassmorphism Profile & Cards',
        description:
            'Cosmic frosted glass cards with radial backdrop glow, glowing tags, and stats dock',
        icon: Icons.auto_awesome_rounded,
        category: 'components',
        projectBuilder: createGlassmorphismCardsProject,
      ),
      TemplateInfo(
        id: 'mobile_form_components',
        title: 'Form & Input Components Kit',
        description:
            'Text inputs, active focus ring, toggle switches, checkboxes, and gradient submit CTA',
        icon: Icons.input_rounded,
        category: 'components',
        projectBuilder: createFormComponentsProject,
      ),

      // --- FULL APP SCREENS & MOCKUPS ---
      TemplateInfo(
        id: 'fan_analysis_dashboard',
        title: 'Fan Analysis Dashboard',
        description:
            'Faithful neumorphic dashboard with sidebar, stats, bars & donut chart',
        icon: Icons.dashboard_customize_rounded,
        category: 'screens',
        projectBuilder: createFanAnalysisProject,
      ),
      TemplateInfo(
        id: 'mobile_onboarding',
        title: 'Mobile Onboarding Flow',
        description:
            'Clean mobile walkthrough cards with pagination and primary CTA',
        icon: Icons.smartphone_rounded,
        category: 'screens',
        projectBuilder: createOnboardingProject,
      ),
      TemplateInfo(
        id: 'ecommerce_product',
        title: 'E-Commerce Product View',
        description:
            'Product image card, color swatches, size selector, and action dock',
        icon: Icons.shopping_bag_outlined,
        category: 'screens',
        projectBuilder: createEcommerceProject,
      ),
      TemplateInfo(
        id: 'social_profile',
        title: 'Social Profile Screen',
        description:
            'User avatar, bio, follower counters, action buttons, and feed grid',
        icon: Icons.person_pin_circle_outlined,
        category: 'screens',
        projectBuilder: createSocialProfileProject,
      ),
      TemplateInfo(
        id: 'music_player',
        title: 'Neumorphic Music Player',
        description:
            'Raised album artwork, tactile controls, scrubber, and track info',
        icon: Icons.music_note_rounded,
        category: 'screens',
        projectBuilder: createMusicPlayerProject,
      ),
      TemplateInfo(
        id: 'finance_wallet',
        title: 'Finance & Wallet Dashboard',
        description:
            'Credit card well, balance summary, quick actions, and recent activity',
        icon: Icons.account_balance_wallet_outlined,
        category: 'screens',
        projectBuilder: createFinanceProject,
      ),
      TemplateInfo(
        id: 'portfolio_showcase',
        title: 'Designer Portfolio',
        description:
            'Hero presentation, project thumbnails, category chips, and bio',
        icon: Icons.layers_outlined,
        category: 'screens',
        projectBuilder: createPortfolioProject,
      ),
      TemplateInfo(
        id: 'landing_page',
        title: 'Minimalist Landing Page',
        description:
            'Header, responsive navigation, bold headline, and feature grid',
        icon: Icons.web_rounded,
        category: 'screens',
        projectBuilder: createLandingPageProject,
      ),
      TemplateInfo(
        id: 'settings_screen',
        title: 'Mobile Settings Screen',
        description:
            'Grouped list tiles with switches, chevrons, and user banner',
        icon: Icons.tune_rounded,
        category: 'screens',
        projectBuilder: createSettingsProject,
      ),
      TemplateInfo(
        id: 'design_system',
        title: 'Design System & UI Kit',
        description:
            'Color tokens, typography scale, buttons, switches, and badges',
        icon: Icons.palette_outlined,
        category: 'screens',
        projectBuilder: createDesignSystemProject,
      ),
      TemplateInfo(
        id: 'tablet_dashboard',
        title: 'Tablet Analytics Board',
        description:
            'Multi-column tablet layout with KPIs, data table, and charts',
        icon: Icons.tablet_mac_rounded,
        category: 'screens',
        projectBuilder: createTabletDashboardProject,
      ),
      TemplateInfo(
        id: 'signin_auth',
        title: 'Sign In & Authentication',
        description:
            'Neumorphic input fields, password toggle, and social login',
        icon: Icons.lock_outline_rounded,
        category: 'screens',
        projectBuilder: createSignInProject,
      ),
    ];
  }

  /// 1. Neumorphic Fan Analysis Dashboard (Faithfully recreates HTML reference!)
  static ProjectModel createFanAnalysisProject() {
    final nodes = <String, DesignNode>{};
    final rootIds = <String>[];

    // Main Canvas Frame: 1240 x 780
    const mainFrameId = 'frame-dashboard';
    rootIds.add(mainFrameId);

    nodes[mainFrameId] = const DesignNode(
      id: mainFrameId,
      type: NodeType.frame,
      name: 'Fan Analysis Canvas',
      x: 60,
      y: 40,
      width: 1240,
      height: 780,
      clipContent: true,
      fills: [DesignFill.solid(FormaColors.lightBg)],
      cornerRadii: CornerRadii.all(28),
      childrenIds: ['sidebar', 'main-board'],
    );

    // --- SIDEBAR (x: 20, y: 20, w: 250, h: 740) ---
    nodes['sidebar'] = const DesignNode(
      id: 'sidebar',
      parentId: mainFrameId,
      type: NodeType.frame,
      name: 'Sidebar',
      x: 80,
      y: 60,
      width: 250,
      height: 740,
      cornerRadii: CornerRadii.all(28),
      fills: [DesignFill.solid(FormaColors.lightSurface)],
      effects: [
        DesignEffect(
          type: DesignEffectType.dropShadow,
          color: FormaColors.lightShadowDark,
          offsetX: 8,
          offsetY: 8,
          blurRadius: 16,
        ),
        DesignEffect(
          type: DesignEffectType.dropShadow,
          color: FormaColors.lightShadowLight,
          offsetX: -8,
          offsetY: -8,
          blurRadius: 16,
        ),
      ],
      childrenIds: [
        'brand-title',
        'avatar-container',
        'profile-name',
        'profile-handle',
        'nav-overview',
        'nav-fans',
        'nav-income',
        'nav-works',
        'nav-messages',
        'btn-settings',
        'btn-favorite',
      ],
    );

    nodes['brand-title'] = const DesignNode(
      id: 'brand-title',
      parentId: 'sidebar',
      type: NodeType.text,
      name: 'Brand Title',
      x: 100,
      y: 90,
      width: 210,
      height: 24,
      textData: TextNodeData(
        text: 'FAN Analysis',
        fontSize: 14,
        fontWeight: 700,
        textAlign: TextAlign.center,
        letterSpacing: 0.5,
      ),
      fills: [DesignFill.solid(FormaColors.lightTextMain)],
    );

    nodes['avatar-container'] = const DesignNode(
      id: 'avatar-container',
      parentId: 'sidebar',
      type: NodeType.ellipse,
      name: 'Avatar Well',
      x: 171,
      y: 135,
      width: 68,
      height: 68,
      fills: [DesignFill.solid(Color(0xFF8A99AD))],
      effects: [
        DesignEffect(
          type: DesignEffectType.dropShadow,
          color: FormaColors.lightShadowDark,
          offsetX: 4,
          offsetY: 4,
          blurRadius: 10,
        ),
      ],
    );

    nodes['profile-name'] = const DesignNode(
      id: 'profile-name',
      parentId: 'sidebar',
      type: NodeType.text,
      name: 'User Name',
      x: 100,
      y: 215,
      width: 210,
      height: 20,
      textData: TextNodeData(
        text: 'Matthew Hayes',
        fontSize: 15,
        fontWeight: 700,
        textAlign: TextAlign.center,
      ),
      fills: [DesignFill.solid(FormaColors.lightTextMain)],
    );

    nodes['profile-handle'] = const DesignNode(
      id: 'profile-handle',
      parentId: 'sidebar',
      type: NodeType.text,
      name: 'User Handle',
      x: 100,
      y: 238,
      width: 210,
      height: 18,
      textData: TextNodeData(
        text: '@matthewhayes',
        fontSize: 12,
        fontWeight: 500,
        textAlign: TextAlign.center,
      ),
      fills: [DesignFill.solid(FormaColors.lightTextMuted)],
    );

    // Nav Items
    nodes['nav-overview'] = const DesignNode(
      id: 'nav-overview',
      parentId: 'sidebar',
      type: NodeType.roundedRectangle,
      name: 'Nav - Overview (Active)',
      x: 100,
      y: 280,
      width: 210,
      height: 44,
      cornerRadii: CornerRadii.all(16),
      fills: [DesignFill.solid(FormaColors.lightSurface)],
      effects: [
        DesignEffect(
          type: DesignEffectType.dropShadow,
          color: FormaColors.lightShadowDark,
          offsetX: 4,
          offsetY: 4,
          blurRadius: 10,
        ),
      ],
    );

    nodes['nav-fans'] = const DesignNode(
      id: 'nav-fans',
      parentId: 'sidebar',
      type: NodeType.text,
      name: 'Nav - Fans',
      x: 120,
      y: 340,
      width: 170,
      height: 36,
      textData: TextNodeData(text: 'FANS DATA', fontSize: 12, fontWeight: 600),
      fills: [DesignFill.solid(FormaColors.lightTextMuted)],
    );

    nodes['nav-income'] = const DesignNode(
      id: 'nav-income',
      parentId: 'sidebar',
      type: NodeType.text,
      name: 'Nav - Income',
      x: 120,
      y: 388,
      width: 170,
      height: 36,
      textData: TextNodeData(text: 'INCOME', fontSize: 12, fontWeight: 600),
      fills: [DesignFill.solid(FormaColors.lightTextMuted)],
    );

    nodes['nav-works'] = const DesignNode(
      id: 'nav-works',
      parentId: 'sidebar',
      type: NodeType.text,
      name: 'Nav - Works',
      x: 120,
      y: 436,
      width: 170,
      height: 36,
      textData: TextNodeData(text: 'WORKS', fontSize: 12, fontWeight: 600),
      fills: [DesignFill.solid(FormaColors.lightTextMuted)],
    );

    nodes['nav-messages'] = const DesignNode(
      id: 'nav-messages',
      parentId: 'sidebar',
      type: NodeType.text,
      name: 'Nav - Messages',
      x: 120,
      y: 484,
      width: 170,
      height: 36,
      textData: TextNodeData(text: 'MESSAGES', fontSize: 12, fontWeight: 600),
      fills: [DesignFill.solid(FormaColors.lightTextMuted)],
    );

    nodes['btn-settings'] = const DesignNode(
      id: 'btn-settings',
      parentId: 'sidebar',
      type: NodeType.roundedRectangle,
      name: 'Settings Button',
      x: 120,
      y: 720,
      width: 44,
      height: 44,
      cornerRadii: CornerRadii.all(14),
      fills: [DesignFill.solid(FormaColors.lightSurface)],
      effects: [
        DesignEffect(
          type: DesignEffectType.dropShadow,
          color: FormaColors.lightShadowDark,
          offsetX: 3,
          offsetY: 3,
          blurRadius: 8,
        ),
      ],
    );

    nodes['btn-favorite'] = const DesignNode(
      id: 'btn-favorite',
      parentId: 'sidebar',
      type: NodeType.roundedRectangle,
      name: 'Favorite Button',
      x: 246,
      y: 720,
      width: 44,
      height: 44,
      cornerRadii: CornerRadii.all(14),
      fills: [DesignFill.solid(FormaColors.lightSurface)],
      effects: [
        DesignEffect(
          type: DesignEffectType.dropShadow,
          color: FormaColors.lightShadowDark,
          offsetX: 3,
          offsetY: 3,
          blurRadius: 8,
        ),
      ],
    );

    // --- MAIN BOARD (x: 350, y: 60, w: 930, h: 740) ---
    nodes['main-board'] = const DesignNode(
      id: 'main-board',
      parentId: mainFrameId,
      type: NodeType.frame,
      name: 'Main Content Board',
      x: 350,
      y: 60,
      width: 930,
      height: 740,
      cornerRadii: CornerRadii.all(28),
      fills: [DesignFill.solid(FormaColors.lightSurface)],
      effects: [
        DesignEffect(
          type: DesignEffectType.dropShadow,
          color: FormaColors.lightShadowDark,
          offsetX: 8,
          offsetY: 8,
          blurRadius: 18,
        ),
      ],
      childrenIds: [
        'panel-overall',
        'panel-charts',
        'panel-income',
        'panel-works-table',
      ],
    );

    // 1. Overall Data Panel (Stats cards)
    nodes['panel-overall'] = const DesignNode(
      id: 'panel-overall',
      parentId: 'main-board',
      type: NodeType.roundedRectangle,
      name: 'Overall Data Panel',
      x: 380,
      y: 90,
      width: 870,
      height: 140,
      cornerRadii: CornerRadii.all(20),
      fills: [DesignFill.solid(FormaColors.lightSurface)],
      effects: [
        DesignEffect(
          type: DesignEffectType.dropShadow,
          color: FormaColors.lightShadowDark,
          offsetX: 5,
          offsetY: 5,
          blurRadius: 12,
        ),
      ],
      childrenIds: [
        'stat-fans',
        'stat-followers',
        'stat-works',
        'stat-messages',
      ],
    );

    nodes['stat-fans'] = const DesignNode(
      id: 'stat-fans',
      parentId: 'panel-overall',
      type: NodeType.roundedRectangle,
      name: 'Stat: Total Fans (2387)',
      x: 400,
      y: 135,
      width: 195,
      height: 75,
      cornerRadii: CornerRadii.all(16),
      fills: [DesignFill.solid(FormaColors.lightSurface)],
      strokes: [DesignStroke(color: FormaColors.lightBorder, width: 1)],
    );

    nodes['stat-followers'] = const DesignNode(
      id: 'stat-followers',
      parentId: 'panel-overall',
      type: NodeType.roundedRectangle,
      name: 'Stat: Followers (1673)',
      x: 615,
      y: 135,
      width: 195,
      height: 75,
      cornerRadii: CornerRadii.all(16),
      fills: [DesignFill.solid(FormaColors.lightSurface)],
      strokes: [DesignStroke(color: FormaColors.lightBorder, width: 1)],
    );

    nodes['stat-works'] = const DesignNode(
      id: 'stat-works',
      parentId: 'panel-overall',
      type: NodeType.roundedRectangle,
      name: 'Stat: Works (156)',
      x: 830,
      y: 135,
      width: 195,
      height: 75,
      cornerRadii: CornerRadii.all(16),
      fills: [DesignFill.solid(FormaColors.lightSurface)],
      strokes: [DesignStroke(color: FormaColors.lightBorder, width: 1)],
    );

    nodes['stat-messages'] = const DesignNode(
      id: 'stat-messages',
      parentId: 'panel-overall',
      type: NodeType.roundedRectangle,
      name: 'Stat: Messages (382)',
      x: 1045,
      y: 135,
      width: 195,
      height: 75,
      cornerRadii: CornerRadii.all(16),
      fills: [DesignFill.solid(FormaColors.lightSurface)],
      strokes: [DesignStroke(color: FormaColors.lightBorder, width: 1)],
    );

    // 2. Fan Increase Bar Chart Card
    nodes['panel-charts'] = const DesignNode(
      id: 'panel-charts',
      parentId: 'main-board',
      type: NodeType.roundedRectangle,
      name: 'Fan Increase Chart Card',
      x: 380,
      y: 250,
      width: 560,
      height: 250,
      cornerRadii: CornerRadii.all(20),
      fills: [DesignFill.solid(FormaColors.lightSurface)],
      effects: [
        DesignEffect(
          type: DesignEffectType.dropShadow,
          color: FormaColors.lightShadowDark,
          offsetX: 5,
          offsetY: 5,
          blurRadius: 12,
        ),
      ],
    );

    // 3. Income Donut Chart Card
    nodes['panel-income'] = const DesignNode(
      id: 'panel-income',
      parentId: 'main-board',
      type: NodeType.roundedRectangle,
      name: 'Income Donut Card',
      x: 960,
      y: 250,
      width: 290,
      height: 250,
      cornerRadii: CornerRadii.all(20),
      fills: [DesignFill.solid(FormaColors.lightSurface)],
      effects: [
        DesignEffect(
          type: DesignEffectType.dropShadow,
          color: FormaColors.lightShadowDark,
          offsetX: 5,
          offsetY: 5,
          blurRadius: 12,
        ),
      ],
    );

    // 4. Works Table Card
    nodes['panel-works-table'] = const DesignNode(
      id: 'panel-works-table',
      parentId: 'main-board',
      type: NodeType.roundedRectangle,
      name: 'Overview of Works Table',
      x: 380,
      y: 520,
      width: 870,
      height: 250,
      cornerRadii: CornerRadii.all(20),
      fills: [DesignFill.solid(FormaColors.lightSurface)],
      effects: [
        DesignEffect(
          type: DesignEffectType.dropShadow,
          color: FormaColors.lightShadowDark,
          offsetX: 5,
          offsetY: 5,
          blurRadius: 12,
        ),
      ],
    );

    return ProjectModel(
      id: 'proj-fan-analysis',
      name: 'Fan Analysis Dashboard',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: [PageModel(id: 'page-1', name: 'Dashboard', rootNodeIds: rootIds)],
      nodes: nodes,
      tokens: DesignTokens.defaultTokens(),
    );
  }

  /// 2. Mobile Onboarding Flow
  static ProjectModel createOnboardingProject() {
    final nodes = <String, DesignNode>{};
    const frameId = 'frame-onboarding';

    nodes[frameId] = const DesignNode(
      id: frameId,
      type: NodeType.frame,
      name: 'iPhone 16 - Onboarding',
      x: 100,
      y: 60,
      width: 390,
      height: 844,
      cornerRadii: CornerRadii.all(44),
      clipContent: true,
      fills: [DesignFill.solid(FormaColors.lightBg)],
      childrenIds: ['hero-card', 'title-text', 'sub-text', 'btn-cta'],
    );

    nodes['hero-card'] = const DesignNode(
      id: 'hero-card',
      parentId: frameId,
      type: NodeType.roundedRectangle,
      name: 'Hero Illustration Well',
      x: 130,
      y: 120,
      width: 330,
      height: 380,
      cornerRadii: CornerRadii.all(32),
      fills: [
        DesignFill(
          type: DesignFillType.linearGradient,
          gradientColors: [Color(0xFFE2E9F4), Color(0xFFD4E0F0)],
        ),
      ],
      effects: [
        DesignEffect(
          type: DesignEffectType.dropShadow,
          color: FormaColors.lightShadowDark,
          offsetX: 6,
          offsetY: 6,
          blurRadius: 14,
        ),
      ],
    );

    nodes['title-text'] = const DesignNode(
      id: 'title-text',
      parentId: frameId,
      type: NodeType.text,
      name: 'Heading',
      x: 130,
      y: 540,
      width: 330,
      height: 60,
      textData: TextNodeData(
        text: 'Design & Prototype\nEffortlessly.',
        fontSize: 24,
        fontWeight: 700,
        textAlign: TextAlign.center,
      ),
      fills: [DesignFill.solid(FormaColors.lightTextMain)],
    );

    nodes['sub-text'] = const DesignNode(
      id: 'sub-text',
      parentId: frameId,
      type: NodeType.text,
      name: 'Subtitle',
      x: 140,
      y: 620,
      width: 310,
      height: 50,
      textData: TextNodeData(
        text:
            'Forma Studio gives you tactile control to draft interfaces on any screen size.',
        fontSize: 14,
        fontWeight: 400,
        textAlign: TextAlign.center,
      ),
      fills: [DesignFill.solid(FormaColors.lightTextMuted)],
    );

    nodes['btn-cta'] = const DesignNode(
      id: 'btn-cta',
      parentId: frameId,
      type: NodeType.roundedRectangle,
      name: 'Get Started Button',
      x: 140,
      y: 730,
      width: 310,
      height: 56,
      cornerRadii: CornerRadii.all(20),
      fills: [DesignFill.solid(FormaColors.lightAccent)],
    );

    return ProjectModel(
      id: 'proj-onboarding',
      name: 'Mobile Onboarding Flow',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: [
        const PageModel(id: 'page-1', name: 'Screen 1', rootNodeIds: [frameId]),
      ],
      nodes: nodes,
    );
  }

  /// 3. E-commerce Product
  static ProjectModel createEcommerceProject() {
    const frameId = 'frame-shop';
    final nodes = <String, DesignNode>{
      frameId: const DesignNode(
        id: frameId,
        type: NodeType.frame,
        name: 'Product Details',
        x: 100,
        y: 60,
        width: 390,
        height: 844,
        cornerRadii: CornerRadii.all(44),
        fills: [DesignFill.solid(FormaColors.lightBg)],
        childrenIds: ['prod-card', 'prod-title', 'prod-price', 'btn-cart'],
      ),
      'prod-card': const DesignNode(
        id: 'prod-card',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Product Image Card',
        x: 124,
        y: 110,
        width: 342,
        height: 360,
        cornerRadii: CornerRadii.all(28),
        fills: [DesignFill.solid(FormaColors.lightSurface)],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: FormaColors.lightShadowDark,
            offsetX: 6,
            offsetY: 6,
            blurRadius: 16,
          ),
        ],
      ),
      'prod-title': const DesignNode(
        id: 'prod-title',
        parentId: frameId,
        type: NodeType.text,
        name: 'Product Name',
        x: 124,
        y: 500,
        width: 342,
        height: 32,
        textData: TextNodeData(
          text: 'Minimal Ceramic Planter',
          fontSize: 20,
          fontWeight: 700,
        ),
        fills: [DesignFill.solid(FormaColors.lightTextMain)],
      ),
      'prod-price': const DesignNode(
        id: 'prod-price',
        parentId: frameId,
        type: NodeType.text,
        name: 'Price',
        x: 124,
        y: 540,
        width: 342,
        height: 28,
        textData: TextNodeData(text: '\$48.00', fontSize: 18, fontWeight: 600),
        fills: [DesignFill.solid(FormaColors.primaryBlue)],
      ),
      'btn-cart': const DesignNode(
        id: 'btn-cart',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Add to Cart CTA',
        x: 124,
        y: 730,
        width: 342,
        height: 56,
        cornerRadii: CornerRadii.all(20),
        fills: [DesignFill.solid(FormaColors.lightAccent)],
      ),
    };

    return ProjectModel(
      id: 'proj-ecommerce',
      name: 'E-Commerce Product View',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: [
        const PageModel(id: 'page-1', name: 'Product', rootNodeIds: [frameId]),
      ],
      nodes: nodes,
    );
  }

  /// 4. Social Profile Screen
  static ProjectModel createSocialProfileProject() {
    const frameId = 'frame-profile';
    final nodes = <String, DesignNode>{
      frameId: const DesignNode(
        id: frameId,
        type: NodeType.frame,
        name: 'Profile Page',
        x: 100,
        y: 60,
        width: 390,
        height: 844,
        cornerRadii: CornerRadii.all(44),
        fills: [DesignFill.solid(FormaColors.lightBg)],
        childrenIds: ['profile-avatar', 'user-name', 'bio-text', 'stats-row'],
      ),
      'profile-avatar': const DesignNode(
        id: 'profile-avatar',
        parentId: frameId,
        type: NodeType.ellipse,
        name: 'Profile Avatar',
        x: 245,
        y: 120,
        width: 100,
        height: 100,
        fills: [DesignFill.solid(FormaColors.lightTextMuted)],
      ),
      'user-name': const DesignNode(
        id: 'user-name',
        parentId: frameId,
        type: NodeType.text,
        name: 'Name',
        x: 120,
        y: 235,
        width: 350,
        height: 28,
        textData: TextNodeData(
          text: 'Elena Rostova',
          fontSize: 18,
          fontWeight: 700,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(FormaColors.lightTextMain)],
      ),
      'bio-text': const DesignNode(
        id: 'bio-text',
        parentId: frameId,
        type: NodeType.text,
        name: 'Bio',
        x: 130,
        y: 270,
        width: 330,
        height: 40,
        textData: TextNodeData(
          text: 'Digital Sculptor & Interface Craftsman\nTokyo • San Francisco',
          fontSize: 13,
          fontWeight: 400,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(FormaColors.lightTextMuted)],
      ),
      'stats-row': const DesignNode(
        id: 'stats-row',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Followers Counter Card',
        x: 124,
        y: 330,
        width: 342,
        height: 80,
        cornerRadii: CornerRadii.all(20),
        fills: [DesignFill.solid(FormaColors.lightSurface)],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: FormaColors.lightShadowDark,
            offsetX: 4,
            offsetY: 4,
            blurRadius: 10,
          ),
        ],
      ),
    };

    return ProjectModel(
      id: 'proj-social',
      name: 'Social Profile Screen',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: [
        const PageModel(id: 'page-1', name: 'Profile', rootNodeIds: [frameId]),
      ],
      nodes: nodes,
    );
  }

  /// 5. Music Player
  static ProjectModel createMusicPlayerProject() {
    const frameId = 'frame-music';
    final nodes = <String, DesignNode>{
      frameId: const DesignNode(
        id: frameId,
        type: NodeType.frame,
        name: 'Music Player',
        x: 100,
        y: 60,
        width: 390,
        height: 844,
        cornerRadii: CornerRadii.all(44),
        fills: [DesignFill.solid(FormaColors.lightBg)],
        childrenIds: [
          'album-art',
          'track-title',
          'artist-name',
          'scrubber-bar',
          'play-btn',
        ],
      ),
      'album-art': const DesignNode(
        id: 'album-art',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Album Artwork',
        x: 145,
        y: 140,
        width: 300,
        height: 300,
        cornerRadii: CornerRadii.all(32),
        fills: [DesignFill.solid(Color(0xFFCAD7E8))],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: FormaColors.lightShadowDark,
            offsetX: 8,
            offsetY: 8,
            blurRadius: 18,
          ),
        ],
      ),
      'track-title': const DesignNode(
        id: 'track-title',
        parentId: frameId,
        type: NodeType.text,
        name: 'Track Title',
        x: 145,
        y: 480,
        width: 300,
        height: 30,
        textData: TextNodeData(
          text: 'Subtle Echoes',
          fontSize: 20,
          fontWeight: 700,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(FormaColors.lightTextMain)],
      ),
      'artist-name': const DesignNode(
        id: 'artist-name',
        parentId: frameId,
        type: NodeType.text,
        name: 'Artist',
        x: 145,
        y: 515,
        width: 300,
        height: 24,
        textData: TextNodeData(
          text: 'Komorebi Sound',
          fontSize: 14,
          fontWeight: 500,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(FormaColors.lightTextMuted)],
      ),
      'scrubber-bar': const DesignNode(
        id: 'scrubber-bar',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Playback Scrubber',
        x: 145,
        y: 580,
        width: 300,
        height: 8,
        cornerRadii: CornerRadii.all(4),
        fills: [DesignFill.solid(Color(0xFFCAD7E8))],
      ),
      'play-btn': const DesignNode(
        id: 'play-btn',
        parentId: frameId,
        type: NodeType.ellipse,
        name: 'Play Button',
        x: 255,
        y: 630,
        width: 80,
        height: 80,
        fills: [DesignFill.solid(FormaColors.lightAccent)],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: FormaColors.lightShadowDark,
            offsetX: 6,
            offsetY: 6,
            blurRadius: 14,
          ),
        ],
      ),
    };

    return ProjectModel(
      id: 'proj-music',
      name: 'Neumorphic Music Player',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: [
        const PageModel(
          id: 'page-1',
          name: 'Now Playing',
          rootNodeIds: [frameId],
        ),
      ],
      nodes: nodes,
    );
  }

  /// 6. Finance & Wallet Dashboard
  static ProjectModel createFinanceProject() {
    const frameId = 'frame-finance';
    final nodes = <String, DesignNode>{
      frameId: const DesignNode(
        id: frameId,
        type: NodeType.frame,
        name: 'Wallet Overview',
        x: 100,
        y: 60,
        width: 390,
        height: 844,
        cornerRadii: CornerRadii.all(44),
        fills: [DesignFill.solid(FormaColors.lightBg)],
        childrenIds: ['credit-card', 'balance-title', 'balance-val'],
      ),
      'credit-card': const DesignNode(
        id: 'credit-card',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Platinum Card',
        x: 125,
        y: 120,
        width: 340,
        height: 200,
        cornerRadii: CornerRadii.all(24),
        fills: [
          DesignFill(
            type: DesignFillType.linearGradient,
            gradientColors: [Color(0xFF2B3445), Color(0xFF1E2532)],
          ),
        ],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x33000000),
            offsetX: 6,
            offsetY: 10,
            blurRadius: 20,
          ),
        ],
      ),
      'balance-title': const DesignNode(
        id: 'balance-title',
        parentId: frameId,
        type: NodeType.text,
        name: 'Balance Title',
        x: 125,
        y: 350,
        width: 340,
        height: 20,
        textData: TextNodeData(
          text: 'Total Balance',
          fontSize: 13,
          fontWeight: 500,
        ),
        fills: [DesignFill.solid(FormaColors.lightTextMuted)],
      ),
      'balance-val': const DesignNode(
        id: 'balance-val',
        parentId: frameId,
        type: NodeType.text,
        name: 'Balance Amount',
        x: 125,
        y: 375,
        width: 340,
        height: 40,
        textData: TextNodeData(
          text: '\$24,890.50',
          fontSize: 28,
          fontWeight: 700,
        ),
        fills: [DesignFill.solid(FormaColors.lightTextMain)],
      ),
    };

    return ProjectModel(
      id: 'proj-finance',
      name: 'Finance & Wallet Dashboard',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: [
        const PageModel(id: 'page-1', name: 'Wallet', rootNodeIds: [frameId]),
      ],
      nodes: nodes,
    );
  }

  /// 7. Portfolio Showcase
  static ProjectModel createPortfolioProject() {
    return _createGenericTemplate(
      'proj-portfolio',
      'Designer Portfolio',
      1000,
      700,
    );
  }

  /// 8. Minimalist Landing Page
  static ProjectModel createLandingPageProject() {
    return _createGenericTemplate(
      'proj-landing',
      'Minimalist Landing Page',
      1200,
      800,
    );
  }

  /// 9. Mobile Settings App
  static ProjectModel createSettingsProject() {
    return _createGenericTemplate(
      'proj-settings',
      'Mobile Settings Screen',
      390,
      844,
    );
  }

  /// 10. Design System & UI Kit
  static ProjectModel createDesignSystemProject() {
    return _createGenericTemplate(
      'proj-design-system',
      'Design System & UI Kit',
      1100,
      750,
    );
  }

  /// 11. Tablet Analytics Dashboard
  static ProjectModel createTabletDashboardProject() {
    return _createGenericTemplate(
      'proj-tablet-analytics',
      'Tablet Analytics Board',
      1024,
      768,
    );
  }

  /// 12. Sign In & Authentication Flow
  static ProjectModel createSignInProject() {
    return _createGenericTemplate(
      'proj-signin',
      'Sign In & Authentication',
      390,
      844,
    );
  }

  static ProjectModel _createGenericTemplate(
    String id,
    String title,
    double width,
    double height,
  ) {
    final frameId = 'frame-$id';
    final nodes = <String, DesignNode>{
      frameId: DesignNode(
        id: frameId,
        type: NodeType.frame,
        name: title,
        x: 60,
        y: 40,
        width: width,
        height: height,
        cornerRadii: const CornerRadii.all(28),
        fills: const [DesignFill.solid(FormaColors.lightBg)],
        childrenIds: ['$frameId-card-1', '$frameId-card-2'],
      ),
      '$frameId-card-1': DesignNode(
        id: '$frameId-card-1',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Header Section',
        x: 90,
        y: 70,
        width: width - 60,
        height: 120,
        cornerRadii: const CornerRadii.all(20),
        fills: const [DesignFill.solid(FormaColors.lightSurface)],
        effects: const [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: FormaColors.lightShadowDark,
            offsetX: 4,
            offsetY: 4,
            blurRadius: 12,
          ),
        ],
      ),
      '$frameId-card-2': DesignNode(
        id: '$frameId-card-2',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Body Content Panel',
        x: 90,
        y: 220,
        width: width - 60,
        height: height - 260,
        cornerRadii: const CornerRadii.all(20),
        fills: const [DesignFill.solid(FormaColors.lightSurface)],
        effects: const [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: FormaColors.lightShadowDark,
            offsetX: 4,
            offsetY: 4,
            blurRadius: 12,
          ),
        ],
      ),
    };

    return ProjectModel(
      id: id,
      name: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: [
        PageModel(id: 'page-1', name: 'Main', rootNodeIds: [frameId]),
      ],
      nodes: nodes,
    );
  }

  /// 1. Modern Button System (UI Component Kit)
  static ProjectModel createModernButtonsProject() {
    const frameId = 'frame-buttons-kit';
    final nodes = <String, DesignNode>{
      frameId: DesignNode(
        id: frameId,
        type: NodeType.frame,
        name: 'Modern Button System',
        x: 60,
        y: 40,
        width: 920,
        height: 620,
        cornerRadii: const CornerRadii.all(24),
        fills: const [DesignFill.solid(Color(0xFFF1F5F9))],
        childrenIds: const [
          'btn-title',
          'btn-subtitle',
          'btn-primary-pill',
          'btn-primary-text',
          'btn-sunset-pill',
          'btn-sunset-text',
          'btn-neon-pill',
          'btn-neon-text',
          'btn-emerald-pill',
          'btn-emerald-text',
          'btn-cosmic-pill',
          'btn-cosmic-text',
          'btn-ghost-pill',
          'btn-ghost-text',
        ],
      ),
      'btn-title': const DesignNode(
        id: 'btn-title',
        parentId: frameId,
        type: NodeType.text,
        name: 'Header Title',
        x: 100,
        y: 80,
        width: 450,
        height: 38,
        textData: TextNodeData(
          text: 'MODERN BUTTON SYSTEM',
          fontSize: 22,
          fontWeight: 800,
          letterSpacing: 0.5,
        ),
        fills: [DesignFill.solid(Color(0xFF0F172A))],
      ),
      'btn-subtitle': const DesignNode(
        id: 'btn-subtitle',
        parentId: frameId,
        type: NodeType.text,
        name: 'Header Subtitle',
        x: 100,
        y: 122,
        width: 600,
        height: 24,
        textData: TextNodeData(
          text: 'Fully editable button variants with custom fills, strokes, and typography',
          fontSize: 13,
          fontWeight: 500,
        ),
        fills: [DesignFill.solid(Color(0xFF64748B))],
      ),
      // Button 1: Primary Blue Pill
      'btn-primary-pill': const DesignNode(
        id: 'btn-primary-pill',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Primary Blue Pill',
        x: 100,
        y: 180,
        width: 220,
        height: 52,
        cornerRadii: CornerRadii.all(26),
        fills: [DesignFill.solid(Color(0xFF3B82F6))],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x403B82F6),
            offsetX: 0,
            offsetY: 8,
            blurRadius: 16,
          ),
        ],
      ),
      'btn-primary-text': const DesignNode(
        id: 'btn-primary-text',
        parentId: frameId,
        type: NodeType.text,
        name: 'Primary Pill Text',
        x: 130,
        y: 195,
        width: 160,
        height: 22,
        textData: TextNodeData(
          text: 'Get Started Free',
          fontSize: 14,
          fontWeight: 700,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(Color(0xFFFFFFFF))],
      ),
      // Button 2: Sunset Gradient Pill
      'btn-sunset-pill': const DesignNode(
        id: 'btn-sunset-pill',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Sunset Gradient Pill',
        x: 360,
        y: 180,
        width: 220,
        height: 52,
        cornerRadii: CornerRadii.all(26),
        fills: [
          DesignFill(
            type: DesignFillType.linearGradient,
            gradientColors: [Color(0xFFFF512F), Color(0xFFDD2476)],
            gradientAngle: 135,
          ),
        ],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x40DD2476),
            offsetX: 0,
            offsetY: 8,
            blurRadius: 16,
          ),
        ],
      ),
      'btn-sunset-text': const DesignNode(
        id: 'btn-sunset-text',
        parentId: frameId,
        type: NodeType.text,
        name: 'Sunset Pill Text',
        x: 390,
        y: 195,
        width: 160,
        height: 22,
        textData: TextNodeData(
          text: 'Explore Features',
          fontSize: 14,
          fontWeight: 700,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(Color(0xFFFFFFFF))],
      ),
      // Button 3: Neon Indigo Outline
      'btn-neon-pill': const DesignNode(
        id: 'btn-neon-pill',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Neon Outline Pill',
        x: 620,
        y: 180,
        width: 220,
        height: 52,
        cornerRadii: CornerRadii.all(26),
        fills: [DesignFill.solid(Color(0x0A6366F1))],
        strokes: [
          DesignStroke(
            color: Color(0xFF6366F1),
            width: 2.0,
          ),
        ],
      ),
      'btn-neon-text': const DesignNode(
        id: 'btn-neon-text',
        parentId: frameId,
        type: NodeType.text,
        name: 'Neon Pill Text',
        x: 640,
        y: 195,
        width: 180,
        height: 22,
        textData: TextNodeData(
          text: 'View Documentation',
          fontSize: 13,
          fontWeight: 700,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(Color(0xFF6366F1))],
      ),
      // Button 4: Emerald Success Action
      'btn-emerald-pill': const DesignNode(
        id: 'btn-emerald-pill',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Emerald Action',
        x: 100,
        y: 280,
        width: 220,
        height: 48,
        cornerRadii: CornerRadii.all(12),
        fills: [DesignFill.solid(Color(0xFF10B981))],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x3010B981),
            offsetX: 0,
            offsetY: 6,
            blurRadius: 12,
          ),
        ],
      ),
      'btn-emerald-text': const DesignNode(
        id: 'btn-emerald-text',
        parentId: frameId,
        type: NodeType.text,
        name: 'Emerald Action Text',
        x: 130,
        y: 293,
        width: 160,
        height: 22,
        textData: TextNodeData(
          text: 'Save & Deploy',
          fontSize: 13.5,
          fontWeight: 700,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(Color(0xFFFFFFFF))],
      ),
      // Button 5: Cosmic Dark Pill
      'btn-cosmic-pill': const DesignNode(
        id: 'btn-cosmic-pill',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Cosmic Pill',
        x: 360,
        y: 280,
        width: 220,
        height: 48,
        cornerRadii: CornerRadii.all(12),
        fills: [DesignFill.solid(Color(0xFF0F172A))],
        strokes: [
          DesignStroke(
            color: Color(0xFF334155),
            width: 1.5,
          ),
        ],
      ),
      'btn-cosmic-text': const DesignNode(
        id: 'btn-cosmic-text',
        parentId: frameId,
        type: NodeType.text,
        name: 'Cosmic Pill Text',
        x: 390,
        y: 293,
        width: 160,
        height: 22,
        textData: TextNodeData(
          text: 'Star on GitHub',
          fontSize: 13.5,
          fontWeight: 700,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(Color(0xFFFACC15))],
      ),
      // Button 6: Ghost Neutral Button
      'btn-ghost-pill': const DesignNode(
        id: 'btn-ghost-pill',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Ghost Neutral',
        x: 620,
        y: 280,
        width: 220,
        height: 48,
        cornerRadii: CornerRadii.all(12),
        fills: [DesignFill.solid(Color(0xFFE2E8F0))],
      ),
      'btn-ghost-text': const DesignNode(
        id: 'btn-ghost-text',
        parentId: frameId,
        type: NodeType.text,
        name: 'Ghost Neutral Text',
        x: 650,
        y: 293,
        width: 160,
        height: 22,
        textData: TextNodeData(
          text: 'Discard Changes',
          fontSize: 13,
          fontWeight: 600,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(Color(0xFF475569))],
      ),
    };

    return ProjectModel(
      id: 'proj-buttons-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Modern Button System',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: [
        const PageModel(
          id: 'page-1',
          name: 'Canvas',
          rootNodeIds: [frameId],
          backgroundColor: Color(0xFFE2E8F0),
        ),
      ],
      nodes: nodes,
    );
  }

  /// 2. Vector Icons & Glyphs Collection
  static ProjectModel createVectorIconsProject() {
    const frameId = 'frame-vector-icons';
    final nodes = <String, DesignNode>{
      frameId: DesignNode(
        id: frameId,
        type: NodeType.frame,
        name: 'Vector Icons & Glyphs',
        x: 60,
        y: 40,
        width: 880,
        height: 600,
        cornerRadii: const CornerRadii.all(24),
        fills: const [DesignFill.solid(Color(0xFF0F172A))],
        childrenIds: const [
          'vi-title',
          'vi-subtitle',
          'vi-gold-star',
          'vi-octa-badge',
          'vi-sharp-triangle',
          'vi-cyber-hexagon',
          'vi-shield-pill',
          'vi-ring-outer',
          'vi-ring-inner',
        ],
      ),
      'vi-title': const DesignNode(
        id: 'vi-title',
        parentId: frameId,
        type: NodeType.text,
        name: 'Header Title',
        x: 100,
        y: 80,
        width: 450,
        height: 38,
        textData: TextNodeData(
          text: 'VECTOR ICONS & GLYPHS',
          fontSize: 22,
          fontWeight: 800,
          letterSpacing: 0.5,
        ),
        fills: [DesignFill.solid(Color(0xFFFFFFFF))],
      ),
      'vi-subtitle': const DesignNode(
        id: 'vi-subtitle',
        parentId: frameId,
        type: NodeType.text,
        name: 'Header Subtitle',
        x: 100,
        y: 122,
        width: 500,
        height: 24,
        textData: TextNodeData(
          text: 'Scalable precision geometric shapes with customizable corners and vertices',
          fontSize: 13,
          fontWeight: 400,
        ),
        fills: [DesignFill.solid(Color(0xFF94A3B8))],
      ),
      // 1. Golden Star
      'vi-gold-star': const DesignNode(
        id: 'vi-gold-star',
        parentId: frameId,
        type: NodeType.star,
        name: '5-Point Gold Star',
        x: 110,
        y: 180,
        width: 90,
        height: 90,
        starPoints: 5,
        fills: [DesignFill.solid(Color(0xFFF59E0B))],
        strokes: [DesignStroke(color: Color(0xFFFDE68A), width: 2.0)],
        effects: [
          DesignEffect(
            type: DesignEffectType.outerGlow,
            color: Color(0x60F59E0B),
            blurRadius: 18,
          ),
        ],
      ),
      // 2. Octagram Badge
      'vi-octa-badge': const DesignNode(
        id: 'vi-octa-badge',
        parentId: frameId,
        type: NodeType.star,
        name: '8-Point Shield Star',
        x: 270,
        y: 180,
        width: 90,
        height: 90,
        starPoints: 8,
        fills: [
          DesignFill(
            type: DesignFillType.linearGradient,
            gradientColors: [Color(0xFF6366F1), Color(0xFFEC4899)],
            gradientAngle: 45,
          ),
        ],
        strokes: [DesignStroke(color: Color(0xFFA5B4FC), width: 2.0)],
        effects: [
          DesignEffect(
            type: DesignEffectType.outerGlow,
            color: Color(0x506366F1),
            blurRadius: 16,
          ),
        ],
      ),
      // 3. Sharp Triangle
      'vi-sharp-triangle': const DesignNode(
        id: 'vi-sharp-triangle',
        parentId: frameId,
        type: NodeType.polygon,
        name: 'Geometric Triangle',
        x: 430,
        y: 180,
        width: 90,
        height: 90,
        polygonSides: 3,
        cornerRadii: CornerRadii.all(6),
        fills: [DesignFill.solid(Color(0xFFEF4444))],
        strokes: [DesignStroke(color: Color(0xFFFCA5A5), width: 2.0)],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x40EF4444),
            offsetX: 0,
            offsetY: 8,
            blurRadius: 16,
          ),
        ],
      ),
      // 4. Cyber Hexagon
      'vi-cyber-hexagon': const DesignNode(
        id: 'vi-cyber-hexagon',
        parentId: frameId,
        type: NodeType.polygon,
        name: 'Cyber Hexagon',
        x: 590,
        y: 180,
        width: 90,
        height: 90,
        polygonSides: 6,
        cornerRadii: CornerRadii.all(8),
        fills: [DesignFill.solid(Color(0xFF06B6D4))],
        strokes: [DesignStroke(color: Color(0xFF67E8F9), width: 2.0)],
        effects: [
          DesignEffect(
            type: DesignEffectType.outerGlow,
            color: Color(0x6006B6D4),
            blurRadius: 20,
          ),
        ],
      ),
      // 5. Shield Pill Badge
      'vi-shield-pill': const DesignNode(
        id: 'vi-shield-pill',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Shield Pill',
        x: 110,
        y: 330,
        width: 150,
        height: 60,
        cornerRadii: CornerRadii.all(30),
        fills: [
          DesignFill(
            type: DesignFillType.linearGradient,
            gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
            gradientAngle: 90,
          ),
        ],
        strokes: [DesignStroke(color: Color(0xFF6EE7B7), width: 1.5)],
      ),
      // 6. Multi-Ring Target
      'vi-ring-outer': const DesignNode(
        id: 'vi-ring-outer',
        parentId: frameId,
        type: NodeType.ellipse,
        name: 'Target Outer Ring',
        x: 320,
        y: 320,
        width: 80,
        height: 80,
        fills: [DesignFill.solid(Color(0x103B82F6))],
        strokes: [DesignStroke(color: Color(0xFF3B82F6), width: 3.0)],
      ),
      'vi-ring-inner': const DesignNode(
        id: 'vi-ring-inner',
        parentId: frameId,
        type: NodeType.ellipse,
        name: 'Target Core',
        x: 345,
        y: 345,
        width: 30,
        height: 30,
        fills: [DesignFill.solid(Color(0xFF3B82F6))],
      ),
    };

    return ProjectModel(
      id: 'proj-vector-glyphs-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Vector Icons & Glyphs',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: [
        const PageModel(
          id: 'page-1',
          name: 'Canvas',
          rootNodeIds: [frameId],
          backgroundColor: Color(0xFF080D1A),
        ),
      ],
      nodes: nodes,
    );
  }

  /// 3. Glassmorphism Profile & Cards (Faithfully matches gemini-code-1793281292883.html)
  static ProjectModel createGlassmorphismCardsProject() {
    const frameId = 'frame-cosmic-glass';
    final nodes = <String, DesignNode>{
      frameId: DesignNode(
        id: frameId,
        type: NodeType.frame,
        name: 'Cosmic Glass Profile & Cards',
        x: 60,
        y: 40,
        width: 960,
        height: 640,
        cornerRadii: const CornerRadii.all(24),
        fills: const [DesignFill.solid(Color(0xFF080D1A))],
        childrenIds: const [
          'orb-purple',
          'orb-cyan',
          'glass-profile-card',
          'profile-avatar',
          'profile-name',
          'profile-role',
          'profile-badge',
          'profile-badge-text',
          'profile-stats-card',
          'profile-stats-text',
          'profile-cta-btn',
          'profile-cta-text',
          'glass-metric-card',
          'metric-title',
          'metric-bar-bg',
          'metric-bar-fill',
        ],
      ),
      // Radial glow orb 1 (Purple)
      'orb-purple': const DesignNode(
        id: 'orb-purple',
        parentId: frameId,
        type: NodeType.ellipse,
        name: 'Purple Glow Orb',
        x: 80,
        y: 100,
        width: 280,
        height: 280,
        fills: [
          DesignFill(
            type: DesignFillType.radialGradient,
            gradientColors: [Color(0x99431D77), Color(0x00080D1A)],
          ),
        ],
      ),
      // Radial glow orb 2 (Cyan)
      'orb-cyan': const DesignNode(
        id: 'orb-cyan',
        parentId: frameId,
        type: NodeType.ellipse,
        name: 'Cyan Glow Orb',
        x: 580,
        y: 220,
        width: 260,
        height: 260,
        fills: [
          DesignFill(
            type: DesignFillType.radialGradient,
            gradientColors: [Color(0x880C7585), Color(0x00080D1A)],
          ),
        ],
      ),
      // Main Glass Profile Card
      'glass-profile-card': const DesignNode(
        id: 'glass-profile-card',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Frosted Profile Card',
        x: 120,
        y: 100,
        width: 360,
        height: 440,
        cornerRadii: CornerRadii.all(20),
        fills: [DesignFill.solid(Color(0xD0131C31))],
        strokes: [DesignStroke(color: Color(0x35FFFFFF), width: 1.5)],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x70000000),
            offsetX: 0,
            offsetY: 16,
            blurRadius: 32,
          ),
        ],
      ),
      'profile-avatar': const DesignNode(
        id: 'profile-avatar',
        parentId: frameId,
        type: NodeType.ellipse,
        name: 'Avatar Gradient',
        x: 265,
        y: 130,
        width: 70,
        height: 70,
        fills: [
          DesignFill(
            type: DesignFillType.linearGradient,
            gradientColors: [Color(0xFF6366F1), Color(0xFFEC4899)],
            gradientAngle: 135,
          ),
        ],
        strokes: [DesignStroke(color: Color(0xFFFFFFFF), width: 2.0)],
      ),
      'profile-name': const DesignNode(
        id: 'profile-name',
        parentId: frameId,
        type: NodeType.text,
        name: 'User Name',
        x: 150,
        y: 215,
        width: 300,
        height: 28,
        textData: TextNodeData(
          text: 'Elena Vance',
          fontSize: 18,
          fontWeight: 800,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(Color(0xFFFFFFFF))],
      ),
      'profile-role': const DesignNode(
        id: 'profile-role',
        parentId: frameId,
        type: NodeType.text,
        name: 'User Role',
        x: 150,
        y: 245,
        width: 300,
        height: 20,
        textData: TextNodeData(
          text: 'Principal Design Technologist',
          fontSize: 12,
          fontWeight: 500,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(Color(0xFF94A3B8))],
      ),
      'profile-badge': const DesignNode(
        id: 'profile-badge',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Pro Badge Pill',
        x: 245,
        y: 275,
        width: 110,
        height: 24,
        cornerRadii: CornerRadii.all(12),
        fills: [DesignFill.solid(Color(0x25FACC15))],
        strokes: [DesignStroke(color: Color(0xFFFACC15), width: 1.0)],
      ),
      'profile-badge-text': const DesignNode(
        id: 'profile-badge-text',
        parentId: frameId,
        type: NodeType.text,
        name: 'Pro Badge Text',
        x: 255,
        y: 279,
        width: 90,
        height: 16,
        textData: TextNodeData(
          text: 'PRO VERIFIED',
          fontSize: 9.5,
          fontWeight: 800,
          letterSpacing: 0.8,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(Color(0xFFFACC15))],
      ),
      'profile-stats-card': const DesignNode(
        id: 'profile-stats-card',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Stats Sub-Box',
        x: 150,
        y: 320,
        width: 300,
        height: 70,
        cornerRadii: CornerRadii.all(14),
        fills: [DesignFill.solid(Color(0x40000000))],
        strokes: [DesignStroke(color: Color(0x20FFFFFF), width: 1.0)],
      ),
      'profile-stats-text': const DesignNode(
        id: 'profile-stats-text',
        parentId: frameId,
        type: NodeType.text,
        name: 'Stats Numbers',
        x: 165,
        y: 335,
        width: 270,
        height: 40,
        textData: TextNodeData(
          text: '34.8K Followers    •    1.2M Views',
          fontSize: 12,
          fontWeight: 700,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(Color(0xFFE2E8F0))],
      ),
      'profile-cta-btn': const DesignNode(
        id: 'profile-cta-btn',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Connect CTA Button',
        x: 150,
        y: 420,
        width: 300,
        height: 46,
        cornerRadii: CornerRadii.all(23),
        fills: [
          DesignFill(
            type: DesignFillType.linearGradient,
            gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            gradientAngle: 90,
          ),
        ],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x606366F1),
            offsetX: 0,
            offsetY: 6,
            blurRadius: 16,
          ),
        ],
      ),
      'profile-cta-text': const DesignNode(
        id: 'profile-cta-text',
        parentId: frameId,
        type: NodeType.text,
        name: 'Connect CTA Text',
        x: 180,
        y: 434,
        width: 240,
        height: 20,
        textData: TextNodeData(
          text: 'Follow & Connect',
          fontSize: 13,
          fontWeight: 700,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(Color(0xFFFFFFFF))],
      ),
      // Secondary Metric Card
      'glass-metric-card': const DesignNode(
        id: 'glass-metric-card',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Telemetry Metric Card',
        x: 520,
        y: 100,
        width: 320,
        height: 240,
        cornerRadii: CornerRadii.all(20),
        fills: [DesignFill.solid(Color(0xD0131C31))],
        strokes: [DesignStroke(color: Color(0x35FFFFFF), width: 1.5)],
      ),
      'metric-title': const DesignNode(
        id: 'metric-title',
        parentId: frameId,
        type: NodeType.text,
        name: 'Metric Card Header',
        x: 550,
        y: 130,
        width: 260,
        height: 24,
        textData: TextNodeData(
          text: 'Studio Deployment Health',
          fontSize: 14,
          fontWeight: 700,
        ),
        fills: [DesignFill.solid(Color(0xFFFFFFFF))],
      ),
      'metric-bar-bg': const DesignNode(
        id: 'metric-bar-bg',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Progress Track',
        x: 550,
        y: 175,
        width: 260,
        height: 12,
        cornerRadii: CornerRadii.all(6),
        fills: [DesignFill.solid(Color(0x30FFFFFF))],
      ),
      'metric-bar-fill': const DesignNode(
        id: 'metric-bar-fill',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Progress Indicator',
        x: 550,
        y: 175,
        width: 200,
        height: 12,
        cornerRadii: CornerRadii.all(6),
        fills: [
          DesignFill(
            type: DesignFillType.linearGradient,
            gradientColors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
            gradientAngle: 90,
          ),
        ],
      ),
    };

    return ProjectModel(
      id: 'proj-glass-cosmic-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Cosmic Glass Profile & Cards',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: [
        const PageModel(
          id: 'page-1',
          name: 'Canvas',
          rootNodeIds: [frameId],
          backgroundColor: Color(0xFF040711),
        ),
      ],
      nodes: nodes,
    );
  }

  /// 4. Form & Input Components Kit
  static ProjectModel createFormComponentsProject() {
    const frameId = 'frame-form-components';
    final nodes = <String, DesignNode>{
      frameId: DesignNode(
        id: frameId,
        type: NodeType.frame,
        name: 'Form & Input Components',
        x: 60,
        y: 40,
        width: 880,
        height: 600,
        cornerRadii: const CornerRadii.all(24),
        fills: const [DesignFill.solid(Color(0xFFF8FAFC))],
        childrenIds: const [
          'form-title',
          'form-label-1',
          'form-input-1',
          'form-input-1-val',
          'form-label-2',
          'form-input-2',
          'form-input-2-val',
          'form-switch-track',
          'form-switch-thumb',
          'form-switch-text',
          'form-submit-btn',
          'form-submit-text',
        ],
      ),
      'form-title': const DesignNode(
        id: 'form-title',
        parentId: frameId,
        type: NodeType.text,
        name: 'Header Title',
        x: 100,
        y: 80,
        width: 450,
        height: 38,
        textData: TextNodeData(
          text: 'FORM & INPUT SYSTEM',
          fontSize: 22,
          fontWeight: 800,
          letterSpacing: 0.5,
        ),
        fills: [DesignFill.solid(Color(0xFF0F172A))],
      ),
      // Input 1: Standard Field
      'form-label-1': const DesignNode(
        id: 'form-label-1',
        parentId: frameId,
        type: NodeType.text,
        name: 'Name Label',
        x: 100,
        y: 140,
        width: 200,
        height: 20,
        textData: TextNodeData(text: 'Full Name', fontSize: 12, fontWeight: 700),
        fills: [DesignFill.solid(Color(0xFF475569))],
      ),
      'form-input-1': const DesignNode(
        id: 'form-input-1',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Input Field 1',
        x: 100,
        y: 165,
        width: 320,
        height: 48,
        cornerRadii: CornerRadii.all(10),
        fills: [DesignFill.solid(Color(0xFFFFFFFF))],
        strokes: [DesignStroke(color: Color(0xFFCBD5E1), width: 1.5)],
      ),
      'form-input-1-val': const DesignNode(
        id: 'form-input-1-val',
        parentId: frameId,
        type: NodeType.text,
        name: 'Input 1 Placeholder',
        x: 115,
        y: 180,
        width: 200,
        height: 20,
        textData: TextNodeData(text: 'Jane Doe', fontSize: 13, fontWeight: 500),
        fills: [DesignFill.solid(Color(0xFF0F172A))],
      ),
      // Input 2: Focused Field
      'form-label-2': const DesignNode(
        id: 'form-label-2',
        parentId: frameId,
        type: NodeType.text,
        name: 'Email Label',
        x: 100,
        y: 235,
        width: 200,
        height: 20,
        textData: TextNodeData(text: 'Work Email Address', fontSize: 12, fontWeight: 700),
        fills: [DesignFill.solid(Color(0xFF475569))],
      ),
      'form-input-2': const DesignNode(
        id: 'form-input-2',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Input Field 2 Focused',
        x: 100,
        y: 260,
        width: 320,
        height: 48,
        cornerRadii: CornerRadii.all(10),
        fills: [DesignFill.solid(Color(0xFFFFFFFF))],
        strokes: [DesignStroke(color: Color(0xFF3B82F6), width: 2.0)],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x303B82F6),
            offsetX: 0,
            offsetY: 4,
            blurRadius: 12,
          ),
        ],
      ),
      'form-input-2-val': const DesignNode(
        id: 'form-input-2-val',
        parentId: frameId,
        type: NodeType.text,
        name: 'Input 2 Text',
        x: 115,
        y: 275,
        width: 250,
        height: 20,
        textData: TextNodeData(text: 'jane.doe@forma.design', fontSize: 13, fontWeight: 600),
        fills: [DesignFill.solid(Color(0xFF1E293B))],
      ),
      // Toggle Switch
      'form-switch-track': const DesignNode(
        id: 'form-switch-track',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Switch Track Active',
        x: 100,
        y: 335,
        width: 52,
        height: 28,
        cornerRadii: CornerRadii.all(14),
        fills: [DesignFill.solid(Color(0xFF3B82F6))],
      ),
      'form-switch-thumb': const DesignNode(
        id: 'form-switch-thumb',
        parentId: frameId,
        type: NodeType.ellipse,
        name: 'Switch Knob',
        x: 128,
        y: 339,
        width: 20,
        height: 20,
        fills: [DesignFill.solid(Color(0xFFFFFFFF))],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x25000000),
            offsetX: 0,
            offsetY: 2,
            blurRadius: 4,
          ),
        ],
      ),
      'form-switch-text': const DesignNode(
        id: 'form-switch-text',
        parentId: frameId,
        type: NodeType.text,
        name: 'Switch Label',
        x: 165,
        y: 340,
        width: 250,
        height: 20,
        textData: TextNodeData(text: 'Enable two-factor authentication', fontSize: 12.5, fontWeight: 600),
        fills: [DesignFill.solid(Color(0xFF334155))],
      ),
      // Submit Button
      'form-submit-btn': const DesignNode(
        id: 'form-submit-btn',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Submit Button',
        x: 100,
        y: 395,
        width: 320,
        height: 50,
        cornerRadii: CornerRadii.all(12),
        fills: [
          DesignFill(
            type: DesignFillType.linearGradient,
            gradientColors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            gradientAngle: 90,
          ),
        ],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x402563EB),
            offsetX: 0,
            offsetY: 8,
            blurRadius: 18,
          ),
        ],
      ),
      'form-submit-text': const DesignNode(
        id: 'form-submit-text',
        parentId: frameId,
        type: NodeType.text,
        name: 'Submit Button Text',
        x: 140,
        y: 410,
        width: 240,
        height: 22,
        textData: TextNodeData(
          text: 'Save Account Settings',
          fontSize: 14,
          fontWeight: 700,
          textAlign: TextAlign.center,
        ),
        fills: [DesignFill.solid(Color(0xFFFFFFFF))],
      ),
    };

    return ProjectModel(
      id: 'proj-form-comp-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Form & Input Components',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: [
        const PageModel(
          id: 'page-1',
          name: 'Canvas',
          rootNodeIds: [frameId],
          backgroundColor: Color(0xFFEDF2F7),
        ),
      ],
      nodes: nodes,
    );
  }
}
