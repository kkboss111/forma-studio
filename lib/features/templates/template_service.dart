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
  final ProjectModel Function() projectBuilder;

  const TemplateInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.projectBuilder,
  });
}

class TemplateService {
  TemplateService._();

  static List<TemplateInfo> getTemplates() {
    return [
      TemplateInfo(
        id: 'liquid_glass_icon_studio',
        title: 'Liquid Glass App Icon Studio',
        description:
            'Translucent 3D app icon with squircle sheen, glass rings, and pod figure',
        icon: Icons.blur_on_rounded,
        projectBuilder: createLiquidGlassIconProject,
      ),
      TemplateInfo(
        id: 'fan_analysis_dashboard',
        title: 'Fan Analysis Dashboard',
        description:
            'Faithful neumorphic dashboard with sidebar, stats, bars & donut chart',
        icon: Icons.dashboard_customize_rounded,
        projectBuilder: createFanAnalysisProject,
      ),
      TemplateInfo(
        id: 'mobile_onboarding',
        title: 'Mobile Onboarding Flow',
        description:
            'Clean mobile walkthrough cards with pagination and primary CTA',
        icon: Icons.smartphone_rounded,
        projectBuilder: createOnboardingProject,
      ),
      TemplateInfo(
        id: 'ecommerce_product',
        title: 'E-Commerce Product View',
        description:
            'Product image card, color swatches, size selector, and action dock',
        icon: Icons.shopping_bag_outlined,
        projectBuilder: createEcommerceProject,
      ),
      TemplateInfo(
        id: 'social_profile',
        title: 'Social Profile Screen',
        description:
            'User avatar, bio, follower counters, action buttons, and feed grid',
        icon: Icons.person_pin_circle_outlined,
        projectBuilder: createSocialProfileProject,
      ),
      TemplateInfo(
        id: 'music_player',
        title: 'Neumorphic Music Player',
        description:
            'Raised album artwork, tactile controls, scrubber, and track info',
        icon: Icons.music_note_rounded,
        projectBuilder: createMusicPlayerProject,
      ),
      TemplateInfo(
        id: 'finance_wallet',
        title: 'Finance & Wallet Dashboard',
        description:
            'Credit card well, balance summary, quick actions, and recent activity',
        icon: Icons.account_balance_wallet_outlined,
        projectBuilder: createFinanceProject,
      ),
      TemplateInfo(
        id: 'portfolio_showcase',
        title: 'Designer Portfolio',
        description:
            'Hero presentation, project thumbnails, category chips, and bio',
        icon: Icons.layers_outlined,
        projectBuilder: createPortfolioProject,
      ),
      TemplateInfo(
        id: 'landing_page',
        title: 'Minimalist Landing Page',
        description:
            'Header, responsive navigation, bold headline, and feature grid',
        icon: Icons.web_rounded,
        projectBuilder: createLandingPageProject,
      ),
      TemplateInfo(
        id: 'settings_screen',
        title: 'Mobile Settings Screen',
        description:
            'Grouped list tiles with switches, chevrons, and user banner',
        icon: Icons.tune_rounded,
        projectBuilder: createSettingsProject,
      ),
      TemplateInfo(
        id: 'design_system',
        title: 'Design System & UI Kit',
        description:
            'Color tokens, typography scale, buttons, switches, and badges',
        icon: Icons.palette_outlined,
        projectBuilder: createDesignSystemProject,
      ),
      TemplateInfo(
        id: 'tablet_dashboard',
        title: 'Tablet Analytics Board',
        description:
            'Multi-column tablet layout with KPIs, data table, and charts',
        icon: Icons.tablet_mac_rounded,
        projectBuilder: createTabletDashboardProject,
      ),
      TemplateInfo(
        id: 'signin_auth',
        title: 'Sign In & Authentication',
        description:
            'Neumorphic input fields, password toggle, and social login',
        icon: Icons.lock_outline_rounded,
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

  static ProjectModel createLiquidGlassIconProject() {
    const frameId = 'frame-glass-studio';
    final nodes = <String, DesignNode>{
      frameId: const DesignNode(
        id: frameId,
        type: NodeType.frame,
        name: 'Liquid Glass Icon Studio',
        x: 60,
        y: 40,
        width: 880,
        height: 640,
        cornerRadii: CornerRadii.all(24),
        fills: [DesignFill.solid(Color(0xFFE6F3FA))],
        childrenIds: [
          'node-glass-title',
          'node-glass-squircle',
          'node-squircle-sheen',
          'node-glass-outer-ring',
          'node-glass-inner-ring',
          'node-pod-head',
          'node-pod-body',
          'node-chip-v1',
          'node-chip-v2',
          'node-chip-v3',
          'node-glass-tag',
        ],
      ),
      'node-glass-title': const DesignNode(
        id: 'node-glass-title',
        parentId: frameId,
        type: NodeType.text,
        name: 'Icon Title',
        x: 295,
        y: 70,
        width: 290,
        height: 32,
        textData: TextNodeData(
          text: 'Podcasts App Icon',
          fontSize: 22,
          fontWeight: 700,
        ),
        fills: [DesignFill.solid(Color(0xFF1C3249))],
      ),
      'node-glass-squircle': const DesignNode(
        id: 'node-glass-squircle',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Liquid Squircle Base',
        x: 295,
        y: 125,
        width: 290,
        height: 290,
        cornerRadii: CornerRadii.all(65),
        fills: [
          DesignFill(
            type: DesignFillType.linearGradient,
            gradientColors: [Color(0xFF4099FF), Color(0xFF0A58CA)],
            gradientStops: [0.0, 1.0],
            gradientBegin: Alignment.topLeft,
            gradientEnd: Alignment.bottomRight,
          ),
        ],
        strokes: [
          DesignStroke(color: Colors.white, width: 1.5),
        ],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x660044B3),
            offsetX: 0,
            offsetY: 25,
            blurRadius: 50,
          ),
        ],
      ),
      'node-squircle-sheen': const DesignNode(
        id: 'node-squircle-sheen',
        parentId: frameId,
        type: NodeType.ellipse,
        name: 'Fluid Specular Sheen',
        x: 310,
        y: 135,
        width: 260,
        height: 140,
        rotation: -15,
        opacity: 0.45,
        fills: [DesignFill.solid(Colors.white)],
      ),
      'node-glass-outer-ring': const DesignNode(
        id: 'node-glass-outer-ring',
        parentId: frameId,
        type: NodeType.ellipse,
        name: 'Outer Glass Ring',
        x: 335,
        y: 165,
        width: 210,
        height: 210,
        fills: [DesignFill.solid(Color(0x33FFFFFF))],
        strokes: [DesignStroke(color: Color(0xB3FFFFFF), width: 1.5)],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x33001E50),
            offsetX: 0,
            offsetY: 8,
            blurRadius: 24,
          ),
        ],
      ),
      'node-glass-inner-ring': const DesignNode(
        id: 'node-glass-inner-ring',
        parentId: frameId,
        type: NodeType.ellipse,
        name: 'Inner Glass Ring',
        x: 362.5,
        y: 192.5,
        width: 155,
        height: 155,
        fills: [DesignFill.solid(Color(0x4DFFFFFF))],
        strokes: [DesignStroke(color: Colors.white, width: 2.0)],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x2B001E50),
            offsetX: 0,
            offsetY: 6,
            blurRadius: 16,
          ),
        ],
      ),
      'node-pod-head': const DesignNode(
        id: 'node-pod-head',
        parentId: frameId,
        type: NodeType.ellipse,
        name: 'Pod Figure Head',
        x: 422,
        y: 226,
        width: 36,
        height: 36,
        fills: [DesignFill.solid(Colors.white)],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x4D001E50),
            offsetX: 0,
            offsetY: 6,
            blurRadius: 14,
          ),
        ],
      ),
      'node-pod-body': const DesignNode(
        id: 'node-pod-body',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Pod Figure Body',
        x: 418,
        y: 268,
        width: 44,
        height: 78,
        cornerRadii: CornerRadii.all(22),
        fills: [DesignFill.solid(Colors.white)],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            color: Color(0x4D001E50),
            offsetX: 0,
            offsetY: 10,
            blurRadius: 22,
          ),
        ],
      ),
      'node-chip-v1': const DesignNode(
        id: 'node-chip-v1',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Variant Purple Chip',
        x: 380,
        y: 445,
        width: 34,
        height: 34,
        cornerRadii: CornerRadii.all(10),
        fills: [DesignFill.solid(Color(0xFF8E44AD))],
        strokes: [DesignStroke(color: Color(0x66FFFFFF), width: 1.0)],
      ),
      'node-chip-v2': const DesignNode(
        id: 'node-chip-v2',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Variant Blue Chip',
        x: 423,
        y: 445,
        width: 34,
        height: 34,
        cornerRadii: CornerRadii.all(10),
        fills: [DesignFill.solid(Color(0xFF007AFF))],
        strokes: [DesignStroke(color: Color(0x66FFFFFF), width: 1.0)],
      ),
      'node-chip-v3': const DesignNode(
        id: 'node-chip-v3',
        parentId: frameId,
        type: NodeType.roundedRectangle,
        name: 'Variant Light Chip',
        x: 466,
        y: 445,
        width: 34,
        height: 34,
        cornerRadii: CornerRadii.all(10),
        fills: [DesignFill.solid(Colors.white)],
        strokes: [DesignStroke(color: Color(0x33000000), width: 1.0)],
      ),
      'node-glass-tag': const DesignNode(
        id: 'node-glass-tag',
        parentId: frameId,
        type: NodeType.text,
        name: 'Platforms Tag',
        x: 375,
        y: 495,
        width: 130,
        height: 24,
        textData: TextNodeData(
          text: 'macOS, iOS, iPadOS',
          fontSize: 11,
          fontWeight: 600,
        ),
        fills: [DesignFill.solid(Color(0xFF5A738C))],
      ),
    };

    return ProjectModel(
      id: 'proj-liquid-glass-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Liquid Glass Podcasts Icon',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: [
        const PageModel(
          id: 'page-1',
          name: 'Canvas',
          rootNodeIds: [frameId],
          backgroundColor: Color(0xFFD6E9F5),
        ),
      ],
      nodes: nodes,
    );
  }
}
