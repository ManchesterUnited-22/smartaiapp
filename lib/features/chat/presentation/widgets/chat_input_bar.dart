// lib/features/chat/presentation/widgets/chat_input_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../speech/data/datasources/speech_to_text_datasource.dart';
import '../../../../core/widgets/aura_orb.dart';

class ChatInputBar extends StatefulWidget {
  final void Function(String) onSend;
  const ChatInputBar({super.key, required this.onSend});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _isListening = false;

  SpeechToTextDatasource get _speechDatasource =>
      context.read<SpeechToTextDatasource>();

  @override
  void initState() {
    super.initState();
    _speechDatasource.addStatusListener(_onSpeechStatus);
  }

  @override
  void dispose() {
    _speechDatasource.removeStatusListener(_onSpeechStatus);
    _controller.dispose();
    super.dispose();
  }

  // Đồng bộ lại UI khi engine TỰ dừng nghe (im lặng quá lâu, hết thời gian...)
  // — tránh AuraOrb nhấp nháy "đang nghe" dù thực tế đã dừng từ lâu.
  void _onSpeechStatus(String status) {
    if ((status == 'done' || status == 'notListening') && mounted && _isListening) {
      setState(() => _isListening = false);
    }
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechDatasource.stopListening();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    await _speechDatasource.startListening(
      onResult: (text) {
        if (!mounted) return;
        _controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleListening,
              child: _isListening
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: AuraOrb(size: 28, animate: true),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.mic_none_rounded, color: scheme.onSurfaceVariant),
                    ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: _isListening ? 'Đang nghe...' : 'Nhắn tin cho AI...',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintStyle: TextStyle(
                    color: _isListening ? scheme.primary : scheme.onSurfaceVariant,
                    fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            Material(
              color: scheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _submit,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.arrow_upward_rounded, color: scheme.onPrimary, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}