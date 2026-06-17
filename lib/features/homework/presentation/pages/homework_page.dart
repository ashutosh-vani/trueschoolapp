import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/homework/data/models/homework_item.dart';
import 'package:trueschoolapp/features/homework/data/services/homework_service.dart';
import 'package:trueschoolapp/features/homework/presentation/pages/homework_attempt_page.dart';
import 'package:trueschoolapp/features/homework/presentation/pages/homework_result_page.dart';
import 'package:trueschoolapp/features/homework/presentation/widgets/homework_card.dart';
import 'package:trueschoolapp/features/homework/presentation/widgets/homework_filter_chips.dart';
import 'package:trueschoolapp/shared/widgets/skeleton.dart';

class HomeworkPage extends StatefulWidget {
  /// Called when the "Home" back button is tapped.
  /// If null, falls back to [Navigator.maybePop].
  final VoidCallback? onBack;

  const HomeworkPage({super.key, this.onBack});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  String _selectedFilter = 'All';
  String? _selectedSubject;
  String _sortBy = 'Latest';
  List<HomeworkItem> _allHomework = [];
  bool _isLoading = true;

  final List<String> _filters = [
    'All',
    'Pending',
    'Overdue',
    'In Progress',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _fetchHomework();
  }

  Future<void> _fetchHomework() async {
    final homework = await HomeworkService.getStudentHomework();
    if (mounted) {
      setState(() {
        _allHomework = homework;
        _isLoading = false;
      });
    }
  }

  List<HomeworkItem> get _filteredHomework {
    List<HomeworkItem> filtered;
    if (_selectedFilter == 'All') {
      filtered = List.from(_allHomework);
    } else {
      final filterKey = _selectedFilter.toLowerCase().replaceAll(' ', '_');
      filtered = _allHomework.where((hw) => hw.status == filterKey).toList();
    }

    // Subject filter
    if (_selectedSubject != null) {
      filtered = filtered.where((hw) => hw.subject == _selectedSubject).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'Due Date':
        filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case 'Subject':
        filtered.sort((a, b) => a.subject.compareTo(b.subject));
        break;
      case 'Difficulty':
        const order = {'low': 0, 'medium': 1, 'high': 2};
        filtered.sort((a, b) =>
            (order[a.difficultyLevel] ?? 1).compareTo(order[b.difficultyLevel] ?? 1));
        break;
      default: // Latest
        filtered.sort((a, b) => b.assignedDate.compareTo(a.assignedDate));
    }

    return filtered;
  }

  Map<String, int> get _statusCounts => {
    'pending':     _allHomework.where((h) => h.status == 'pending').length,
    'overdue':     _allHomework.where((h) => h.status == 'overdue').length,
    'in_progress': _allHomework.where((h) => h.status == 'in_progress').length,
    'completed':   _allHomework.where((h) => h.status == 'completed').length,
  };

  List<String> get _subjects => _allHomework.map((h) => h.subject).toSet().where((s) => s.isNotEmpty).toList();

  void _navigateToAttempt(HomeworkItem homework) {
    if (homework.status == 'completed') {
      // Completed homework → show result page with grade info
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HomeworkResultPage(
            homeworkId: homework.id,
            homeworkTitle: homework.title,
            apiResult: homework.grade != null
                ? {'final_grade': homework.grade, 'teacher_feedback': homework.teacherFeedback}
                : null,
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeworkAttemptPage(
          homeworkId: homework.id,
          title: homework.title,
        ),
      ),
    ).then((_) => _fetchHomework()); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildSortButton(),
            const SizedBox(height: 14),
            // Status count cards row
            if (_isLoading)
              _buildStatusCardsSkeleton()
            else
              _buildStatusCountCards(),
            const SizedBox(height: 12),
            HomeworkFilterChips(
              filters: _filters,
              selectedFilter: _selectedFilter,
              onFilterSelected: (filter) {
                setState(() => _selectedFilter = filter);
              },
            ),
            // Subject filter
            if (!_isLoading && _subjects.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildSubjectFilter(),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 4,
                      itemBuilder: (_, __) => const HomeworkCardSkeleton(),
                    )
                  : _buildHomeworkList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildAiFab(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Your Homework',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Result count badge
          if (!_isLoading && (_selectedFilter != 'All' || _selectedSubject != null))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_filteredHomework.length} result${_filteredHomework.length != 1 ? "s" : ""}',
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _showSortOptions,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sort: $_sortBy',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Color(0xFF2E7D32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption('Latest'),
              _buildSortOption('Due Date'),
              _buildSortOption('Subject'),
              _buildSortOption('Difficulty'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String option) {
    final isSelected = _sortBy == option;
    return ListTile(
      title: Text(
        option,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() => _sortBy = option);
        Navigator.pop(context);
      },
    );
  }

