import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/config/app_config.dart';
import 'package:trueschoolapp/features/ai_tutor/data/services/vin_ai_service.dart';
import 'package:trueschoolapp/features/ai_tutor/data/utils/vin_xml_parser.dart';
import 'package:trueschoolapp/features/ai_tutor/presentation/widgets/related_media_sheet.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';

// ── Attached image model ──────────────────────────────────────────────────────
class _AttachedImage {
  final String localPath; // shown in preview before upload
  String? uploadedUrl;   // set after successful upload
  bool uploading;

  _AttachedImage({required this.localPath, this.uploadedUrl, this.uploading = false});
}

// ── Avatar URL (same as web frontend) ────────────────────────────────────────
const _kAvatarUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCVoyiJ7XrXHXK5K-2X_581fJt9Yda1obdRKXh8gdfrGJ-NTpwYc8Km130_4l0luSueL9ix-IRGHNCp0uH9upkA5CSl6HyXmL9HX8WiewcPAML8ScVZhykcFVW7tUor-OIEAHbE7ZKxqi5Xj8_k00wG3jpjMmNAte8QGNbJqce__URELabhUvBiKHea4H50BaekRP686vZn0lYjQOmCU4n5h_sdI72gdVsRCO-v1PQud4PcPKAtuj3xCRoTX0UhQmi-8lJ7R8e5SPWr';

// ── Chat message model ────────────────────────────────────────────────────────
enum _Role { user, assistant }

class _ChatMessage {
  final int id;
  final _Role role;
  final String? text;
  String xmlBuffer;
  bool done;

  // MCQ answer state — persisted here so parent setState doesn't reset it
  String? mcqSelectedId;
  bool mcqChecked = false;

  _ChatMessage.user({required this.id, required String this.text})
      : role = _Role.user,
        xmlBuffer = '',
        done = true;

  _ChatMessage.assistant({required this.id})
      : role = _Role.assistant,
        text = null,
        xmlBuffer = '',
        done = false;
}

enum _Status { idle, thinking, streaming }

// ── Main page ─────────────────────────────────────────────────────────────────
class AiTutorPage extends StatefulWidget {
  const AiTutorPage({super.key});

  @override
  State<AiTutorPage> createState() => _AiTutorPageState();
}

