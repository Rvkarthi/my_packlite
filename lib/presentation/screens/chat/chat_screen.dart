import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../presentation/providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Auto-scroll when messages change
    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const Gap(10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Assistant', style: theme.textTheme.titleMedium),
                Text(
                  _statusLabel(state.status),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _statusColor(state.status, cs),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (state.status == GemmaStatus.ready)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear chat',
              onPressed: () => ref.read(chatProvider.notifier).clearChat(),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Status / Download banner ──────────────────────────────────
          if (state.status != GemmaStatus.ready) _StatusBanner(state: state),

          // ── Messages ──────────────────────────────────────────────────
          Expanded(
            child: state.messages.isEmpty
                ? _EmptyState(status: state.status)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: state.messages.length,
                    itemBuilder: (ctx, i) =>
                        _MessageBubble(msg: state.messages[i]),
                  ),
          ),

          // ── Input bar ─────────────────────────────────────────────────
          _InputBar(
            ctrl: _ctrl,
            enabled: state.status == GemmaStatus.ready && !state.isGenerating,
            isGenerating: state.isGenerating,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  String _statusLabel(GemmaStatus s) {
    switch (s) {
      case GemmaStatus.idle:
        return 'Tap to load model';
      case GemmaStatus.downloading:
        return 'Downloading model...';
      case GemmaStatus.loading:
        return 'Loading model...';
      case GemmaStatus.ready:
        return 'Gemma 3 1B · On-device';
      case GemmaStatus.error:
        return 'Error';
    }
  }

  Color _statusColor(GemmaStatus s, ColorScheme cs) {
    switch (s) {
      case GemmaStatus.ready:
        return Colors.green;
      case GemmaStatus.error:
        return Colors.red;
      default:
        return cs.primary;
    }
  }
}

// ── Status Banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final GemmaState state;
  const _StatusBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (state.status == GemmaStatus.error) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: Colors.red.withValues(alpha: 0.1),
        child: Text(
          'Error: ${state.errorMessage}',
          style: const TextStyle(color: Colors.red, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (state.status == GemmaStatus.downloading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: cs.primary.withValues(alpha: 0.07),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.download_rounded, size: 16, color: cs.primary),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Downloading Gemma 3 1B (~700MB)...',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${(state.downloadProgress * 100).round()}%',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Gap(6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.downloadProgress,
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(cs.primary),
                minHeight: 5,
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == GemmaStatus.loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: cs.primary.withValues(alpha: 0.07),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: cs.primary),
            ),
            const Gap(10),
            Text('Initializing model...', style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends ConsumerWidget {
  final GemmaStatus status;
  const _EmptyState({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  size: 40, color: cs.primary),
            ),
            const Gap(20),
            Text('On-Device AI Assistant',
                style: theme.textTheme.titleLarge),
            const Gap(8),
            Text(
              'Powered by Gemma 3 1B running entirely on your device.\nNo internet needed after first download.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            _SuggestionChips(),
            const Gap(24),
            if (status == GemmaStatus.idle)
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(chatProvider.notifier).initModel(),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Load AI Model (~700MB)'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChips extends ConsumerWidget {
  static const _suggestions = [
    'What should I pack for a beach trip?',
    'Packing tips for cold weather',
    'How to pack light for 2 weeks?',
    'Essential travel documents checklist',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(chatProvider);
    if (state.status != GemmaStatus.ready) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _suggestions
          .map((s) => ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 12)),
                backgroundColor: cs.primary.withValues(alpha: 0.08),
                side: BorderSide(color: cs.primary.withValues(alpha: 0.2)),
                onPressed: () =>
                    ref.read(chatProvider.notifier).sendMessage(s),
              ))
          .toList(),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 14),
            ),
            const Gap(8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? cs.primary
                    : theme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: msg.isStreaming && msg.text.isEmpty
                  ? _TypingIndicator(color: cs.primary)
                  : Text(
                      msg.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isUser ? Colors.white : cs.onSurface,
                      ),
                    ),
            ),
          ),
          if (isUser) const Gap(8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i / 3;
          final opacity = ((_ctrl.value - delay) % 1.0).abs();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Opacity(
              opacity: opacity < 0.5 ? opacity * 2 : (1 - opacity) * 2,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends ConsumerWidget {
  final TextEditingController ctrl;
  final bool enabled;
  final bool isGenerating;
  final VoidCallback onSend;

  const _InputBar({
    required this.ctrl,
    required this.enabled,
    required this.isGenerating,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(chatProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1C1E21)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Load model button if not ready
          if (state.status == GemmaStatus.idle)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(chatProvider.notifier).initModel(),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Load AI Model'),
              ),
            )
          else ...[
            Expanded(
              child: TextField(
                controller: ctrl,
                enabled: enabled,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? (_) => onSend() : null,
                decoration: InputDecoration(
                  hintText: isGenerating
                      ? 'Generating...'
                      : 'Ask about packing, travel tips...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cs.onSurface.withValues(alpha: 0.06),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const Gap(8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: isGenerating
                  ? Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.primary),
                      ),
                    )
                  : IconButton.filled(
                      onPressed: enabled ? onSend : null,
                      icon: const Icon(Icons.send_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(44, 44),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
