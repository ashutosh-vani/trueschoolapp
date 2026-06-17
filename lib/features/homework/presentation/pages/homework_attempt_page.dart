import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/homework/data/models/homework_question.dart';
import 'package:trueschoolapp/features/homework/data/services/homework_service.dart';
import 'package:trueschoolapp/features/homework/presentation/pages/homework_result_page.dart';

class HomeworkAttemptPage extends StatefulWidget {
  final String homeworkId;
  final String title;

  const HomeworkAttemptPage({
    super.key,
    required this.homeworkId,
    required this.title,
  });

  @override
  State<HomeworkAttemptPage> createState() => _HomeworkAttemptPageState();
}

class _HomeworkAttemptPageState extends State<HomeworkAttemptPage> {
  List<HomeworkQuestion> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _currentIndex = 0;
  final Map<String, String?> _answers = {};
  final Map<String, XFile?> _uploadFiles = {}; // per-question uploaded file
  final Map<String, TextEditingController> _typedControllers = {}; // per-question text controllers
  final Map<String, String> _activeAnswerType = {}; // per-question active type
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    for (final ctrl in _typedControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String questionId) {
    return _typedControllers.putIfAbsent(
      questionId,
      () => TextEditingController(text: _answers[questionId] ?? ''),
    );
  }