class _AiTutorPageState extends State<AiTutorPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();

  final List<_ChatMessage> _messages = [];
  final List<Map<String, String>> _history = [];
  _Status _status = _Status.idle;
  String _userName = 'Alice';

  List<DoubtHistoryItem> _doubtHistory = [];
  bool _historyLoading = false;
  String _historySearch = '';
  String _historySubjectFilter = 'All';
  bool _showHistoryDrawer = false;

  StreamSubscription<String>? _streamSub;

  // The last user question — used for Get Images / Get Videos search
  String _lastTopic = '';

  // Upload state
  final _picker = ImagePicker();

  // ── Speech-to-text ─────────────────────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  // Attached images — list of {file, uploadedUrl}
  // Max 10, matching the web "Add more (x/10)" pattern
  final List<_AttachedImage> _attachedImages = [];
  static const int _maxImages = 10;

  static const _suggestions = [
    'How do I solve quadratic equations?',
    "Explain Newton's Third Law",
    'What is photosynthesis?',
  ];

  static const _subjects = [
    'All', 'Mathematics', 'Physics', 'Chemistry',
    'Biology', 'English', 'History',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadHistory();
    _initSpeech();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _speech.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final name = await TokenStorage.getName();
    if (name != null && name.isNotEmpty && mounted) {
      setState(() => _userName = name.split(' ').first);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    final items = await VinAiService.getHistory();
    if (mounted) {
      setState(() {
        _doubtHistory = items;
        _historyLoading = false;
      });
    }
  }

  // ── Speech-to-text ──────────────────────────────────────────────────────────
  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (error) {
        debugPrint('[STT] error: $error');
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    // Keep whatever the user already typed — append to it
    final existingText = _inputController.text;

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _inputController.text = existingText.isEmpty
                ? result.recognizedWords
                : '$existingText ${result.recognizedWords}';
            // Move cursor to end
            _inputController.selection = TextSelection.fromPosition(
              TextPosition(offset: _inputController.text.length),
            );
          });
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _status != _Status.idle) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage.user(
          id: DateTime.now().millisecondsSinceEpoch, text: trimmed));
      _status = _Status.thinking;
      _lastTopic = trimmed; // track for Get Images / Get Videos
    });
    _scrollToBottom();

    _history.add({'role': 'user', 'content': trimmed});
    if (_history.length > 20) _history.removeAt(0);

    await Future.delayed(const Duration(milliseconds: 300));

    final assistantMsg =
        _ChatMessage.assistant(id: DateTime.now().millisecondsSinceEpoch + 1);
    setState(() {
      _messages.add(assistantMsg);
      _status = _Status.streaming;
    });

    final xmlBuffer = StringBuffer();
    _streamSub = VinAiService.streamChat(
      message: trimmed,
      history: List.from(_history),
    ).listen(
      (token) {
        xmlBuffer.write(token);
        setState(() => assistantMsg.xmlBuffer = xmlBuffer.toString());
        _scrollToBottom();
      },
      onDone: () {
        setState(() {
          assistantMsg.done = true;
          _status = _Status.idle;
        });
        _history.add({'role': 'assistant', 'content': xmlBuffer.toString()});
        if (_history.length > 20) _history.removeAt(0);
        _loadHistory();
        _scrollToBottom();
      },
      onError: (_) {
        setState(() {
          assistantMsg.done = true;
          _status = _Status.idle;
        });
        _scrollToBottom();
      },
    );
  }

  Future<void> _handleAnswer(
      String question, String chosen, bool correct) async {
    if (_status != _Status.idle) return;
    final assistantMsg =
        _ChatMessage.assistant(id: DateTime.now().millisecondsSinceEpoch);
    setState(() {
      _messages.add(assistantMsg);
      _status = _Status.streaming;
    });
    _scrollToBottom();

    final xmlBuffer = StringBuffer();
    _streamSub = VinAiService.streamAnswer(
      question: question,
      chosen: chosen,
      correct: correct,
      history: List.from(_history),
    ).listen(
      (token) {
        xmlBuffer.write(token);
        setState(() => assistantMsg.xmlBuffer = xmlBuffer.toString());
        _scrollToBottom();
      },
      onDone: () {
        setState(() {
          assistantMsg.done = true;
          _status = _Status.idle;
        });
        _history.add({'role': 'assistant', 'content': xmlBuffer.toString()});
        if (_history.length > 20) _history.removeAt(0);
        _scrollToBottom();
      },
      onError: (_) {
        setState(() {
          assistantMsg.done = true;
          _status = _Status.idle;
        });
      },
    );
  }

  // ── Upload Problem ──────────────────────────────────────────────────────────
  void _handleUploadProblem() {
    if (_attachedImages.length >= _maxImages) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      builder: (_) => _UploadChoiceSheet(
        onCamera: () {
          Navigator.pop(context);
          _pickAndAttach(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickAndAttach(ImageSource.gallery);
        },
      ),
    );
  }

  Future<void> _pickAndAttach(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (file == null) return;

    final attached = _AttachedImage(localPath: file.path, uploading: true);
    setState(() => _attachedImages.add(attached));

    try {
      final token = await TokenStorage.getToken();

      // Detect MIME type — backend allowlist: image/jpeg, image/png, image/gif, application/pdf
      // Camera always produces JPEG; gallery detects from extension
      final ext = file.path.split('.').last.toLowerCase();
      final mimeType = switch (ext) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'pdf' => 'application/pdf',
        _ => 'image/jpeg', // covers jpg, jpeg, heic (converted by picker), and camera shots
      };

      // Send exactly as the web does: multipart with file + folder as form fields
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiUrl}/storage/upload'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        // folder as a form field, same as web's formData.append("folder", "vin-problems")
        ..fields['folder'] = 'vin-problems'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType.parse(mimeType),
        ));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();

      debugPrint('[Upload] status=${streamed.statusCode} body=$body');

      if (!mounted) return;
      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        final match = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(body);
        setState(() {
          attached.uploadedUrl = match?.group(1);
          attached.uploading = false;
        });
      } else {
        debugPrint('[Upload] failed: ${streamed.statusCode} — $body');
        setState(() => _attachedImages.remove(attached));
        _showUploadError('${streamed.statusCode}: $body');
      }
    } catch (e) {
      debugPrint('[Upload] exception: $e');
      if (mounted) {
        setState(() => _attachedImages.remove(attached));
        _showUploadError(e.toString());
      }
    }
  }

  void _clearAttachments() => setState(() => _attachedImages.clear());

  void _sendWithImages(String customQuestion) {
    if (_attachedImages.isEmpty) return;

    // Only use images that have finished uploading
    final readyUrls = _attachedImages
        .where((img) => img.uploadedUrl != null)
        .map((img) => img.uploadedUrl!)
        .toList();

    if (readyUrls.isEmpty) {
      // Still uploading — wait
      _showUploadError('Image is still uploading, please wait.');
      return;
    }

    final String msg;
    if (customQuestion.trim().isNotEmpty) {
      // User typed a question: "<question> Image URL: <url>"
      // Matches web format exactly
      msg = readyUrls.length == 1
          ? "${customQuestion.trim()} Image URL: ${readyUrls.first}"
          : "${customQuestion.trim()} Image URLs: ${readyUrls.join(', ')}";
    } else {
      // "Solve this problem for me" — exact same string the web sends
      msg = readyUrls.length == 1
          ? "I've uploaded a problem image. Please help me solve it. Image URL: ${readyUrls.first}"
          : "I've uploaded a problem image. Please help me solve it. Image URLs: ${readyUrls.join(', ')}";
    }

    _clearAttachments();
    _inputController.clear();
    _sendMessage(msg);
  }

  void _showUploadError([String? detail]) {
    final msg = detail != null && detail.length < 80
        ? 'Upload failed: $detail'
        : 'Upload failed. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Contextual search actions ───────────────────────────────────────────────
  void _handleGetImages() {
    showRelatedMediaSheet(
      context,
      topic: _lastTopic.isNotEmpty ? _lastTopic : 'study',
      startOnVideos: false,
    );
  }

  void _handleGetVideos() {
    showRelatedMediaSheet(
      context,
      topic: _lastTopic.isNotEmpty ? _lastTopic : 'study',
      startOnVideos: true,
    );
  }

  void _handleFormulaHelp() {
    _inputController.text =
        'Can you show me the key formulas I need to know for this topic?';
    _inputFocus.requestFocus();
  }

  void _handlePastLessons() => setState(() => _showHistoryDrawer = true);

  Future<void> _toggleStar(String id) async {
    setState(() {
      final idx = _doubtHistory.indexWhere((h) => h.id == id);
      if (idx != -1) _doubtHistory[idx].starred = !_doubtHistory[idx].starred;
    });
    await VinAiService.toggleStar(id);
  }

  List<DoubtHistoryItem> get _filteredHistory => _doubtHistory.where((h) {
        final matchSubj = _historySubjectFilter == 'All' ||
            h.subject == _historySubjectFilter;
        final matchSearch = _historySearch.isEmpty ||
            h.question
                .toLowerCase()
                .contains(_historySearch.toLowerCase());
        return matchSubj && matchSearch;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar with gradient accent and menu icon
                _buildTopBar(),
                Expanded(child: _buildBody()),
                _buildFooter(),
              ],
            ),
            if (_showHistoryDrawer) _buildHistoryDrawer(),
          ],
        ),
      ),
    );
  }

  // ── Top bar with gradient accent and history menu icon ────────────────────
  Widget _buildTopBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Thin gradient accent line
        Container(
          height: 4,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9B59B6), Color(0xFF667EEA)],
            ),
          ),
        ),
        // Header row with title and menu icon
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Lumi avatar (small)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ClipOval(
                  child: Image.network(
                    _kAvatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF2D2D3A),
                      child: const Icon(Icons.person,
                          color: Colors.white70, size: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'LumiTutor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              // History menu icon button
              GestureDetector(
                onTap: () => setState(() => _showHistoryDrawer = true),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom border for header
        Container(
          height: 1,
          color: const Color(0xFFF0F0F5),
        ),
      ],
    );
  }

  // ── Body: empty state or chat ─────────────────────────────────────────────
  Widget _buildBody() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      itemCount:
          _messages.length + (_status == _Status.thinking ? 1 : 0),
      itemBuilder: (context, index) {
        if (_status == _Status.thinking && index == _messages.length) {
          return _buildTypingDots();
        }
        final msg = _messages[index];
        return msg.role == _Role.user
            ? _buildUserBubble(msg)
            : _buildAssistantBubble(msg);
      },
    );
  }

  // ── Empty / welcome state ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Avatar — circular photo
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                _kAvatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF2D2D3A),
                  child: const Icon(Icons.person, size: 44, color: Colors.white70),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Greeting — bold, large
          Text(
            "Hi $_userName, I'm LumiTutor!",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your AI tutor — ask me anything about your subjects.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 32),
          // Suggestion chips — left-aligned pill style
          ..._suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => _sendMessage(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A2E),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Chat bubbles ──────────────────────────────────────────────────────────
  Widget _buildUserBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('You',
                    style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Text(msg.text!,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.4)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppColors.primary),
            child: const Icon(Icons.person, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ClipOval(
              child: Image.network(
                _kAvatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF2D2D3A),
                  child: const Icon(Icons.person,
                      color: Colors.white70, size: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lumi',
                    style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: const Border(
                        left: BorderSide(
                            color: Color(0xFFD4C5F9), width: 3)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: _StreamingMessageWidget(
                    xmlBuffer: msg.xmlBuffer,
                    done: msg.done,
                    onFollowup: _sendMessage,
                    onAnswerQuestion: _handleAnswer,
                    mcqSelectedId: msg.mcqSelectedId,
                    mcqChecked: msg.mcqChecked,
                    onMcqStateChanged: (selectedId, checked) {
                      setState(() {
                        msg.mcqSelectedId = selectedId;
                        msg.mcqChecked = checked;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDots() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ClipOval(
              child: Image.network(_kAvatarUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF2D2D3A),
                      child: const Icon(Icons.person,
                          color: Colors.white70, size: 16))),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: const Border(
                  left: BorderSide(color: Color(0xFFD4C5F9), width: 3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:
                  List.generate(3, (i) => _BouncingDot(delay: i * 150)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    final hasMessages = _messages.isNotEmpty;
    final hasAttachments = _attachedImages.isNotEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Attachment panel (shown when images are selected) ─────────────
          if (hasAttachments) ...[
            _buildAttachmentPanel(),
            const SizedBox(height: 10),
          ],
          // ── Quick action chips ────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasAttachments)
                // "Add more (x/10)" chip when attachments exist
                _buildActionChip(
                  Icons.upload_file_outlined,
                  'Add more (${_attachedImages.length}/$_maxImages)',
                  color: AppColors.primary,
                  onTap: _attachedImages.length < _maxImages
                      ? _handleUploadProblem
                      : () {},
                )
              else
                _buildActionChip(
                  Icons.upload_file_outlined,
                  'Upload Problem',
                  color: AppColors.primary,
                  onTap: _handleUploadProblem,
                ),
              _buildActionChip(
                Icons.functions,
                'Formula Help',
                color: AppColors.primary,
                onTap: _handleFormulaHelp,
              ),
              if (hasMessages && !hasAttachments) ...[
                _buildActionChip(
                  Icons.image_search_outlined,
                  'Get Images',
                  color: const Color(0xFF059669),
                  onTap: _handleGetImages,
                ),
                _buildActionChip(
                  Icons.play_circle_outline,
                  'Get Videos',
                  color: const Color(0xFFDC2626),
                  onTap: _handleGetVideos,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // ── Input bar ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5FA),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    focusNode: _inputFocus,
                    decoration: InputDecoration(
                      hintText: hasAttachments
                          ? 'Ask about this image, or leave blank to solve it...'
                          : 'Ask your doubt or paste an image...',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                        fontFamily: 'Poppins',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: hasAttachments
                        ? _sendWithImages
                        : _sendMessage,
                  ),
                ),
                // ── Mic button ─────────────────────────────────────────
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_outlined,
                      color: _isListening
                          ? const Color(0xFFDC2626)
                          : (_speechAvailable
                              ? const Color(0xFF6B7280)
                              : const Color(0xFFD1D5DB)),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // ── Send button ────────────────────────────────────────
                GestureDetector(
                  onTap: _status == _Status.idle
                      ? () {
                          if (_isListening) _speech.stop();
                          if (hasAttachments) {
                            _sendWithImages(_inputController.text);
                          } else {
                            _sendMessage(_inputController.text);
                          }
                        }
                      : null,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _status == _Status.idle
                          ? AppColors.primary.withValues(alpha: 0.7)
                          : AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'LumiTutor can make mistakes. Verify important information.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Attachment panel ──────────────────────────────────────────────────────
  Widget _buildAttachmentPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // light green tint
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.attach_file,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                '${_attachedImages.length} IMAGE${_attachedImages.length > 1 ? 'S' : ''} ATTACHED',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearAttachments,
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Thumbnail row
          SizedBox(
            height: 76,
            child: Row(
              children: [
                // Existing thumbnails
                ..._attachedImages.map((img) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildThumbnail(img),
                    )),
                // "Add more" dashed placeholder
                if (_attachedImages.length < _maxImages)
                  GestureDetector(
                    onTap: _handleUploadProblem,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 1.5,
                          // Dashed border simulation via custom painter
                        ),
                        color: AppColors.primary.withValues(alpha: 0.04),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Hint text
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 13, color: Color(0xFF6B7280)),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Type your question below, or use the shortcut:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // "Solve this problem for me" button
          GestureDetector(
            onTap: () => _sendWithImages(''),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome,
                      color: AppColors.primary, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Solve this problem for me',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(_AttachedImage img) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(img.localPath),
            width: 76,
            height: 76,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 76,
              height: 76,
              color: const Color(0xFFF5F5FA),
              child: const Icon(Icons.broken_image_outlined,
                  color: Color(0xFFD1D5DB)),
            ),
          ),
        ),
        // Upload spinner overlay
        if (img.uploading)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        // Remove button
        if (!img.uploading)
          Positioned(
            top: 3,
            right: 3,
            child: GestureDetector(
              onTap: () => setState(() => _attachedImages.remove(img)),
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 11),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionChip(
    IconData icon,
    String label, {
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── History drawer ────────────────────────────────────────────────────────
  Widget _buildHistoryDrawer() {
    return GestureDetector(
      onTap: () => setState(() => _showHistoryDrawer = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 12, 16),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFE5E7EB))),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Doubt History',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                    fontFamily: 'Poppins')),
                          ),
                          IconButton(
                            onPressed: () => setState(
                                () => _showHistoryDrawer = false),
                            icon: const Icon(Icons.close,
                                color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        onChanged: (v) =>
                            setState(() => _historySearch = v),
                        decoration: InputDecoration(
                          hintText: 'Search your doubts...',
                          hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                              fontFamily: 'Poppins'),
                          prefixIcon: const Icon(Icons.search,
                              size: 18, color: Color(0xFF6B7280)),
                          filled: true,
                          fillColor: const Color(0xFFF5F5FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        itemCount: _subjects.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final s = _subjects[i];
                          final active =
                              _historySubjectFilter == s;
                          return GestureDetector(
                            onTap: () => setState(
                                () => _historySubjectFilter = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary
                                    : const Color(0xFFF5F5FA),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(s,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? Colors.white
                                        : const Color(0xFF6B7280),
                                    fontFamily: 'Poppins',
                                  )),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _historyLoading
                          ? const Center(
                              child: CircularProgressIndicator())
                          : _filteredHistory.isEmpty
                              ? const Center(
                                  child: Text('No doubts found',
                                      style: TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 13,
                                          fontFamily: 'Poppins')))
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  itemCount:
                                      _filteredHistory.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) =>
                                      _HistoryCard(
                                    item: _filteredHistory[i],
                                    onStar: _toggleStar,
                                    onTap: (q) {
                                      setState(() =>
                                          _showHistoryDrawer =
                                              false);
                                      _sendMessage(q);
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Streaming message renderer ────────────────────────────────────────────────
class _StreamingMessageWidget extends StatelessWidget {
  final String xmlBuffer;
  final bool done;
  final void Function(String) onFollowup;
  final void Function(String, String, bool) onAnswerQuestion;
  // MCQ state lifted to parent so it survives rebuilds
  final String? mcqSelectedId;
  final bool mcqChecked;
  final void Function(String? selectedId, bool checked) onMcqStateChanged;

  const _StreamingMessageWidget({
    required this.xmlBuffer,
    required this.done,
    required this.onFollowup,
    required this.onAnswerQuestion,
    required this.mcqSelectedId,
    required this.mcqChecked,
    required this.onMcqStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = VinXmlParser.parse(xmlBuffer);

    if (!parsed.hasContent && !done) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => _BouncingDot(delay: i * 150)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parsed.subject != null) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(parsed.subject!,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontFamily: 'Poppins')),
          ),
          const SizedBox(height: 10),
        ],
        if (parsed.hasContent)
          RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                  height: 1.5,
                  fontFamily: 'Poppins'),
              children: [
                TextSpan(text: VinXmlParser.stripHtml(parsed.content)),
                if (!done)
                  const WidgetSpan(
                    child: _BlinkingCursor(),
                    alignment: PlaceholderAlignment.middle,
                  ),
              ],
            ),
          ),
        if (parsed.hint != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5E5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Color(0xFFDC2626), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HINT',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFDC2626),
                              letterSpacing: 0.8,
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 4),
                      Text(VinXmlParser.stripHtml(parsed.hint!),
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7F1D1D),
                              height: 1.4,
                              fontFamily: 'Poppins')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (parsed.steps.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFC8E6C9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.checklist,
                        color: Color(0xFF2E7D32), size: 16),
                    SizedBox(width: 6),
                    Text('STEP-BY-STEP',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E7D32),
                            letterSpacing: 0.8,
                            fontFamily: 'Poppins')),
                  ],
                ),
                const SizedBox(height: 10),
                ...parsed.steps.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white),
                            child: Center(
                              child: Text('${step.number}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                      fontFamily: 'Poppins')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                                VinXmlParser.stripHtml(step.text),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1B5E20),
                                    height: 1.4,
                                    fontFamily: 'Poppins')),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
        if (parsed.question != null) ...[
          const SizedBox(height: 12),
          _PracticeQuestion(
            question: parsed.question!,
            onAnswer: onAnswerQuestion,
            selectedId: mcqSelectedId,
            checked: mcqChecked,
            onStateChanged: onMcqStateChanged,
          ),
        ],
        if (done && parsed.followups.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: parsed.followups
                .map((f) => GestureDetector(
                      onTap: () => onFollowup(f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(f,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins')),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ── Practice question — StatelessWidget, state lifted to _ChatMessage ─────────
class _PracticeQuestion extends StatelessWidget {
  final VinQuestion question;
  final void Function(String, String, bool) onAnswer;
  // Lifted state — owned by _ChatMessage, survives parent setState
  final String? selectedId;
  final bool checked;
  final void Function(String? selectedId, bool checked) onStateChanged;

  const _PracticeQuestion({
    required this.question,
    required this.onAnswer,
    required this.selectedId,
    required this.checked,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final correct = question.options.firstWhere(
      (o) => o.correct,
      orElse: () => question.options.first,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRACTICE QUESTION',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          Text(question.text,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1A1A2E),
                  height: 1.4,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 12),
          ...question.options.map((opt) {
            final isSel = selectedId == opt.id;
            final isGood = checked && opt.correct;
            final isBad = checked && isSel && !opt.correct;
            Color borderColor = const Color(0xFFE5E7EB);
            Color bgColor = Colors.white;
            if (isGood) {
              borderColor = const Color(0xFF16A34A);
              bgColor = const Color(0xFFF0FDF4);
            } else if (isBad) {
              borderColor = const Color(0xFFDC2626);
              bgColor = const Color(0xFFFEF2F2);
            } else if (isSel) {
              borderColor = AppColors.primary;
              bgColor = AppColors.primary.withValues(alpha: 0.05);
            }
            return GestureDetector(
              onTap: checked
                  ? null
                  : () => onStateChanged(opt.id, false),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSel
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSel
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('${opt.id}. ${opt.text}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A2E),
                              fontFamily: 'Poppins')),
                    ),
                    if (checked && opt.correct)
                      const Icon(Icons.check_circle,
                          color: Color(0xFF16A34A), size: 18),
                    if (checked && isBad)
                      const Icon(Icons.cancel,
                          color: Color(0xFFDC2626), size: 18),
                  ],
                ),
              ),
            );
          }),
          if (!checked) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedId == null
                    ? null
                    : () {
                        // Persist checked=true into the message model
                        onStateChanged(selectedId, true);
                        final chosen = question.options
                            .firstWhere((o) => o.id == selectedId);
                        onAnswer(question.text, chosen.text, chosen.correct);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: Size.zero,
                ),
                child: const Text('Check Answer',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Poppins')),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selectedId == correct.id
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedId == correct.id
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedId == correct.id
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: selectedId == correct.id
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedId == correct.id
                          ? 'Correct! Well done.'
                          : 'Not quite. The correct answer is ${correct.id}.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selectedId == correct.id
                            ? const Color(0xFF166534)
                            : const Color(0xFF991B1B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── History card ──────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final DoubtHistoryItem item;
  final void Function(String) onStar;
  final void Function(String) onTap;

  const _HistoryCard(
      {required this.item, required this.onStar, required this.onTap});

  static Color _subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return const Color(0xFF695BE6);
      case 'physics':
        return const Color(0xFF3B82F6);
      case 'chemistry':
        return const Color(0xFFF97316);
      case 'biology':
        return const Color(0xFF10B981);
      case 'english':
        return const Color(0xFF14B8A6);
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor(item.subject);
    return GestureDetector(
      onTap: () => onTap(item.question),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(item.subject,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: color,
                          fontFamily: 'Poppins')),
                ),
                const Spacer(),
                Text(_formatDate(item.createdAt),
                    style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF9CA3AF),
                        fontFamily: 'Poppins')),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.question,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                    fontFamily: 'Poppins')),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(item.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Poppins')),
                ),
                GestureDetector(
                  onTap: () => onStar(item.id),
                  child: Icon(
                    item.starred ? Icons.star : Icons.star_border,
                    color: item.starred
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF9CA3AF),
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upload choice bottom sheet ────────────────────────────────────────────────
class _UploadChoiceSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _UploadChoiceSheet({
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Choose an action',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 32),
            // Options spaced evenly across full width
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _UploadOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: onCamera,
                ),
                _UploadOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Photos and\nvideos',
                  onTap: onGallery,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated helpers ──────────────────────────────────────────────────────────
class _BouncingDot extends StatefulWidget {
  final int delay;
  const _BouncingDot({required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 16,
        margin: const EdgeInsets.only(left: 2),
        color: AppColors.primary,
      ),
    );
  }
}
