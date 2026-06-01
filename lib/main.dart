import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ChatApp(prefs: prefs));
}

// ─────────────────────────────────────────────────────────────
// THEME DEFINITIONS
// ─────────────────────────────────────────────────────────────
class AppThemes {
  static const List<Map<String, dynamic>> themes = [
    {
      'name': 'Midnight Aurora',
      'primary': Color(0xFF6C63FF),
      'secondary': Color(0xFF00D4AA),
      'bg': Color(0xFF0A0E1A),
      'surface': Color(0xFF111827),
      'card': Color(0xFF1A2235),
      'userBubble': Color(0xFF6C63FF),
      'botBubble': Color(0xFF1E2D45),
      'text': Color(0xFFE8EBF0),
      'subtext': Color(0xFF8892A4),
      'accent': Color(0xFF00D4AA),
      'isDark': true,
    },
    {
      'name': 'Rose Gold',
      'primary': Color(0xFFE91E8C),
      'secondary': Color(0xFFFF6B35),
      'bg': Color(0xFF1A0A14),
      'surface': Color(0xFF261020),
      'card': Color(0xFF331828),
      'userBubble': Color(0xFFE91E8C),
      'botBubble': Color(0xFF2D1525),
      'text': Color(0xFFF5E6EE),
      'subtext': Color(0xFF9E7589),
      'accent': Color(0xFFFF6B35),
      'isDark': true,
    },
    {
      'name': 'Ocean Breeze',
      'primary': Color(0xFF0284C7),
      'secondary': Color(0xFF06B6D4),
      'bg': Color(0xFFF0F9FF),
      'surface': Color(0xFFFFFFFF),
      'card': Color(0xFFE0F2FE),
      'userBubble': Color(0xFF0284C7),
      'botBubble': Color(0xFFE0F2FE),
      'text': Color(0xFF0C4A6E),
      'subtext': Color(0xFF64748B),
      'accent': Color(0xFF06B6D4),
      'isDark': false,
    },
    {
      'name': 'Forest Dusk',
      'primary': Color(0xFF22C55E),
      'secondary': Color(0xFF84CC16),
      'bg': Color(0xFF052E16),
      'surface': Color(0xFF071F0F),
      'card': Color(0xFF0F3320),
      'userBubble': Color(0xFF16A34A),
      'botBubble': Color(0xFF0A2A14),
      'text': Color(0xFFDCFCE7),
      'subtext': Color(0xFF6EE7B7),
      'accent': Color(0xFF84CC16),
      'isDark': true,
    },
    {
      'name': 'Cyberpunk',
      'primary': Color(0xFFFFE600),
      'secondary': Color(0xFFFF00AA),
      'bg': Color(0xFF060614),
      'surface': Color(0xFF0E0E2A),
      'card': Color(0xFF16163A),
      'userBubble': Color(0xFFFFE600),
      'botBubble': Color(0xFF1A1A40),
      'text': Color(0xFFF0F0FF),
      'subtext': Color(0xFF888ACC),
      'accent': Color(0xFFFF00AA),
      'isDark': true,
    },
    {
      'name': 'Pure White',
      'primary': Color(0xFF5B21B6),
      'secondary': Color(0xFF7C3AED),
      'bg': Color(0xFFFAFAFA),
      'surface': Color(0xFFFFFFFF),
      'card': Color(0xFFF3F4F6),
      'userBubble': Color(0xFF5B21B6),
      'botBubble': Color(0xFFF3F4F6),
      'text': Color(0xFF111827),
      'subtext': Color(0xFF6B7280),
      'accent': Color(0xFF7C3AED),
      'isDark': false,
    },
  ];
}

// ─────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────
enum MessageType { text, image, code, mixed }

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final MessageType type;
  final String? imagePath;
  final String? codeLanguage;
  final DateTime timestamp;
  bool isTyping;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    this.type = MessageType.text,
    this.imagePath,
    this.codeLanguage,
    required this.timestamp,
    this.isTyping = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'isUser': isUser,
        'type': type.index,
        'imagePath': imagePath,
        'codeLanguage': codeLanguage,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        content: j['content'],
        isUser: j['isUser'],
        type: MessageType.values[j['type'] ?? 0],
        imagePath: j['imagePath'],
        codeLanguage: j['codeLanguage'],
        timestamp: DateTime.parse(j['timestamp']),
      );
}