  Future<void> _loadQuestions() async {
    final questions = await HomeworkService.getQuestions(widget.homeworkId);
    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoading = false;
        if (questions.isEmpty) {
          _errorMessage = 'No questions found for this homework.';
        }
      });
    }
  }

  String _getActiveType(HomeworkQuestion question) {
    return _activeAnswerType[question.id] ?? question.answerType;
  }

  void _setActiveType(String questionId, String type) {
    setState(() {
      _activeAnswerType[questionId] = type;
    });
  }

  void _selectAnswer(String questionId, String optionId) {
    setState(() {
      _answers[questionId] = optionId;
    });
  }

  void _goToNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _submitAnswers() async {
    setState(() => _isSubmitting = true);

    // First, upload any pending files and collect the remote URLs
    final Map<String, String?> uploadedUrls = {};
    for (final entry in _uploadFiles.entries) {
      if (entry.value != null) {
        final url = await HomeworkService.uploadFile(File(entry.value!.path));
        uploadedUrls[entry.key] = url;
        if (url == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File upload failed. Submitting without attachment.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }

    final answersPayload = _questions.map((q) {
      final activeType = _getActiveType(q);
      String? answer;
      if (activeType == 'upload') {
        // Prefer the remote URL; fall back to local path if upload failed
        answer = uploadedUrls[q.id] ?? _uploadFiles[q.id]?.path;
      } else {
        answer = _answers[q.id];
      }
      return {
        'question_id': q.id,
        'answer': answer,
        'answer_type': activeType,
      };
    }).toList();

    final result = await HomeworkService.submitHomework(
      homeworkId: widget.homeworkId,
      answers: answersPayload,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      // Build a string-keyed answers map for the result page
      final answersMap = <String, String?>{};
      for (final q in _questions) {
        final activeType = _getActiveType(q);
        if (activeType == 'upload') {
          answersMap[q.id] = _uploadFiles[q.id]?.path;
        } else {
          answersMap[q.id] = _answers[q.id];
        }
      }

      // Navigate to full result page (replaces old dialog)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeworkResultPage(
            homeworkId: widget.homeworkId,
            homeworkTitle: widget.title,
            apiResult: result,
            questionSet: _questions,
            answers: answersMap,
          ),
        ),
      );
    }
  }

  void _showSaveExitDialog() {
    final answeredCount = _answers.values.where((v) => v != null).length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save & Exit?'),
        content: Text(
          'You have answered $answeredCount of ${_questions.length} questions. '
          'Your progress will not be saved if you exit now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F6F8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F6F8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment_outlined, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'No questions available.',
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Back to Homework'),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final totalQ = _questions.length;
    final progressPct = ((_currentIndex + 1) / totalQ);
    final isLast = _currentIndex == totalQ - 1;
    final currentAnswer = _answers[question.id];
    final activeType = _getActiveType(question);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressSection(progressPct, totalQ),
                    const SizedBox(height: 20),
                    _buildQuestionCard(question, currentAnswer, activeType),
                    if (question.hint != null) ...[
                      const SizedBox(height: 16),
                      _buildHintCard(question.hint!),
                    ],
                  ],
                ),
              ),
            ),
            _buildFooter(isLast, currentAnswer),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showSaveExitDialog,
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildHeaderPill(
            label: 'Ask\nVin',
            filled: true,
            icon: Icons.smart_toy_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('TrueSchoolAI coming soon!')),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildHeaderPill(
            label: 'Save\n& Exit',
            filled: false,
            icon: null,
            onTap: _showSaveExitDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill({
    required String label,
    required bool filled,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: filled ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : AppColors.textSecondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Progress ──
  Widget _buildProgressSection(double progressPct, int totalQ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROGRESS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary.withValues(alpha: 0.7),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_currentIndex + 1} of $totalQ',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${(progressPct * 100).round()}% Complete',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progressPct,
            minHeight: 10,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 10),
        _buildDotNavigator(totalQ),
      ],
    );
  }

  Widget _buildDotNavigator(int totalQ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(totalQ, (i) {
        final isActive = i == _currentIndex;
        final isAnswered = _answers[_questions[i].id] != null;
        return GestureDetector(
          onTap: () => setState(() => _currentIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 24 : 10,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: isActive
                  ? AppColors.primary
                  : isAnswered
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }

  // ── Question Card with Answer Type Switcher ──
  Widget _buildQuestionCard(HomeworkQuestion question, String? currentAnswer, String activeType) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Answer type switcher tabs
          _buildAnswerTypeSwitcher(question, activeType),
          const SizedBox(height: 24),
          // Question text
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          // Answer input based on active type
          if (activeType == 'mcq')
            _buildMCQOptions(question, currentAnswer),
          if (activeType == 'typed')
            _buildTypedInput(question),
          if (activeType == 'upload')
            _buildUploadInput(question),
        ],
      ),
    );
  }

  Widget _buildAnswerTypeSwitcher(HomeworkQuestion question, String activeType) {
    final types = [
      {'key': 'mcq', 'label': 'Multiple\nChoice'},
      {'key': 'typed', 'label': 'Typed'},
      {'key': 'upload', 'label': 'Upload'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: types.map((t) {
          final isActive = activeType == t['key'];
          return GestureDetector(
            onTap: () => _setActiveType(question.id, t['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                t['label']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  height: 1.2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── MCQ Options ──
  Widget _buildMCQOptions(HomeworkQuestion question, String? selectedId) {
    const optionLabels = ['A', 'B', 'C', 'D', 'E', 'F'];
    return Column(
      children: List.generate(question.options.length, (i) {
        final option = question.options[i];
        final isSelected = selectedId == option.id;
        final label = i < optionLabels.length ? optionLabels[i] : '${i + 1}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _selectAnswer(question.id, option.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade200,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      option.text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Typed Input with Toolbar ──
  Widget _buildTypedInput(HomeworkQuestion question) {
    final controller = _controllerFor(question.id);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _buildToolbarButton('B', FontWeight.bold),
                const SizedBox(width: 12),
                _buildToolbarButton('I', FontWeight.normal, italic: true),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      Text(
                        'Σ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'EQUATION\nEDITOR',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Icon(Icons.undo, size: 20, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          // Text area — uses a persistent controller so the answer is retained
          TextField(
            controller: controller,
            maxLines: 8,
            onChanged: (value) {
              setState(() {
                _answers[question.id] = value.isEmpty ? null : value;
              });
            },
            decoration: InputDecoration(
              hintText: "Let's work through this...\nStart typing your thoughts and Vin will help refine them.",
              hintStyle: TextStyle(color: Colors.grey.shade400, height: 1.5),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(String text, FontWeight weight, {bool italic = false}) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: weight,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ── Upload Input ──
  Future<void> _pickImage(HomeworkQuestion question, ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _uploadFiles[question.id] = picked;
          // Store the file path as the answer so canProceed can check it
          _answers[question.id] = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFile(HomeworkQuestion question) async {
    // Fall back to gallery when no dedicated file picker package is present
    await _pickImage(question, ImageSource.gallery);
  }

  Widget _buildUploadInput(HomeworkQuestion question) {
    final uploadedFile = _uploadFiles[question.id];

    if (uploadedFile != null) {
      // Show picked file preview
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green.shade300, width: 2),
          borderRadius: BorderRadius.circular(14),
          color: Colors.green.shade50,
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(uploadedFile.path),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.insert_drive_file_outlined,
                  size: 64,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    uploadedFile.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _uploadFiles.remove(question.id);
                  _answers.remove(question.id);
                });
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Remove & re-upload', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Camera and gallery icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.add_a_photo_outlined, size: 30, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.collections_outlined, size: 30, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Click to take a photo or upload a scan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Drag & drop your files here or browse from your device gallery',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          // Take Photo button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _pickImage(question, ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined, size: 20),
              label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Browse Files button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickFile(question),
              icon: const Icon(Icons.file_upload_outlined, size: 20),
              label: const Text('Browse Files', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ACCEPTED: JPG, PNG, PDF · MAX 20MB',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hint Card ──
  Widget _buildHintCard(String hint) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFFF9A825), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF795548),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ──
  Widget _buildFooter(bool isLast, String? currentAnswer) {
    final question = _questions[_currentIndex];
    final activeType = _getActiveType(question);
    final isTyped = activeType == 'typed';
    final isUpload = activeType == 'upload';

    // Determine whether the user has provided a valid answer
    bool canProceed;
    if (isTyped) {
      canProceed = (currentAnswer ?? '').trim().length > 4;
    } else if (isUpload) {
      canProceed = _uploadFiles[question.id] != null;
    } else {
      // MCQ
      canProceed = currentAnswer != null;
    }

    final String buttonLabel = isLast
        ? (isTyped || isUpload ? 'Submit All' : 'Submit\nAnswer')
        : (isTyped ? 'Next' : isUpload ? 'Next' : 'Submit\nAnswer');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          GestureDetector(
            onTap: _currentIndex > 0 ? _goToPrevious : null,
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: _currentIndex > 0 ? AppColors.textPrimary : Colors.grey.shade300,
                ),
                const SizedBox(width: 4),
                Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _currentIndex > 0 ? AppColors.textPrimary : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Skip button
          if (!isLast)
            GestureDetector(
              onTap: _goToNext,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFE082)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 16, color: Color(0xFFF9A825)),
                    SizedBox(width: 4),
                    Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF9A825),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!isLast) const SizedBox(width: 12),
          // Next / Submit button
          GestureDetector(
            onTap: (_isSubmitting || !canProceed)
                ? null
                : () {
                    if (isLast) {
                      _submitAnswers();
                    } else {
                      _goToNext();
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: canProceed ? 1.0 : 0.4),
                borderRadius: BorderRadius.circular(28),
                boxShadow: canProceed
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          buttonLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