  // ── Status count cards (mirrors web sidebar) ─────────────────────
  Widget _buildStatusCountCards() {
    final counts = _statusCounts;
    final cards = [
      {'key': 'pending',     'label': 'Pending',     'count': counts['pending']!,     'bg': const Color(0xFFFFE5E5),  'textColor': const Color(0xFFB91C1C),  'icon': Icons.assignment_late_outlined},
      {'key': 'overdue',     'label': 'Overdue',     'count': counts['overdue']!,     'bg': const Color(0xFFFFB3BA),  'textColor': const Color(0xFF9A3412),  'icon': Icons.history_outlined},
      {'key': 'in_progress', 'label': 'In Progress', 'count': counts['in_progress']!, 'bg': const Color(0xFFD4C5F9),  'textColor': const Color(0xFF3730A3),  'icon': Icons.pending_actions_outlined},
      {'key': 'completed',   'label': 'Done',        'count': counts['completed']!,   'bg': const Color(0xFFC8E6C9),  'textColor': const Color(0xFF166534),  'icon': Icons.check_circle_outline},
    ];

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final card = cards[i];
          final key = card['key'] as String;
          final isActive = _selectedFilter.toLowerCase().replaceAll(' ', '_') == key;
          return GestureDetector(
            onTap: () => setState(() {
              final label = {'pending': 'Pending', 'overdue': 'Overdue', 'in_progress': 'In Progress', 'completed': 'Completed'}[key]!;
              _selectedFilter = isActive ? 'All' : label;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: card['bg'] as Color,
                borderRadius: BorderRadius.circular(14),
                border: isActive ? Border.all(color: AppColors.primary, width: 2) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(17)),
                    child: Icon(card['icon'] as IconData, size: 18, color: card['textColor'] as Color),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card['label'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: card['textColor'] as Color)),
                      Text('${card['count']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCardsSkeleton() {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: 110, height: 76,
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ── Subject filter chips ──────────────────────────────────────────
  Widget _buildSubjectFilter() {
    final subjects = _subjects;
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subjects.length + 1, // +1 for "All Subjects"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final subject = i == 0 ? null : subjects[i - 1];
          final label = subject ?? 'All Subjects';
          final isSelected = _selectedSubject == subject;
          return GestureDetector(
            onTap: () => setState(() => _selectedSubject = isSelected ? null : subject),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1),
              ),
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeworkList() {
    final homework = _filteredHomework;

    if (homework.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _selectedFilter == 'All'
                  ? 'No homework assigned yet'
                  : 'No $_selectedFilter homework',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHomework,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: homework.length,
        itemBuilder: (context, index) {
          final hw = homework[index];
          return GestureDetector(
            onTap: () => _navigateToAttempt(hw),
            child: HomeworkCard(
              subject: hw.subject.toUpperCase(),
              status: hw.status.replaceAll('_', ' ').toUpperCase(),
              title: hw.title,
              assignedBy: 'Assigned by ${hw.assignedBy}',
              dueDate: _formatDueDate(hw.dueDate),
              difficulty: _capitalize(hw.difficultyLevel),
              estimatedTime: 'Est. Remaining: ${hw.estimatedDurationMinutes} mins',
              progress: hw.progressPercent / 100.0,
              grade: hw.grade,
              teacherFeedback: hw.teacherFeedback,
              onTap: () => _navigateToAttempt(hw),
            ),
          );
        },
      ),
    );
  }

  String _formatDueDate(String dateStr) {
    if (dateStr.isEmpty) return 'No due date';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return 'Due ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return 'Due $dateStr';
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _buildAiFab() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}
