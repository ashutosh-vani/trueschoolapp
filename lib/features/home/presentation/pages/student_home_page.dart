import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/ai_tutor/presentation/pages/ai_tutor_page.dart';
import 'package:trueschoolapp/features/career/presentation/pages/career_explorer_page.dart';
import 'package:trueschoolapp/features/exam_prep/presentation/pages/exam_prep_list_page.dart';
import 'package:trueschoolapp/features/learning_gaps/presentation/pages/learning_gap_hub_page.dart';
import 'package:trueschoolapp/features/home/data/models/recent_activity_item.dart';
import 'package:trueschoolapp/features/home/data/models/task_item.dart';
import 'package:trueschoolapp/features/home/data/services/task_service.dart';
import 'package:trueschoolapp/features/home/presentation/widgets/greeting_card.dart';
import 'package:trueschoolapp/features/home/presentation/widgets/quick_action_card.dart';
import 'package:trueschoolapp/features/homework/data/models/homework_item.dart';
import 'package:trueschoolapp/features/homework/data/services/homework_service.dart';
import 'package:trueschoolapp/features/homework/presentation/pages/homework_attempt_page.dart';
import 'package:trueschoolapp/features/homework/presentation/pages/homework_page.dart';
import 'package:trueschoolapp/app/routes/app_router.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';
import 'package:trueschoolapp/features/profile/presentation/pages/profile_page.dart';
import 'package:trueschoolapp/features/notifications/data/services/notification_service.dart';
import 'package:trueschoolapp/features/notifications/presentation/pages/notifications_page.dart';
import 'package:trueschoolapp/features/progress/presentation/pages/progress_page.dart';
import 'package:trueschoolapp/shared/widgets/skeleton.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _currentIndex = 0;
  List<RecentActivityItem> _recentActivities = [];
  bool _isLoadingActivities = true;
  List<HomeworkItem> _dueHomework = [];
  String _userInitial = '';
  int _unreadNotifCount = 0;

  // ── Task state ─────────────────────────────────────────────────────────────
  List<TaskItem> _tasks = [];
  bool _isLoadingTasks = true;
  bool _isAddingTask = false;
  final TextEditingController _taskController = TextEditingController();
  final FocusNode _taskFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadUserInitial();
    _loadHomeworkData();
    _loadTasks();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _taskController.dispose();
    _taskFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserInitial() async {
    final name = await TokenStorage.getName();
    if (mounted && name != null && name.isNotEmpty) {
      setState(() => _userInitial = name.trim()[0].toUpperCase());
    }
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() => _unreadNotifCount = count);
    }
  }

  /// Single API call that populates both Recent Activity and Today's Focus.
  Future<void> _loadHomeworkData() async {
    if (mounted) {
      setState(() => _isLoadingActivities = true);
    }

    final homework = await HomeworkService.getStudentHomework();

    if (!mounted) return;

    // ── Today's Focus: pending / in_progress / overdue (up to 3) ──────────
    final due = homework
        .where((hw) =>
            hw.status == 'pending' ||
            hw.status == 'in_progress' ||
            hw.status == 'overdue')
        .take(3)
        .toList();

    // ── Recent Activity: derive from homework list ─────────────────────────
    final allActivities = homework
        .map((hw) => RecentActivityItem.fromHomework({
              'id': hw.id,
              'title': hw.title,
              'subject': hw.subject,
              'status': hw.status,
              'assignedDate': hw.assignedDate,
              'dueDate': hw.dueDate,
            }))
        .where((a) => a.title.isNotEmpty)
        .toList();

    allActivities.sort((a, b) {
      final aActive = a.status != 'completed';
      final bActive = b.status != 'completed';
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;
      if (a.timestamp != null && b.timestamp != null) {
        return a.timestamp!.compareTo(b.timestamp!);
      }
      if (a.timestamp != null) return -1;
      if (b.timestamp != null) return 1;
      return 0;
    });

    setState(() {
      _dueHomework = due;
      _recentActivities = allActivities.take(5).toList();
      _isLoadingActivities = false;
    });
  }

  Future<void> _loadTasks() async {
    final tasks = await TaskService.getTasks();
    if (mounted) {
      setState(() {
        _tasks = List<TaskItem>.from(tasks);
        _isLoadingTasks = false;
      });
    }
  }

  Future<void> _toggleTask(TaskItem task) async {
    // Optimistic update — new list copy so Flutter detects the change
    setState(() {
      _tasks = _tasks
          .map((t) => t.id == task.id ? t.copyWith(done: !t.done) : t)
          .toList();
    });

    final newDone = await TaskService.toggleTask(task.id);
    if (!mounted) return;

    if (newDone != null) {
      setState(() {
        _tasks = _tasks
            .map((t) => t.id == task.id ? t.copyWith(done: newDone) : t)
            .toList();
      });
    } else {
      // Revert on failure
      setState(() {
        _tasks = _tasks
            .map((t) => t.id == task.id ? task : t)
            .toList();
      });
    }
  }

  Future<void> _submitNewTask() async {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;

    // Close the input immediately with optimistic item visible
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = TaskItem(
      id: tempId,
      title: title,
      subject: 'Custom',
      done: false,
      isOptimistic: true,
    );

    setState(() {
      _tasks = [..._tasks, optimistic]; // new list — guarantees rebuild
      _taskController.clear();
      _isAddingTask = false;
    });

    // Call backend, then always reload from server to get the real ID
    await TaskService.addTask(title);
    final fresh = await TaskService.getTasks();
    if (mounted) {
      setState(() {
        _tasks = fresh;
        _isLoadingTasks = false;
      });
    }
  }

  /// Called after returning from homework attempt to refresh both sections.
  Future<void> _refreshAfterAttempt() => _loadHomeworkData();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevent back navigation to auth screens
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _currentIndex == 0 ? _buildHomeContent() : _buildPlaceholder(),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final labels = ['Home', 'Homework', 'AI', 'Progress', 'Profile'];
    if (_currentIndex == 1) {
      return HomeworkPage(
        onBack: () => setState(() => _currentIndex = 0),
      );
    }
    if (_currentIndex == 2) {
      return const AiTutorPage();
    }
    if (_currentIndex == 3) {
      return ProgressPage(
        onBack: () => setState(() => _currentIndex = 0),
      );
    }
    if (_currentIndex == 4) {
      return ProfilePage(
        onBack: () => setState(() => _currentIndex = 0),
      );
    }
    return Center(
      child: Text(
        '${labels[_currentIndex]} - Coming Soon',
        style: const TextStyle(
          fontSize: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppBar(),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: GreetingCard(),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 16),
          _buildExtraActions(),
          const SizedBox(height: 32),
          _buildRecentActivity(),
          const SizedBox(height: 32),
          _buildTodaysFocus(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.school,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'TrueSchool Student',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsPage(),
                ),
              ).then((_) => _loadUnreadCount());
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                ),
                if (_unreadNotifCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _unreadNotifCount > 99
                              ? '99+'
                              : '$_unreadNotifCount',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await TokenStorage.clear();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.roleSelection,
                    (_) => false,
                  );
                }
              }
            },
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            color: Colors.white,
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFE53935),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Center(
                child: Text(
                  _userInitial.isNotEmpty ? _userInitial : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.4,
        children: [
          QuickActionCard(
            title: 'Homework',
            badge: '0 PENDING',
            icon: Icons.menu_book_outlined,
            gradient: AppColors.homeworkGradient,
            onTap: () => setState(() => _currentIndex = 1),
          ),
          QuickActionCard(
            title: 'LumiTutor',
            badge: '24/7 AVAILABLE',
            icon: Icons.auto_awesome,
            gradient: AppColors.tutorGradient,
            onTap: () => setState(() => _currentIndex = 2),
          ),
          QuickActionCard(
            title: 'Learning Gaps',
            badge: 'ACTIVE GAPS',
            icon: Icons.warning_amber_rounded,
            gradient: AppColors.learningGapsGradient,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LearningGapHubPage()),
            ),
          ),
          QuickActionCard(
            title: 'My Portfolio',
            badge: 'SHOWCASE',
            icon: Icons.account_circle_outlined,
            gradient: AppColors.portfolioGradient,
            onTap: () => setState(() => _currentIndex = 4),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.4,
        children: [
          QuickActionCard(
            title: 'Exam Prep',
            badge: '0 TASKS',
            icon: Icons.description_outlined,
            gradient: AppColors.examPrepGradient,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExamPrepListPage(),
                ),
              );
            },
          ),
          QuickActionCard(
            title: 'Career',
            badge: 'DISCOVER',
            icon: Icons.rocket_launch_outlined,
            gradient: AppColors.careerGradient,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CareerExplorerPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                },
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingActivities)
            Column(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: EdgeInsets.only(bottom: i < 2 ? 12 : 0),
                  child: const ActivityItemSkeleton(),
                ),
              ),
            )
          else if (_recentActivities.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'No recent activity yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...List.generate(_recentActivities.length, (index) {
              final activity = _recentActivities[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _recentActivities.length - 1 ? 12 : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    if (activity.id.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeworkAttemptPage(
                            homeworkId: activity.id,
                            title: activity.title,
                          ),
                        ),
                      ).then((_) => _refreshAfterAttempt());
                    }
                  },
                  child: _buildActivityItem(
                    icon: activity.icon,
                    title: activity.title,
                    subtitle: activity.subtitle,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysFocus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Focus",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HOMEWORK DUE section ──────────────────────────────────
                const Text(
                  'HOMEWORK DUE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoadingActivities)
                  Column(
                    children: List.generate(
                      2,
                      (i) => Padding(
                        padding: EdgeInsets.only(bottom: i < 1 ? 10 : 0),
                        child: const FocusTaskSkeleton(),
                      ),
                    ),
                  )
                else if (_dueHomework.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'No homework due. You\'re all caught up!',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...List.generate(_dueHomework.length, (index) {
                    final hw = _dueHomework[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < _dueHomework.length - 1 ? 10 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomeworkAttemptPage(
                                homeworkId: hw.id,
                                title: hw.title,
                              ),
                            ),
                          ).then((_) => _refreshAfterAttempt());
                        },
                        child: _buildFocusTask(
                          title: hw.title,
                          subject: hw.subject,
                          status: _buildStatusText(hw),
                          isOverdue: hw.status == 'overdue',
                        ),
                      ),
                    );
                  }),

                // ── MY TASKS section ──────────────────────────────────────
                const SizedBox(height: 20),
                const Text(
                  'MY TASKS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                if (_isLoadingTasks)
                  Column(
                    children: List.generate(
                      2,
                      (_) => const TaskRowSkeleton(),
                    ),
                  )
                else if (_tasks.isEmpty && !_isAddingTask)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'No tasks yet. Add one to get started!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  )
                else
                  ...List.generate(_tasks.length, (index) {
                    final task = _tasks[index];
                    return _buildTaskRow(task);
                  }),

                const SizedBox(height: 12),

                // ── Inline add input or Add Task button ───────────────────
                if (_isAddingTask)
                  _buildAddTaskInput()
                else
                  _buildAddTaskButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(TaskItem task) {
    final isDone = task.done;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: task.isOptimistic ? null : () => _toggleTask(task),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isDone ? AppColors.primary : Colors.grey.shade400,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDone
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textSecondary,
              ),
            ),
          ),
          // Optimistic spinner
          if (task.isOptimistic)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddTaskInput() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _taskController,
              focusNode: _taskFocusNode,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitNewTask(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Task title...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                isDense: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Add button
        GestureDetector(
          onTap: _submitNewTask,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'Add',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Cancel button
        GestureDetector(
          onTap: () {
            _taskController.clear();
            setState(() => _isAddingTask = false);
          },
          child: Icon(Icons.close, size: 20, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildAddTaskButton() {
    return GestureDetector(
      onTap: () => setState(() => _isAddingTask = true),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: Colors.grey.shade300,
          borderRadius: 12,
          dashWidth: 6,
          dashGap: 4,
          strokeWidth: 1.5,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  'Add Task',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Homework focus card helpers ─────────────────────────────────────────────

  String _buildStatusText(HomeworkItem hw) {
    final dateStr = _formatShortDate(hw.dueDate);
    if (hw.status == 'overdue') {
      return dateStr.isNotEmpty ? 'Overdue · $dateStr' : 'Overdue';
    } else if (hw.status == 'in_progress') {
      return dateStr.isNotEmpty ? 'Due · $dateStr' : 'Due';
    } else {
      return dateStr.isNotEmpty ? 'Due · $dateStr' : 'Pending';
    }
  }

  String _formatShortDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildFocusTask({
    required String title,
    required String subject,
    required String status,
    bool isOverdue = false,
  }) {
    const statusColor = AppColors.error;
    const bgColor = Color(0xFFFFF0F0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '·',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: statusColor,
                    ),
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', 0),
              _buildNavItem(Icons.description_outlined, 'Homework', 1),
              _buildCenterNavItem(),
              _buildNavItem(Icons.bar_chart, 'Progress', 3),
              _buildNavItem(Icons.person_outline, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterNavItem() {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

/// Paints a rounded-rectangle dashed border using [CustomPainter].
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  const _DashedBorderPainter({
    required this.color,
    this.borderRadius = 12,
    this.dashWidth = 6,
    this.dashGap = 4,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.borderRadius != borderRadius ||
      old.dashWidth != dashWidth ||
      old.dashGap != dashGap ||
      old.strokeWidth != strokeWidth;
}