// ─────────────────────────────────────────────────────────────
// ROOT APP
// ─────────────────────────────────────────────────────────────
class ChatApp extends StatefulWidget {
  final SharedPreferences prefs;
  const ChatApp({super.key, required this.prefs});

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  int _themeIndex = 0;

  @override
  void initState() {
    super.initState();
    _themeIndex = widget.prefs.getInt('themeIndex') ?? 0;
  }

  void _setTheme(int idx) {
    setState(() => _themeIndex = idx);
    widget.prefs.setInt('themeIndex', idx);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemes.themes[_themeIndex];
    final isDark = t['isDark'] as bool;
    final primary = t['primary'] as Color;
    final bg = t['bg'] as Color;
    final surface = t['surface'] as Color;
    final textColor = t['text'] as Color;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NexusAI',
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: bg,
        primaryColor: primary,
        colorScheme: ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: primary,
          onPrimary: Colors.white,
          secondary: t['secondary'] as Color,
          onSecondary: Colors.white,
          error: Colors.redAccent,
          onError: Colors.white,
          surface: surface,
          onSurface: textColor,
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: textColor, fontFamily: 'Roboto'),
        ),
        useMaterial3: true,
      ),
      home: RootRouter(prefs: widget.prefs, themeIndex: _themeIndex, onThemeChange: _setTheme),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ROOT ROUTER  – shows Onboarding if no username saved
// ─────────────────────────────────────────────────────────────
class RootRouter extends StatefulWidget {
  final SharedPreferences prefs;
  final int themeIndex;
  final void Function(int) onThemeChange;
  const RootRouter({super.key, required this.prefs, required this.themeIndex, required this.onThemeChange});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  bool _ready = false;
  bool _hasUser = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  void _check() {
    final name = widget.prefs.getString('username') ?? '';
    setState(() {
      _hasUser = name.isNotEmpty;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_hasUser) {
      return OnboardingScreen(
        prefs: widget.prefs,
        themeIndex: widget.themeIndex,
        onDone: () => setState(() => _hasUser = true),
      );
    }
    return ChatScreen(
      prefs: widget.prefs,
      themeIndex: widget.themeIndex,
      onThemeChange: widget.onThemeChange,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ONBOARDING  – username + avatar selection
// ─────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final int themeIndex;
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.prefs, required this.themeIndex, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  String? _avatarPath;
  int _avatarEmoji = 0;
  bool _useImage = false;
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  final List<String> _emojis = ['🧑', '👩', '👨', '🧒', '👦', '👧', '🧑‍💻', '👩‍💻', '🦊', '🐱', '🐶', '🦄', '🤖', '👾', '🧙', '🦸'];

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _t => AppThemes.themes[widget.themeIndex];

  Future<void> _pickAvatar() async {
    final p = ImagePicker();
    final img = await p.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() { _avatarPath = img.path; _useImage = true; });
  }

  void _save() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please enter your name'), backgroundColor: Colors.red.shade700),
      );
      return;
    }
    widget.prefs.setString('username', name);
    widget.prefs.setInt('avatarEmoji', _avatarEmoji);
    if (_avatarPath != null) widget.prefs.setString('avatarPath', _avatarPath!);
    widget.prefs.setBool('avatarUseImage', _useImage);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final primary = t['primary'] as Color;
    final bg = t['bg'] as Color;
    final card = t['card'] as Color;
    final textColor = t['text'] as Color;
    final subtext = t['subtext'] as Color;
    final accent = t['accent'] as Color;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            children: [
              // Floating robot icon
              AnimatedBuilder(
                animation: _floatAnim,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
                    ),
                    child: const Center(child: Text('🤖', style: TextStyle(fontSize: 48))),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('Welcome to NexusAI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('Set up your profile to get started', style: TextStyle(fontSize: 14, color: subtext)),
              const SizedBox(height: 40),

              // Avatar section
              Text('Choose Your Avatar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subtext, letterSpacing: 1)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [primary.withOpacity(0.3), accent.withOpacity(0.3)]),
                        border: Border.all(color: primary, width: 3),
                      ),
                      child: ClipOval(
                        child: _useImage && _avatarPath != null
                            ? Image.file(File(_avatarPath!), fit: BoxFit.cover)
                            : Center(child: Text(_emojis[_avatarEmoji], style: const TextStyle(fontSize: 44))),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: primary),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Emoji picker grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: List.generate(_emojis.length, (i) => GestureDetector(
                    onTap: () => setState(() { _avatarEmoji = i; _useImage = false; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _avatarEmoji == i && !_useImage ? primary.withOpacity(0.3) : Colors.transparent,
                        border: Border.all(color: _avatarEmoji == i && !_useImage ? primary : Colors.transparent, width: 2),
                      ),
                      child: Center(child: Text(_emojis[i], style: const TextStyle(fontSize: 22))),
                    ),
                  )),
                ),
              ),
              const SizedBox(height: 28),

