import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../app/theme/forma_theme.dart';
import '../../../../app/theme/neumorphic.dart';
import '../../../../core/collab/collab_models.dart';
import '../../../../core/collab/collab_service.dart';

/// Shows the dedicated Room Operator & Host Controls panel.
Future<void> showRoomOperatorMenu(
  BuildContext context, {
  CollabService? collabService,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => RoomOperatorMenu(collabService: collabService),
  );
}

/// Dedicated host and operator management panel for real-time collaborative rooms.
/// Gives room hosts full authority to monitor latency, copy room codes, toggle
/// room lock status, manage participant drawing permissions (Editor vs Viewer),
/// kick unwanted users, force canvas state resynchronization, and tear down sessions.
class RoomOperatorMenu extends ConsumerStatefulWidget {
  final CollabService? collabService;

  const RoomOperatorMenu({
    super.key,
    this.collabService,
  });

  @override
  ConsumerState<RoomOperatorMenu> createState() => _RoomOperatorMenuState();
}

class _RoomOperatorMenuState extends ConsumerState<RoomOperatorMenu> {
  bool _codeCopied = false;
  bool _linkCopied = false;
  bool _syncedBanner = false;

  CollabService _resolveService({bool listen = false}) {
    final custom = widget.collabService;
    if (custom != null) return custom;
    return listen
        ? ref.watch(collabServiceProvider)
        : ref.read(collabServiceProvider);
  }

