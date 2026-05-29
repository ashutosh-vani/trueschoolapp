import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/homework/data/models/homework_item.dart';
import 'package:trueschoolapp/features/homework/data/services/homework_service.dart';
import 'package:trueschoolapp/features/homework/presentation/pages/homework_attempt_page.dart';
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

  void _navigateToAttempt(HomeworkItem homework) {
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
            const SizedBox(height: 16),
            HomeworkFilterChips(
              filters: _filters,
              selectedFilter: _selectedFilter,
              onFilterSelected: (filter) {
                setState(() => _selectedFilter = filter);
              },
            ),
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
          GestureDetector(
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.maybePop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16, color: AppColors.textPrimary),
                  SizedBox(width: 4),
                  Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Your Homework',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
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