              // Name field
              Container(
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _ctrl,
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Enter your name...',
                    hintStyle: TextStyle(color: subtext),
                    prefixIcon: Icon(Icons.person_outline, color: primary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Start button
              GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [primary, accent]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Text('Start Chatting →', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MAIN CHAT SCREEN
// ─────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final int themeIndex;
  final void Function(int) onThemeChange;
  const ChatScreen({super.key, required this.prefs, required this.themeIndex, required this.onThemeChange});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  XFile? _pendingImage;
  bool _showCodeInput = false;
  final _codeCtrl = TextEditingController();
  String _codeLanguage = 'dart';
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // User info
  String _username = '';
  String? _avatarPath;
  int _avatarEmoji = 0;
  bool _avatarUseImage = false;
  final List<String> _emojis = ['🧑', '👩', '👨', '🧒', '👦', '👧', '🧑‍💻', '👩‍💻', '🦊', '🐱', '🐶', '🦄', '🤖', '👾', '🧙', '🦸'];

  final List<String> _codeLanguages = ['dart', 'python', 'javascript', 'java', 'kotlin', 'swift', 'c++', 'html', 'css', 'sql', 'bash', 'json'];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseCtrl);
    _loadData();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _codeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _loadData() {
    _username = widget.prefs.getString('username') ?? 'User';
    _avatarPath = widget.prefs.getString('avatarPath');
    _avatarEmoji = widget.prefs.getInt('avatarEmoji') ?? 0;
    _avatarUseImage = widget.prefs.getBool('avatarUseImage') ?? false;
    _groqApiKey = widget.prefs.getString('groqApiKey') ?? '';

    final raw = widget.prefs.getString('chatHistory');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _messages = list.map((e) => ChatMessage.fromJson(e)).toList();
      } catch (_) {}
    }

    if (_messages.isEmpty) {
      final hasKey = (_groqApiKey).isNotEmpty;
      _messages.add(ChatMessage(
        id: _uid(),
        content: hasKey
            ? 'Hi $_username! 👋 I\'m **NexusAI**, powered by **Groq AI**.\n\nI can help you with:\n• 💬 General conversations\n• 🖼️ Image uploads & discussion\n• 💻 Code review & debugging\n• 📝 Writing & creativity\n\nHow can I assist you today?'
            : 'Hi $_username! 👋 I\'m **NexusAI**, powered by **Groq AI**.\n\n⚠️ **Setup Required**: Please tap your avatar (top right) to open **Settings** and enter your **Groq API key** to enable AI responses.\n\nGet a free key at **console.groq.com** 🚀',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
    setState(() {});
  }

  void _saveHistory() {
    final data = jsonEncode(_messages.map((m) => m.toJson()).toList());
    widget.prefs.setString('chatHistory', data);
  }

  String _uid() => DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(9999).toString();

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
      }
    });
  }

  // ── GROQ CONFIG ──────────────────────────────────────────────
  static const String _groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String _groqModel = 'openai/gpt-oss-20b';
  String _groqApiKey = '';

  String _getApiKey() {
    if (_groqApiKey.isNotEmpty) return _groqApiKey;
    return widget.prefs.getString('groqApiKey') ?? '';
  }

  // Build conversation history for the API (last 20 messages for context)
  List<Map<String, String>> _buildConversationHistory(String newUserMessage) {
    final history = <Map<String, String>>[];
    // System prompt
    history.add({
      'role': 'system',
      'content':
          'You are NexusAI, a highly intelligent, friendly, and helpful AI assistant. '
          'The user\'s name is $_username. Address them by name occasionally. '
          'Be concise, insightful, and use a warm conversational tone. '
          'When reviewing code, provide specific actionable feedback. '
          'Use markdown-style **bold** for emphasis where appropriate.',
    });
    // Past messages (skip typing indicators, limit to last 18)
    final real = _messages.where((m) => !m.isTyping).toList();
    final slice = real.length > 18 ? real.sublist(real.length - 18) : real;
    for (final m in slice) {
      if (m.type == MessageType.image) continue; // skip image-only msgs
      history.add({
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.type == MessageType.code
            ? 'Here is my ${m.codeLanguage ?? ''} code:\n\`\`\`${m.codeLanguage ?? ''}\n${m.content}\n\`\`\`'
            : m.content,
      });
    }
    // New user message
    history.add({'role': 'user', 'content': newUserMessage});
    return history;
  }

  // Core Groq API call
  Future<String> _callGroq(List<Map<String, String>> messages) async {
    final apiKey = _getApiKey();
    if (apiKey.isEmpty) {
      return '⚠️ **No API Key set!**\n\nPlease open **Settings** (tap your avatar) and enter your Groq API key to enable AI responses.\n\nGet a free key at [console.groq.com](https://console.groq.com).';
    }
    try {
      final response = await http.post(
        Uri.parse('$_groqBaseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _groqModel,
          'messages': messages,
          'max_tokens': 1024,
          'temperature': 0.7,
          'top_p': 0.9,
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] ?? '';
        return content.toString().trim();
      } else if (response.statusCode == 401) {
        return '🔑 **Invalid API Key**\n\nYour Groq API key is invalid or expired. Please update it in Settings.';
      } else if (response.statusCode == 429) {
        return '⏳ **Rate Limit Reached**\n\nToo many requests. Please wait a moment and try again.';
      } else {
        final err = jsonDecode(response.body);
        final msg = err['error']?['message'] ?? 'Unknown error';
        return '❌ **API Error ${response.statusCode}**\n\n$msg';
      }
    } on SocketException {
      return '🌐 **No Internet Connection**\n\nPlease check your network and try again.';
    } catch (e) {
      return '❌ **Error**: ${e.toString()}\n\nPlease try again.';
    }
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _pendingImage = img);
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    final hasImage = _pendingImage != null;
    final userMsg = ChatMessage(
      id: _uid(),
      content: text,
      isUser: true,
      type: hasImage ? (text.isNotEmpty ? MessageType.mixed : MessageType.image) : MessageType.text,
      imagePath: _pendingImage?.path,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _pendingImage = null;
      _msgCtrl.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    // Typing indicator
    final typingMsg = ChatMessage(id: 'typing', content: '', isUser: false, timestamp: DateTime.now(), isTyping: true);
    setState(() => _messages.add(typingMsg));
    _scrollToBottom();

    // Build prompt — mention image if attached
    String prompt = text;
    if (hasImage && text.isEmpty) {
      prompt = 'I have shared an image with you. Please acknowledge it and ask how you can help analyze or discuss it.';
    } else if (hasImage && text.isNotEmpty) {
      prompt = '$text\n\n[Note: The user also attached an image. Acknowledge you can see an image was shared, but explain vision analysis requires a vision-capable model.]';
    }

    final history = _buildConversationHistory(prompt);
    final reply = await _callGroq(history);

    setState(() {
      _messages.removeWhere((m) => m.id == 'typing');
      _messages.add(ChatMessage(id: _uid(), content: reply, isUser: false, timestamp: DateTime.now()));
      _isLoading = false;
    });
    _saveHistory();
    _scrollToBottom();
  }

  Future<void> _sendCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;

    final userMsg = ChatMessage(
      id: _uid(), content: code, isUser: true,
      type: MessageType.code, codeLanguage: _codeLanguage,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMsg);
      _showCodeInput = false;
      _codeCtrl.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    final typingMsg = ChatMessage(id: 'typing', content: '', isUser: false, timestamp: DateTime.now(), isTyping: true);
    setState(() => _messages.add(typingMsg));
    _scrollToBottom();

    final prompt =
        'Please review the following $_codeLanguage code. '
        'Provide: 1) A brief summary of what it does, 2) Any bugs or issues found, '
        '3) Specific improvement suggestions, 4) Best practices tips.\n\n'
        '\`\`\`$_codeLanguage\n$code\n\`\`\`';

    final history = _buildConversationHistory(prompt);
    final reply = await _callGroq(history);

    setState(() {
      _messages.removeWhere((m) => m.id == 'typing');
      _messages.add(ChatMessage(id: _uid(), content: reply, isUser: false, timestamp: DateTime.now()));
      _isLoading = false;
    });
    _saveHistory();
    _scrollToBottom();
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _t['card'] as Color,
        title: Text('Clear Chat', style: TextStyle(color: _t['text'] as Color)),
        content: Text('Delete all messages?', style: TextStyle(color: _t['subtext'] as Color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _messages.clear());
              widget.prefs.remove('chatHistory');
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> get _t => AppThemes.themes[widget.themeIndex];

  Widget _buildAvatar({required bool isUser, double size = 36}) {
    if (isUser) {
      final primary = _t['primary'] as Color;
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [primary, (_t['accent'] as Color)]),
        ),
        child: ClipOval(
          child: _avatarUseImage && _avatarPath != null
              ? Image.file(File(_avatarPath!), fit: BoxFit.cover)
              : Center(child: Text(_emojis[_avatarEmoji], style: TextStyle(fontSize: size * 0.5))),
        ),
      );
    }
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [const Color(0xFF6C63FF), const Color(0xFF00D4AA)]),
      ),
      child: Center(child: Text('🤖', style: TextStyle(fontSize: size * 0.5))),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final t = _t;
    final primary = t['primary'] as Color;
    final userBubble = t['userBubble'] as Color;
    final botBubble = t['botBubble'] as Color;
    final textColor = t['text'] as Color;
    final subtext = t['subtext'] as Color;
    final accent = t['accent'] as Color;

    if (msg.isTyping) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildAvatar(isUser: false),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: botBubble, borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18),
              )),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, -4 * sin((_pulseCtrl.value * 2 * pi) + i * 1.0)),
                    child: Container(
                      margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                      width: 8, height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withOpacity(0.7)),
                    ),
                  ),
                )),
              ),
            ),
          ],
        ),
      );
    }

    final isUser = msg.isUser;
    final timeStr = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    Widget bubbleContent;

    if (msg.type == MessageType.code) {
      bubbleContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(msg.codeLanguage?.toUpperCase() ?? 'CODE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: primary, letterSpacing: 1)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Clipboard.setData(ClipboardData(text: msg.content)),
                child: Icon(Icons.copy, size: 14, color: subtext),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(msg.content,
                style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 13, color: Color(0xFF79C0FF), height: 1.5,
                )),
          ),
        ],
      );
    } else {
      final parts = _parseContent(msg.content);
      bubbleContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: parts.map((p) {
          if (p['type'] == 'bold') {
            return Text(p['text']!, style: TextStyle(fontWeight: FontWeight.w700, color: isUser ? Colors.white : textColor, fontSize: 14, height: 1.5));
          }
          return Text(p['text']!, style: TextStyle(color: isUser ? Colors.white : textColor, fontSize: 14, height: 1.5));
        }).toList(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[_buildAvatar(isUser: false), const SizedBox(width: 8)],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!isUser)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text('NexusAI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
                        ),
                      if (msg.imagePath != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(File(msg.imagePath!), width: 200, height: 150, fit: BoxFit.cover),
                          ),
                        ),
                      if (msg.content.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isUser ? userBubble : botBubble,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isUser ? 18 : 4),
                              topRight: Radius.circular(isUser ? 4 : 18),
                              bottomLeft: const Radius.circular(18),
                              bottomRight: const Radius.circular(18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isUser ? userBubble : botBubble).withOpacity(0.3),
                                blurRadius: 8, offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: bubbleContent,
                        ),
                    ],
                  ),
                ),
              ),
              if (isUser) ...[const SizedBox(width: 8), _buildAvatar(isUser: true)],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: isUser ? 0 : 52, right: isUser ? 52 : 0, top: 3),
            child: Text(timeStr, style: TextStyle(fontSize: 10, color: subtext)),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _parseContent(String text) {
    final parts = <Map<String, String>>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > last) parts.add({'type': 'normal', 'text': text.substring(last, m.start)});
      parts.add({'type': 'bold', 'text': m.group(1)!});
      last = m.end;
    }
    if (last < text.length) parts.add({'type': 'normal', 'text': text.substring(last)});
    if (parts.isEmpty) parts.add({'type': 'normal', 'text': text});
    return parts;
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsSheet(
        prefs: widget.prefs,
        themeIndex: widget.themeIndex,
        onThemeChange: widget.onThemeChange,
        onApiKeyChange: (key) {
          setState(() => _groqApiKey = key);
          widget.prefs.setString('groqApiKey', key);
        },
        groqApiKey: _groqApiKey,
        onLogout: () {
          Navigator.pop(context);
          widget.prefs.remove('username');
          widget.prefs.remove('avatarPath');
          widget.prefs.remove('avatarEmoji');
          widget.prefs.remove('avatarUseImage');
          widget.prefs.remove('chatHistory');
          widget.prefs.remove('groqApiKey');
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => RootRouter(prefs: widget.prefs, themeIndex: widget.themeIndex, onThemeChange: widget.onThemeChange),
          ));
        },
        username: _username,
        avatarEmoji: _avatarEmoji,
        avatarPath: _avatarPath,
        avatarUseImage: _avatarUseImage,
        emojis: _emojis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final primary = t['primary'] as Color;
    final bg = t['bg'] as Color;
    final surface = t['surface'] as Color;
    final card = t['card'] as Color;
    final textColor = t['text'] as Color;
    final subtext = t['subtext'] as Color;
    final accent = t['accent'] as Color;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surface,
                border: Border(bottom: BorderSide(color: primary.withOpacity(0.15))),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [primary, accent]),
                          boxShadow: [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 10)],
                        ),
                        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 22))),
                      ),
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF22C55E),
                          border: Border.all(color: surface, width: 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NexusAI', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor)),
                        Text('● Online', style: TextStyle(fontSize: 11, color: const Color(0xFF22C55E), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _clearChat,
                    icon: Icon(Icons.delete_outline, color: subtext, size: 22),
                    tooltip: 'Clear chat',
                  ),
                  GestureDetector(
                    onTap: _openSettings,
                    child: _buildAvatar(isUser: true, size: 40),
                  ),
                ],
              ),
            ),

            // ── MESSAGES ──
            Expanded(
              child: _messages.isEmpty
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🤖', style: const TextStyle(fontSize: 64)),
                        const SizedBox(height: 12),
                        Text('Start a conversation!', style: TextStyle(color: subtext, fontSize: 16)),
                      ],
                    ))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _buildMessage(_messages[i]),
                    ),
            ),

            // ── IMAGE PREVIEW ──
            if (_pendingImage != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_pendingImage!.path), width: 60, height: 60, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Image ready to send', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(_pendingImage!.name, style: TextStyle(color: subtext, fontSize: 11), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _pendingImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.2)),
                        child: const Icon(Icons.close, size: 16, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // ── CODE INPUT PANEL ──
            if (_showCodeInput)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _codeLanguage,
                              dropdownColor: card,
                              style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w600),
                              items: _codeLanguages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                              onChanged: (v) => setState(() => _codeLanguage = v!),
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _showCodeInput = false),
                          child: Icon(Icons.close, size: 18, color: subtext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10)),
                      child: TextField(
                        controller: _codeCtrl,
                        maxLines: 6,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFF79C0FF), height: 1.5),
                        decoration: InputDecoration(
                          hintText: 'Paste your $_codeLanguage code here...',
                          hintStyle: const TextStyle(color: Color(0xFF3D4452), fontFamily: 'monospace'),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _sendCode,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [primary, accent]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text('Send Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── INPUT BAR ──
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: primary.withOpacity(0.1))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Image picker button
                  GestureDetector(
                    onTap: _pickImage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _pendingImage != null ? primary.withOpacity(0.2) : card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _pendingImage != null ? primary : Colors.transparent),
                      ),
                      child: Icon(Icons.image_outlined, color: _pendingImage != null ? primary : subtext, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Code button
                  GestureDetector(
                    onTap: () => setState(() => _showCodeInput = !_showCodeInput),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _showCodeInput ? primary.withOpacity(0.2) : card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _showCodeInput ? primary : Colors.transparent),
                      ),
                      child: Center(
                        child: Text('</>', style: TextStyle(
                          color: _showCodeInput ? primary : subtext,
                          fontSize: 12, fontWeight: FontWeight.w700,
                        )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Text input
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primary.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        maxLines: null,
                        style: TextStyle(color: textColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Message NexusAI...',
                          hintStyle: TextStyle(color: subtext),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  GestureDetector(
                    onTap: _isLoading ? null : _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: _isLoading ? null : LinearGradient(colors: [primary, accent]),
                        color: _isLoading ? card : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _isLoading ? [] : [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: _isLoading
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SETTINGS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────
class SettingsSheet extends StatefulWidget {
  final SharedPreferences prefs;
  final int themeIndex;
  final void Function(int) onThemeChange;
  final void Function(String) onApiKeyChange;
  final String groqApiKey;
  final VoidCallback onLogout;
  final String username;
  final int avatarEmoji;
  final String? avatarPath;
  final bool avatarUseImage;
  final List<String> emojis;

  const SettingsSheet({
    super.key,
    required this.prefs,
    required this.themeIndex,
    required this.onThemeChange,
    required this.onApiKeyChange,
    required this.groqApiKey,
    required this.onLogout,
    required this.username,
    required this.avatarEmoji,
    required this.avatarPath,
    required this.avatarUseImage,
    required this.emojis,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late int _selected;
  late TextEditingController _apiKeyCtrl;
  bool _apiKeyVisible = false;
  bool _apiKeySaved = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.themeIndex;
    _apiKeyCtrl = TextEditingController(text: widget.groqApiKey);
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemes.themes[_selected];
    final primary = t['primary'] as Color;
    final card = t['card'] as Color;
    final surface = t['surface'] as Color;
    final textColor = t['text'] as Color;
    final subtext = t['subtext'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: subtext.withOpacity(0.3), borderRadius: BorderRadius.circular(2),
              )),
            ),
            const SizedBox(height: 20),

            // Profile
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [primary, t['accent'] as Color]),
                  ),
                  child: ClipOval(
                    child: widget.avatarUseImage && widget.avatarPath != null
                        ? Image.file(File(widget.avatarPath!), fit: BoxFit.cover)
                        : Center(child: Text(widget.emojis[widget.avatarEmoji], style: const TextStyle(fontSize: 30))),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.username, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                    Text('NexusAI Member', style: TextStyle(fontSize: 12, color: primary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── API KEY SECTION ──
            Text('GROQ API KEY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subtext, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _apiKeyCtrl.text.isNotEmpty ? primary.withOpacity(0.5) : subtext.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _apiKeyCtrl.text.isNotEmpty ? const Color(0xFF22C55E) : Colors.orange,
                            )),
                            const SizedBox(width: 5),
                            Text(
                              _apiKeyCtrl.text.isNotEmpty ? 'Connected' : 'Not Set',
                              style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: _apiKeyCtrl.text.isNotEmpty ? const Color(0xFF22C55E) : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text('Model: gpt-oss-20b', style: TextStyle(fontSize: 10, color: subtext)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _apiKeyCtrl,
                          obscureText: !_apiKeyVisible,
                          style: TextStyle(color: textColor, fontSize: 13, fontFamily: 'monospace'),
                          onChanged: (_) => setState(() => _apiKeySaved = false),
                          decoration: InputDecoration(
                            hintText: 'gsk_xxxxxxxxxxxxxxxxxxxx',
                            hintStyle: TextStyle(color: subtext.withOpacity(0.5), fontFamily: 'monospace', fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _apiKeyVisible = !_apiKeyVisible),
                        child: Icon(_apiKeyVisible ? Icons.visibility_off : Icons.visibility, size: 18, color: subtext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final key = _apiKeyCtrl.text.trim();
                            widget.onApiKeyChange(key);
                            setState(() => _apiKeySaved = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(key.isEmpty ? 'API key cleared' : '✅ API key saved!'),
                                backgroundColor: key.isEmpty ? Colors.orange : const Color(0xFF22C55E),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              gradient: _apiKeySaved
                                  ? const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)])
                                  : LinearGradient(colors: [primary, t['accent'] as Color]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_apiKeySaved ? Icons.check : Icons.save_outlined, size: 14, color: Colors.white),
                                const SizedBox(width: 5),
                                Text(_apiKeySaved ? 'Saved!' : 'Save API Key',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() { _apiKeyCtrl.clear(); _apiKeySaved = false; });
                          widget.onApiKeyChange('');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.clear, size: 14, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 11, color: subtext),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('Free key at console.groq.com • Stored locally on device',
                            style: TextStyle(fontSize: 10, color: subtext)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text('APPEARANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subtext, letterSpacing: 1.5)),
            const SizedBox(height: 12),

            // Theme grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3),
              itemCount: AppThemes.themes.length,
              itemBuilder: (_, i) {
                final th = AppThemes.themes[i];
                final isSelected = _selected == i;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selected = i);
                    widget.onThemeChange(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: th['bg'] as Color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? (th['primary'] as Color) : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected ? [BoxShadow(color: (th['primary'] as Color).withOpacity(0.4), blurRadius: 8)] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: th['primary'] as Color)),
                            const SizedBox(width: 4),
                            Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: th['accent'] as Color)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(th['name'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: th['text'] as Color)),
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.check_circle, size: 12, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // About section
            Text('ABOUT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subtext, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _settingRow(Icons.info_outline, 'Version', '1.0.0', textColor, subtext),
                  Divider(color: subtext.withOpacity(0.1), height: 16),
                  _settingRow(Icons.psychology_outlined, 'AI Model', 'gpt-oss-20b', textColor, primary),
                  Divider(color: subtext.withOpacity(0.1), height: 16),
                  _settingRow(Icons.cloud_outlined, 'Provider', 'Groq API', textColor, subtext),
                  Divider(color: subtext.withOpacity(0.1), height: 16),
                  _settingRow(Icons.palette_outlined, 'Current Theme', t['name'] as String, textColor, primary),
                  Divider(color: subtext.withOpacity(0.1), height: 16),
                  _settingRow(Icons.storage_outlined, 'Chat History', 'Saved locally', textColor, subtext),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Logout
            GestureDetector(
              onTap: widget.onLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Reset & Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingRow(IconData icon, String label, String value, Color text, Color accent) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: text, fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