  void _copyRoomCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _codeCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room code $code copied to clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  void _copyInviteLink(String roomId) {
    final link = 'https://forma.studio/collab/$roomId';
    Clipboard.setData(ClipboardData(text: link));
    setState(() => _linkCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite link copied! Share with your friends to draw together.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _linkCopied = false);
    });
  }

  void _handleForceSync(CollabService service) {
    service.forceSyncCanvas([]);
    setState(() => _syncedBanner = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _syncedBanner = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = _resolveService(listen: true);
    final session = service.session;
    final tokens = FormaTheme.tokensOf(context);
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = math.min(screenSize.width - 32, 540.0);

    if (session == null || !service.isConnected) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: NeuCard(
          width: dialogWidth,
          radius: 20,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: FormaColors.dangerRed),
              const SizedBox(height: 12),
              Text(
                'No Active Collaborative Room',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: tokens.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Host or join a room from the Collaboration menu to access operator controls.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: tokens.textMuted),
              ),
              const SizedBox(height: 16),
              NeuButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    final isHost = service.isHost;
    final participants = session.participants;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: NeuCard(
        width: dialogWidth,
        radius: 24,
        padding: const EdgeInsets.all(22),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenSize.height * 0.88),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(tokens, service, isHost),
                const SizedBox(height: 16),

                if (_syncedBanner) ...[
                  _buildSyncNotice(tokens),
                  const SizedBox(height: 14),
                ],

                // Room Code Card
                _buildRoomCodeCard(tokens, session),
                const SizedBox(height: 16),

                // Host Controls (Lock Room & Force Sync)
                if (isHost) ...[
                  _buildOperatorControls(tokens, service),
                  const SizedBox(height: 16),
                ],

                // Connected Participants List & Permissions
                _buildParticipantsSection(tokens, service, participants, isHost),
                const SizedBox(height: 20),

                // Footer Actions (Leave / End Session)
                _buildFooterActions(tokens, service, isHost),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FormaThemeTokens tokens, CollabService service, bool isHost) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
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
                      isHost ? 'Room Operator Controls' : 'Room Participants & Status',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textMain,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Live ping indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: FormaColors.successGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: FormaColors.successGreen.withValues(alpha: 0.4),
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
                        Text(
                          '${service.pingMs}ms',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: FormaColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                isHost
                    ? 'You are the host • Manage drawing permissions, invite codes, and room security'
                    : 'Hosted by ${service.session?.host?.name ?? "Room Lead"} • Synchronized in real time',
                style: TextStyle(fontSize: 11.5, color: tokens.textMuted),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close_rounded, color: tokens.textMuted, size: 20),
          splashRadius: 18,
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildSyncNotice(FormaThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: FormaColors.primaryBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FormaColors.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: FormaColors.primaryBlue, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Canvas state broadcasted to all participants successfully!',
              style: TextStyle(
                fontSize: 12,
                color: FormaColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCodeCard(FormaThemeTokens tokens, CollabSession session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.wellBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FormaColors.primaryBlue.withValues(alpha: 0.25),
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
                      'ROOM CODE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: tokens.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
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
                  ],
                ),
              ),
              NeuButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: () => _copyRoomCode(session.roomId),
                color: _codeCopied ? FormaColors.successGreen : tokens.surface,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _codeCopied ? Icons.check_rounded : Icons.copy_rounded,
                      size: 15,
                      color: _codeCopied ? Colors.white : tokens.textMain,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _codeCopied ? 'Copied' : 'Copy Code',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _codeCopied ? Colors.white : tokens.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              NeuButton(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                onPressed: () => _copyInviteLink(session.roomId),
                color: tokens.surface,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _linkCopied ? Icons.check_rounded : Icons.link_rounded,
                      size: 15,
                      color: FormaColors.primaryBlue,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _linkCopied ? 'Link Copied' : 'Invite Link',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Share this 6-letter code with your friend to draw together in real time!',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: tokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorControls(FormaThemeTokens tokens, CollabService service) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.wellBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Host Room Controls',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: tokens.textMain,
            ),
          ),
          const SizedBox(height: 10),

          // Lock Room Tile
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  service.isRoomLocked
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  size: 18,
                  color: service.isRoomLocked
                      ? FormaColors.dangerRed
                      : FormaColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.isRoomLocked ? 'Room is Locked' : 'Lock Room',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.textMain,
                      ),
                    ),
                    Text(
                      service.isRoomLocked
                          ? 'New participants cannot join with room code'
                          : 'Block new participants from joining',
                      style: TextStyle(fontSize: 11, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: service.isRoomLocked,
                activeThumbColor: FormaColors.dangerRed,
                onChanged: (val) => service.setRoomLocked(val),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 10),

          // Force Sync Canvas Button
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sync_rounded,
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
                      'Force Canvas Synchronization',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.textMain,
                      ),
                    ),
                    Text(
                      'Resynchronize all layers if a peer had network lag',
                      style: TextStyle(fontSize: 11, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
              NeuButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                onPressed: () => _handleForceSync(service),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Sync Now',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection(
    FormaThemeTokens tokens,
    CollabService service,
    List<Collaborator> participants,
    bool isHost,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Connected Designers (${participants.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tokens.textMain,
              ),
            ),
            Text(
              isHost ? 'Tap badge to change permissions' : 'Participant Roles',
              style: TextStyle(fontSize: 11, color: tokens.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: tokens.wellBg,
            borderRadius: BorderRadius.circular(16),
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
              final pIsHost = p.id == service.session?.hostId;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    // Colored Avatar Circle
                    Container(
                      width: 34,
                      height: 34,
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

                    // Name and Status
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
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
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
                            ],
                          ),
                          Text(
                            pIsHost
                                ? 'Host / Session Admin'
                                : (p.canEdit ? 'Can Draw & Edit' : 'View Only'),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: tokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Role Badge / Selector
                    if (pIsHost) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                            SizedBox(width: 4),
                            Text(
                              'HOST',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isHost) ...[
                      // Host can switch peer between Editor and Viewer
                      PopupMenuButton<CollaboratorRole>(
                        initialValue: p.role,
                        tooltip: 'Change permission',
                        onSelected: (role) => service.updateCollaboratorRole(p.id, role),
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: CollaboratorRole.editor,
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 16, color: FormaColors.primaryBlue),
                                SizedBox(width: 8),
                                Text('Editor (Can Draw)'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: CollaboratorRole.viewer,
                            child: Row(
                              children: [
                                Icon(Icons.visibility_rounded, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Viewer (Read Only)'),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.canEdit
                                ? FormaColors.primaryBlue.withValues(alpha: 0.12)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: p.canEdit
                                  ? FormaColors.primaryBlue.withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                p.canEdit ? Icons.edit_rounded : Icons.visibility_rounded,
                                size: 12,
                                color: p.canEdit ? FormaColors.primaryBlue : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                p.canEdit ? 'Editor' : 'Viewer',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: p.canEdit ? FormaColors.primaryBlue : tokens.textMuted,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 14,
                                color: tokens.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Kick Button
                      IconButton(
                        icon: const Icon(
                          Icons.person_remove_rounded,
                          size: 16,
                          color: FormaColors.dangerRed,
                        ),
                        splashRadius: 16,
                        tooltip: 'Remove from room',
                        onPressed: () => service.kickCollaborator(p.id),
                      ),
                    ] else ...[
                      // Peer view of other peers
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tokens.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: tokens.borderSubtle),
                        ),
                        child: Text(
                          p.canEdit ? 'Editor' : 'Viewer',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: tokens.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        if (participants.length <= 1) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: tokens.wellBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: FormaColors.primaryBlue.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: FormaColors.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
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
                        'No other collaborators connected yet',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.textMain,
                        ),
                      ),
                      Text(
                        'Share your room code to invite friends!',
                        style: TextStyle(
                          fontSize: 11,
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                NeuButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  onPressed: () => _copyRoomCode(service.session?.roomId ?? ''),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Copy Code',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooterActions(
    FormaThemeTokens tokens,
    CollabService service,
    bool isHost,
  ) {
    return Row(
      children: [
        if (isHost) ...[
          Expanded(
            child: NeuButton(
              height: 42,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('End Session for All?'),
                    content: const Text(
                      'This will disconnect all designers and close the collaborative room.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'End Session',
                          style: TextStyle(color: FormaColors.dangerRed),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await service.endSessionForAll();
                  if (mounted) Navigator.of(context).pop();
                }
              },
              color: FormaColors.dangerRed.withValues(alpha: 0.12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.power_settings_new_rounded, size: 16, color: FormaColors.dangerRed),
                  SizedBox(width: 6),
                  Text(
                    'End for All',
                    style: TextStyle(
                      color: FormaColors.dangerRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: NeuButton(
            height: 42,
            onPressed: () async {
              await service.leaveRoom();
              if (mounted) Navigator.of(context).pop();
            },
            color: tokens.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, size: 16, color: tokens.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Leave Room',
                  style: TextStyle(
                    color: tokens.textMain,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
