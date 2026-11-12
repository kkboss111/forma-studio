import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../app/theme/forma_theme.dart';
import '../../../../app/theme/neumorphic.dart';
import '../../../../core/collab/collab_models.dart';
import '../../../../core/collab/collab_service.dart';
import '../panels/room_operator_menu.dart';

/// Modal dialog for managing real-time multi-user design sessions in Forma Studio.
/// Features instant 1-click room hosting, quick join, 6-character room code sharing,
/// active collaborator indicators, remote cursor toggles, and Room Operator menu access.
class CollabDialog extends ConsumerStatefulWidget {
  final CollabService? collabService;

  const CollabDialog({
    super.key,
    this.collabService,
  });

  @override
  ConsumerState<CollabDialog> createState() => _CollabDialogState();
}

class _CollabDialogState extends ConsumerState<CollabDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _createRoomNameCtrl =
      TextEditingController(text: 'Design Studio Session');
  final TextEditingController _createUserNameCtrl =
      TextEditingController(text: 'Lead Designer');
  final TextEditingController _joinRoomCodeCtrl = TextEditingController();
  final TextEditingController _joinUserNameCtrl =
      TextEditingController(text: 'Peer Designer');
  final TextEditingController _firebaseUrlCtrl = TextEditingController();

  late Color _selectedColor;
  bool _copied = false;
  bool _isActionInProgress = false;
  bool _isSavingFirebase = false;
  bool _isFirebaseSetupExpanded = false;
  bool _syncedInitialFirebaseUrl = false;
  String? _statusError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedColor = CollaboratorColorPalette.vibrantColors[0];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_syncedInitialFirebaseUrl) {
      _syncedInitialFirebaseUrl = true;
      final savedUrl = _resolveService().firebaseDbUrl;
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _firebaseUrlCtrl.text = savedUrl;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _createRoomNameCtrl.dispose();
    _createUserNameCtrl.dispose();
    _joinRoomCodeCtrl.dispose();
    _joinUserNameCtrl.dispose();
    _firebaseUrlCtrl.dispose();
    super.dispose();
  }

  CollabService _resolveService({bool listen = false}) {
    final custom = widget.collabService;
    if (custom != null) return custom;
    return listen
        ? ref.watch(collabServiceProvider)
        : ref.read(collabServiceProvider);
  }

  Future<void> _handleQuickHost() async {
    final service = _resolveService();
    setState(() {
      _isActionInProgress = true;
      _statusError = null;
    });

    try {
      final session = await service.quickHostRoom(
        roomName: _createRoomNameCtrl.text,
        userName: _createUserNameCtrl.text,
        color: _selectedColor,
      );

      // Automatically copy 6-character code to clipboard
      await Clipboard.setData(ClipboardData(text: session.roomId));

      if (mounted) {
        setState(() {
          _isActionInProgress = false;
          _copied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Room ${session.roomId} created! Code copied. Share it with your friend to draw together!',
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
          _statusError = 'Error hosting room: $e';
        });
      }
    }
  }

  Future<void> _handleJoinRoom(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      setState(() => _statusError = 'Please enter a valid 6-character room code');
      return;
    }

    final service = _resolveService();
    setState(() {
      _isActionInProgress = true;
      _statusError = null;
    });

    try {
      await service.joinRoom(
        cleanCode,
        _joinUserNameCtrl.text,
        color: _selectedColor,
      );
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
          _statusError = 'Error joining room: $e';
        });
      }
    }
  }

  Future<void> _handleDisconnect() async {
    final service = _resolveService();
    setState(() => _isActionInProgress = true);
    await service.leaveRoom();
    if (mounted) {
      setState(() {
        _isActionInProgress = false;
        _copied = false;
      });
    }
  }

  void _copyRoomCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room code $code copied to clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _handleSaveFirebase() async {
    final service = _resolveService();
    setState(() {
      _isSavingFirebase = true;
      _statusError = null;
    });

    try {
      await service.configureFirebase(_firebaseUrlCtrl.text);
      if (mounted) {
        setState(() {
          _isSavingFirebase = false;
          if (service.isFirebaseConfigured) {
            _isFirebaseSetupExpanded = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              service.isFirebaseConfigured
                  ? 'Firebase Cloud Sync connected! Host or join rooms across any device.'
                  : 'Switched to Browser Tab & Local Engine.',
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingFirebase = false;
          _statusError = '$e';
        });
      }
    }
  }

  Future<void> _handleClearFirebase() async {
    final service = _resolveService();
    setState(() {
      _isSavingFirebase = true;
      _statusError = null;
    });
    await service.clearFirebaseConfig();
    if (mounted) {
      _firebaseUrlCtrl.clear();
      setState(() => _isSavingFirebase = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Switched back to Browser Tab & Local Engine.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = _resolveService(listen: true);
    final session = service.session;
    final isConnected = service.isConnected && session != null;
    final tokens = FormaTheme.tokensOf(context);
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = math.min(screenSize.width - 32, 540.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: NeuCard(
        width: dialogWidth,
        radius: 24,
        padding: const EdgeInsets.all(22),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenSize.height * 0.88,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(tokens, isConnected),
                const SizedBox(height: 18),
                if (_statusError != null) ...[
                  _buildErrorBanner(tokens, _statusError!),
                  const SizedBox(height: 14),
                ],
                if (isConnected)
                  _buildConnectedView(tokens, service, session)
                else
                  _buildDisconnectedView(tokens, service),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FormaThemeTokens tokens, bool isConnected) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.hub_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Multi-User Collaboration',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: tokens.textMain,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (isConnected) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: FormaColors.successGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: FormaColors.successGreen.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: FormaColors.successGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: FormaColors.successGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                isConnected
                    ? 'Syncing active canvas, layers & remote cursors in real time'
                    : 'Design together in real time with Figma-grade cursor tracking',
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.textMuted,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close_rounded,
            color: tokens.textMuted,
            size: 20,
          ),
          splashRadius: 18,
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildErrorBanner(FormaThemeTokens tokens, String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: FormaColors.dangerRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: FormaColors.dangerRed.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: FormaColors.dangerRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: FormaColors.dangerRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Disconnected View: Instant 1-Click Host, Quick Join, and Backend Setup
  // ===========================================================================
  Widget _buildDisconnectedView(FormaThemeTokens tokens, CollabService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab Bar Switcher
        Container(
          height: 40,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: tokens.wellBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: tokens.isDark ? 0.35 : 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: tokens.textMain,
            unselectedLabelColor: tokens.textMuted,
            labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
            dividerHeight: 0,
            tabs: const [
              Tab(text: 'Quick Start'),
              Tab(text: 'Custom Setup'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 348,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInstantOnboardingTab(tokens),
              _buildCustomSetupTab(tokens),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildBackendModeCard(tokens, service),
      ],
    );
  }

  Widget _buildBackendStatusPill(FormaThemeTokens tokens, CollabService service) {
    final isCloud = service.isFirebaseConfigured;
    final pillColor = isCloud ? FormaColors.successGreen : FormaColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: pillColor.withValues(alpha: tokens.isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: pillColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        isCloud
            ? '☁️ Firebase Cloud Sync Active'
            : '🌐 Browser Tab & Local Engine',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isCloud ? FormaColors.successGreen : FormaColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildBackendModeCard(FormaThemeTokens tokens, CollabService service) {
    final isCloud = service.isFirebaseConfigured;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.wellBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCloud
              ? FormaColors.successGreen.withValues(alpha: 0.35)
              : tokens.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(
              () => _isFirebaseSetupExpanded = !_isFirebaseSetupExpanded,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Backend Mode',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.textMain,
                        ),
                      ),
                      _buildBackendStatusPill(tokens, service),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCloud ? 'Firebase Setup' : 'Configure Cloud',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tokens.textMain,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _isFirebaseSetupExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16,
                        color: tokens.textMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isFirebaseSetupExpanded) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: tokens.borderSubtle),
            const SizedBox(height: 12),
            _buildInputLabel(tokens, 'Firebase Realtime Database URL'),
            NeuTextField(
              controller: _firebaseUrlCtrl,
              hintText: 'https://my-app-default-rtdb.firebaseio.com',
              prefixIcon: const Icon(
                Icons.cloud_outlined,
                size: 18,
                color: FormaColors.primaryBlue,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste_rounded, size: 17),
                tooltip: 'Paste URL from clipboard',
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _firebaseUrlCtrl.text = data!.text!.trim();
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: NeuButton(
                    height: 40,
                    onPressed: _isSavingFirebase ? null : _handleSaveFirebase,
                    color: FormaColors.primaryBlue,
                    child: _isSavingFirebase
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_done_rounded, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Save & Connect Firebase',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (isCloud) ...[
                  const SizedBox(width: 8),
                  NeuButton(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: _isSavingFirebase ? null : _handleClearFirebase,
                    color: tokens.surface,
                    child: Text(
                      'Local Mode',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textMain,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Text(
                '1. Create Firebase Realtime Database in Test Mode -> 2. Paste URL above so friends on different PCs/phones can join the same Room Code!',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: tokens.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Fast, instant, fool-proof onboarding tab
  Widget _buildInstantOnboardingTab(FormaThemeTokens tokens) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1-Click Host Hero Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2563EB).withValues(alpha: tokens.isDark ? 0.25 : 0.10),
                  const Color(0xFF7C3AED).withValues(alpha: tokens.isDark ? 0.25 : 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: FormaColors.primaryBlue.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FormaColors.primaryBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: FormaColors.primaryBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Host a Live Room in 1 Click',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tokens.textMain,
                            ),
                          ),
                          Text(
                            'Instantly generates a 6-letter room code and copies it to share.',
                            style: TextStyle(fontSize: 11.5, color: tokens.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                NeuButton(
                  height: 46,
                  onPressed: _isActionInProgress ? null : _handleQuickHost,
                  color: FormaColors.primaryBlue,
                  child: _isActionInProgress
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_tethering_rounded, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Start Live Room Now',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: tokens.borderSubtle)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'OR JOIN A FRIEND\'S ROOM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: tokens.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(child: Divider(color: tokens.borderSubtle)),
            ],
          ),
          const SizedBox(height: 14),

          // Room Code Input & Join Button
          _buildInputLabel(tokens, 'Enter 6-Letter Room Code'),
          Row(
            children: [
              Expanded(
                child: NeuTextField(
                  controller: _joinRoomCodeCtrl,
                  hintText: 'e.g. FORMA-8392 or A9X2',
                  prefixIcon: const Icon(
                    Icons.pin_rounded,
                    size: 18,
                    color: FormaColors.primaryBlue,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded, size: 17),
                    tooltip: 'Paste from clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        _joinRoomCodeCtrl.text = data!.text!.trim().toUpperCase();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              NeuButton(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                onPressed: _isActionInProgress
                    ? null
                    : () => _handleJoinRoom(_joinRoomCodeCtrl.text),
                color: FormaColors.primaryBlue,
                child: _isActionInProgress
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        children: [
                          Icon(Icons.login_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Join',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quick LAN Join Pills
          _buildRecentRoomsList(tokens),
        ],
      ),
    );
  }

  /// Custom settings tab (display name, custom room title, cursor color)
  Widget _buildCustomSetupTab(FormaThemeTokens tokens) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputLabel(tokens, 'Custom Room Name'),
          NeuTextField(
            controller: _createRoomNameCtrl,
            hintText: 'e.g. Mobile Design System Sprint',
            prefixIcon: Icon(Icons.meeting_room_outlined, size: 18, color: tokens.textMuted),
          ),
          const SizedBox(height: 12),
          _buildInputLabel(tokens, 'Your Display Name'),
          NeuTextField(
            controller: _createUserNameCtrl,
            hintText: 'e.g. Alex Rivera',
            prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: tokens.textMuted),
          ),
          const SizedBox(height: 12),
          _buildInputLabel(tokens, 'Your Live Cursor & Badge Color'),
          _buildColorPickerRow(tokens),
          const SizedBox(height: 14),
          _buildFeaturesRow(tokens),
          const SizedBox(height: 16),
          NeuButton(
            height: 44,
            onPressed: _isActionInProgress ? null : _handleQuickHost,
            color: FormaColors.primaryBlue,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Launch Custom Session',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(FormaThemeTokens tokens, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.textMuted,
        ),
      ),
    );
  }

  Widget _buildColorPickerRow(FormaThemeTokens tokens) {
    final colors = CollaboratorColorPalette.vibrantColors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: colors.map((col) {
          final isSelected = col.toARGB32() == _selectedColor.toARGB32();
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = col),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: col,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: col.withValues(alpha: 0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturesRow(FormaThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.wellBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(child: _buildFeatureItem(tokens, Icons.near_me_rounded, 'Live Cursors')),
          const SizedBox(width: 4),
          Expanded(child: _buildFeatureItem(tokens, Icons.bolt_rounded, '0-Latency Sync')),
          const SizedBox(width: 4),
          Expanded(child: _buildFeatureItem(tokens, Icons.wifi_protected_setup_rounded, 'LAN & Cloud')),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(FormaThemeTokens tokens, IconData icon, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: FormaColors.primaryBlue),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tokens.textMain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRoomsList(FormaThemeTokens tokens) {
    const defaultCodes = ['FORMA-8392', 'FORMA-4821'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Join Local LAN Sessions',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: tokens.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: defaultCodes.map((code) {
            return NeuPill(
              onTap: () {
                _joinRoomCodeCtrl.text = code;
                _handleJoinRoom(code);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lan_outlined, size: 13, color: FormaColors.primaryBlue),
                  const SizedBox(width: 5),
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.textMain,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===========================================================================
  // Connected View: Room Code with 1-click Copy, Participants, Operator Button
  // ===========================================================================
  Widget _buildConnectedView(
    FormaThemeTokens tokens,
    CollabService service,
    CollabSession session,
  ) {
    final participants = session.participants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Room Code 1-Click Copy Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: tokens.wellBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: FormaColors.primaryBlue.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SHARE THIS 6-LETTER CODE WITH YOUR FRIEND',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: tokens.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.roomId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: FormaColors.primaryBlue,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${session.roomName} • ${service.adapterName}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: tokens.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildBackendStatusPill(tokens, service),
                      ],
                    ),
                  ),
                  NeuButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    onPressed: () => _copyRoomCode(session.roomId),
                    color: _copied ? FormaColors.successGreen : tokens.surface,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 16,
                          color: _copied ? Colors.white : tokens.textMain,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _copied ? 'Copied' : 'Copy Code',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _copied ? Colors.white : tokens.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Dedicated Button to Open Room Operator Menu
              NeuButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: () {
                  Navigator.of(context).pop();
                  showRoomOperatorMenu(context, collabService: service);
                },
                color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Open Room Operator Menu (Host Controls)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Active Participants List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Collaborators (${participants.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tokens.textMain,
              ),
            ),
            Text(
              '${service.pingMs}ms latency',
              style: TextStyle(
                fontSize: 11,
                color: tokens.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Participants Cards
        Container(
          constraints: const BoxConstraints(maxHeight: 160),
          decoration: BoxDecoration(
            color: tokens.wellBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            shrinkWrap: true,
            itemCount: participants.length,
            separatorBuilder: (context, index) => Divider(
              height: 8,
              thickness: 0.5,
              color: tokens.borderSubtle,
            ),
            itemBuilder: (context, index) {
              final p = participants[index];
              final isMe = p.id == service.localUser?.id;
              final isHost = p.id == session.hostId;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    // Live colored avatar badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: p.color.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          p.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textMain,
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: tokens.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'YOU',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: tokens.accent,
                                    ),
                                  ),
                                ),
                              ],
                              if (isHost) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'HOST',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (p.cursorPosition != null)
                            Text(
                              'Cursor: (${p.cursorPosition!.dx.toInt()}, ${p.cursorPosition!.dy.toInt()})',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: tokens.textMuted,
                              ),
                            )
                          else
                            Text(
                              p.canEdit ? 'Can edit canvas' : 'View only',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: tokens.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Live pulsing indicator
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.isRecent ? p.color : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (participants.length <= 1) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: tokens.wellBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: FormaColors.primaryBlue.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.group_add_outlined,
                  size: 18,
                  color: FormaColors.primaryBlue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No other collaborators connected yet. Share your room code to invite friends!',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: tokens.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Remote Cursors Toggle Tile
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: tokens.wellBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.near_me_rounded,
                  size: 18,
                  color: FormaColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Show remote cursors',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.textMain,
                      ),
                    ),
                    Text(
                      'Render live peer cursors & designer labels on canvas',
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: service.showRemoteCursors,
                activeTrackColor: FormaColors.primaryBlue,
                onChanged: (val) => service.setShowRemoteCursors(val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Disconnect Button
        NeuButton(
          height: 44,
          onPressed: _isActionInProgress ? null : _handleDisconnect,
          color: FormaColors.dangerRed.withValues(alpha: 0.12),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link_off_rounded, size: 18, color: FormaColors.dangerRed),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Disconnect / Leave Session',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FormaColors.dangerRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
