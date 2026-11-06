import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/ai_engine_service.dart';
import '../services/model_manager_service.dart';
import '../services/myket_billing_service.dart';
import 'model_store_screen.dart';

class ChatScreen extends StatefulWidget {
  final AiEngineService aiEngine;
  final ModelManagerService modelManager;
  final MyketBillingService billingService;

  const ChatScreen({
    super.key,
    required this.aiEngine,
    required this.modelManager,
    required this.billingService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = TextEditingController() as dynamic ?? ScrollController();
  bool _isGenerating = false;
  String _selectedPersona = "دستیار همه‌فن‌حریف";

  final Map<String, String> _personas = {
    "دستیار همه‌فن‌حریف": "تو جارویس پلاس هستی؛ دستیار هوش مصنوعی هوشمند، سریع و کاملاً آفلاین که با زبان فارسی سلیس و محترمانه پاسخ می‌دهی.",
    "برنامه‌نویس و کدنویس": "تو جارویس پلاس در نقش مهندس ارشد نرم‌افزار هستی. کدهای تمیز، بهینه و با توضیح فارسی ارائه می‌دهی.",
    "نویسنده و شاعر خلاق": "تو جارویس پلاس در نقش نویسنده و ویراستار ادبی هستی. متن‌های گیرا، بازنویسی‌های جذاب و محتوای باکیفیت به فارسی می‌نویسی.",
    "استاد زبان انگلیسی": "تو جارویس پلاس در نقش مدرس حرفه‌ای زبان انگلیسی هستی. قواعد، ترجمه و مکالمات را به زبان‌آموزان ایرانی آموزش می‌دهی.",
  };

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        id: "welcome",
        text: "درود! من جارویس پلاس هستم، دستیار هوش مصنوعی شما که کاملاً آفلاین و با تکیه بر سخت‌افزار گوشی‌تان کار می‌کنم. بدون نیاز به اینترنت و بدون فیلترشکن در خدمت شما هستم.",
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    if (!widget.aiEngine.isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("لطفاً ابتدا از منوی بالا یک مدل رایگان را انتخاب یا دریافت نمایید."),
          backgroundColor: Colors.amber,
        ),
      );
      _openModelStore();
      return;
    }

    _textController.clear();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final assistantMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    final assistantMsg = ChatMessage(
      id: assistantMsgId,
      text: "",
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isThinking: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(assistantMsg);
      _isGenerating = true;
    });

    _scrollToBottom();

    final stopwatch = Stopwatch()..start();
    int tokenCount = 0;
    String fullResponse = "";

    final systemPrompt = _personas[_selectedPersona] ?? _personas["دستیار همه‌فن‌حریف"]!;

    try {
      final stream = widget.aiEngine.generateStream(
        _messages.sublist(0, _messages.length - 1),
        systemPrompt: systemPrompt,
      );

      await for (final token in stream) {
        fullResponse += token;
        tokenCount++;
        final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000.0;
        final tps = elapsedSeconds > 0 ? (tokenCount / elapsedSeconds) : 0.0;

        setState(() {
          final index = _messages.indexWhere((m) => m.id == assistantMsgId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
              text: fullResponse,
              isThinking: false,
              tokensPerSecond: tps,
            );
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantMsgId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            text: "خطا در پردازش روی گوشی: $e",
            isThinking: false,
          );
        }
      });
    } finally {
      stopwatch.stop();
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openModelStore() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModelStoreScreen(
          modelManager: widget.modelManager,
          aiEngine: widget.aiEngine,
          billingService: widget.billingService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 2,
          title: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.aiEngine.isModelLoaded ? const Color(0xFF10B981) : Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "جارویس پلاس",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF3B82F6), width: 0.8),
                ),
                child: const Text(
                  "کاملاً آفلاین",
                  style: TextStyle(fontSize: 10, color: Color(0xFF60A5FA)),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.psychology, color: Color(0xFF38BDF8)),
              tooltip: "مدیریت مدل‌ها",
              onPressed: _openModelStore,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.person_pin, color: Colors.white70),
              tooltip: "انتخاب تخصص",
              onSelected: (persona) {
                setState(() => _selectedPersona = persona);
              },
              itemBuilder: (context) => _personas.keys.map((p) {
                return PopupMenuItem(
                  value: p,
                  child: Text(
                    p,
                    style: TextStyle(
                      fontWeight: p == _selectedPersona ? FontWeight.bold : FontWeight.normal,
                      color: p == _selectedPersona ? const Color(0xFF38BDF8) : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFF1E293B).withOpacity(0.6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "شخصیت جاری: $_selectedPersona",
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                  Text(
                    widget.aiEngine.isModelLoaded ? "موتور محلی آماده است" : "مدل انتخاب نشده",
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.aiEngine.isModelLoaded ? const Color(0xFF34D399) : Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg.role == MessageRole.user;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Align(
                      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 4 : 16),
                            bottomRight: Radius.circular(isUser ? 16 : 4),
                          ),
                          border: Border.all(
                            color: isUser ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg.isThinking)
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                                  ),
                                  SizedBox(width: 8),
                                  Text("در حال تفکر روی تراشه گوشی...", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              )
                            else
                              SelectableText(
                                msg.text,
                                style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.55),
                              ),
                            if (msg.tokensPerSecond != null && msg.tokensPerSecond! > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  "سرعت تولید: ${msg.tokensPerSecond!.toStringAsFixed(1)} توکن/ثانیه",
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF1E293B),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLines: 4,
                        minLines: 1,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "از جارویس بپرسید (بدون نیاز به اینترنت)...",
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13.5),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: _isGenerating ? Colors.grey : const Color(0xFF3B82F6),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_upward, color: Colors.white),
                        onPressed: _isGenerating ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
