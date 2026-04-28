import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/flutter_gemma_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Message model ─────────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isStreaming;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
  });

  ChatMessage copyWith({String? text, bool? isUser, bool? isStreaming}) =>
      ChatMessage(
        text: text ?? this.text,
        isUser: isUser ?? this.isUser,
        isStreaming: isStreaming ?? this.isStreaming,
      );
}

// ── Gemma state ───────────────────────────────────────────────────────────────

enum GemmaStatus { idle, downloading, loading, ready, error }

class GemmaState {
  final GemmaStatus status;
  final double downloadProgress;
  final String? errorMessage;
  final List<ChatMessage> messages;
  final bool isGenerating;

  const GemmaState({
    this.status = GemmaStatus.idle,
    this.downloadProgress = 0,
    this.errorMessage,
    this.messages = const [],
    this.isGenerating = false,
  });

  GemmaState copyWith({
    GemmaStatus? status,
    double? downloadProgress,
    String? errorMessage,
    List<ChatMessage>? messages,
    bool? isGenerating,
  }) =>
      GemmaState(
        status: status ?? this.status,
        downloadProgress: downloadProgress ?? this.downloadProgress,
        errorMessage: errorMessage ?? this.errorMessage,
        messages: messages ?? this.messages,
        isGenerating: isGenerating ?? this.isGenerating,
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final chatProvider =
    NotifierProvider<ChatNotifier, GemmaState>(ChatNotifier.new);

class ChatNotifier extends Notifier<GemmaState> {
  // Gemma 3 1B — ~500MB .task file, public (no HF token needed)
  static const _modelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task';
  static const _modelFileName = 'gemma3-1b-it-int4.task';

  InferenceModel? _model;
  InferenceChat? _chat;

  @override
  GemmaState build() => const GemmaState();

  Future<void> initModel() async {
    if (state.status == GemmaStatus.ready ||
        state.status == GemmaStatus.loading ||
        state.status == GemmaStatus.downloading) return;

    state = state.copyWith(status: GemmaStatus.downloading, downloadProgress: 0);

    try {
      final isInstalled = await FlutterGemma.isModelInstalled(_modelFileName);

      if (!isInstalled) {
        await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
            .fromNetwork(_modelUrl)
            .withProgress((progress) {
          state = state.copyWith(downloadProgress: progress / 100.0);
        }).install();
      }

      state = state.copyWith(status: GemmaStatus.loading, downloadProgress: 1.0);

      _model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: PreferredBackend.gpu,
      );

      _chat = await _model!.createChat(
        temperature: 0.8,
        topK: 40,
        randomSeed: 42,
      );

      state = state.copyWith(
        status: GemmaStatus.ready,
        messages: [
          const ChatMessage(
            text: 'Hi! I\'m PackLite AI, your on-device travel assistant. '
                'Ask me about packing lists, travel tips, or destination advice!',
            isUser: false,
          ),
        ],
      );
    } catch (e) {
      state = state.copyWith(
        status: GemmaStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isGenerating || _chat == null) return;

    final userMsg = ChatMessage(text: text.trim(), isUser: true);
    const botMsg = ChatMessage(text: '', isUser: false, isStreaming: true);

    state = state.copyWith(
      messages: [...state.messages, userMsg, botMsg],
      isGenerating: true,
    );

    try {
      await _chat!.addQueryChunk(Message.text(text: text.trim(), isUser: true));

      final buffer = StringBuffer();

      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is TextResponse) {
          buffer.write(response.token);
          final updated = List<ChatMessage>.from(state.messages);
          updated[updated.length - 1] =
              botMsg.copyWith(text: buffer.toString(), isStreaming: true);
          state = state.copyWith(messages: updated);
        }
      }

      final finalMessages = List<ChatMessage>.from(state.messages);
      finalMessages[finalMessages.length - 1] =
          botMsg.copyWith(text: buffer.toString(), isStreaming: false);
      state = state.copyWith(messages: finalMessages, isGenerating: false);
    } catch (e) {
      final msgs = List<ChatMessage>.from(state.messages);
      msgs[msgs.length - 1] = const ChatMessage(
        text: 'Sorry, something went wrong. Please try again.',
        isUser: false,
      );
      state = state.copyWith(messages: msgs, isGenerating: false);
    }
  }

  Future<void> clearChat() async {
    if (_model == null) return;
    _chat = await _model!.createChat(
      temperature: 0.8,
      topK: 40,
      randomSeed: 42,
    );
    state = state.copyWith(
      messages: [
        const ChatMessage(
          text: 'Chat cleared. How can I help you?',
          isUser: false,
        )
      ],
    );
  }
}
