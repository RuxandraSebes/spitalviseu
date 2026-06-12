import 'package:flutter/material.dart';
import 'package:spital_visu_upu/data/services/chat_service.dart';
import 'package:spital_visu_upu/data/models/user_model.dart';
import 'package:spital_visu_upu/i18n/language_provider.dart';
import 'package:spital_visu_upu/features/chat/presentation/screens/chat_screen.dart';
import 'package:spital_visu_upu/core/theme/app_colors.dart';
import 'package:spital_visu_upu/shared/widgets/program_emblem_background.dart';
import 'package:spital_visu_upu/shared/widgets/unread_badge.dart';

/// Lists chat conversations for doctors and companions with multiple patients.
class ChatConversationsScreen extends StatefulWidget {
  final UserModel currentUser;
  final Function(int)? onUnreadChanged;

  const ChatConversationsScreen({
    super.key,
    required this.currentUser,
    this.onUnreadChanged,
  });

  @override
  State<ChatConversationsScreen> createState() =>
      _ChatConversationsScreenState();
}

class _ChatConversationsScreenState extends State<ChatConversationsScreen> {
  final _service = ChatService();
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  int get _totalUnread => _conversations.fold(
      0, (sum, c) => sum + ((c['unread_count'] ?? 0) as int));

  String _tr(String key) => LanguageProvider.of(context)?.tr(key) ?? key;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Opens a conversation and reloads the list when returning.
  Future<void> _openConversation(Map<String, dynamic> conv) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          currentUser: widget.currentUser,
          patientId: conv['patient_id'],
          patientName: conv['patient_name'] ?? '',
        ),
      ),
    );

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 600));
    await _load();
  }

  /// Fetches conversations and notifies [onUnreadChanged] with the total unread count.
  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.getConversations();
    if (mounted) {
      setState(() {
        _conversations = list;
        _loading = false;
      });
      widget.onUnreadChanged?.call(_totalUnread);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        foregroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tr('chat_title'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (_totalUnread > 0) ...[
              const SizedBox(width: 8),
              UnreadBadge(count: _totalUnread, fontSize: 12),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: ProgramEmblemBackground(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _conversations.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _conversations.length,
                      itemBuilder: (_, i) {
                        final conv = _conversations[i];
                        final unread = (conv['unread_count'] ?? 0) as int;
                        final total = (conv['total_count'] ?? 0) as int;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openConversation(conv),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.12),
                                    child: const Icon(Icons.person,
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          conv['patient_name'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: unread > 0
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          conv['last_message'] ??
                                              _tr('no_message'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                          style: TextStyle(
                                            color: unread > 0
                                                ? AppColors.primary
                                                : Colors.grey.shade500,
                                            fontSize: 12,
                                            fontWeight: unread > 0
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        if (total > 0) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '$total ${total == 1 ? _tr('message_count_singular') : _tr('messages_count')}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (conv['last_time'] != null)
                                        Text(
                                          _formatTime(conv['last_time']),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      if (unread > 0) ...[
                                        const SizedBox(height: 6),
                                        UnreadBadge(count: unread),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.chat_bubble_outline,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(_tr('no_messages'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text(_tr('patients_initiate'),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      );

  /// Formats an ISO timestamp for display in the conversation list.
  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
