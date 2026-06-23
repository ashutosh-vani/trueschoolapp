import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/progress/data/models/learning_gap_models.dart';
import 'package:trueschoolapp/features/progress/data/services/learning_gap_service.dart';
import 'package:trueschoolapp/features/progress/presentation/pages/gap_remediation_page.dart';
import 'package:trueschoolapp/features/ai_tutor/presentation/pages/ai_tutor_page.dart';

const _kOrange = Color(0xFFEC5B13);

class LearningGapsListPage extends StatefulWidget {
  const LearningGapsListPage({super.key});

  @override
  State<LearningGapsListPage> createState() => _LearningGapsListPageState();
}

class _LearningGapsListPageState extends State<LearningGapsListPage> {
  GapHealth _health = GapHealth.fallback;
  List<LearningGap> _gaps = [];
  bool _loading = true;
  String _activeSubject = 'All';

  static const Map<String, List<String>> _subjectAliases = {
    'Math':      ['Math', 'Mathematics', 'Maths'],
    'Physics':   ['Physics', 'Science'],
    'Chemistry': ['Chemistry'],
    'Biology':   ['Biology'],
    'History':   ['History', 'SST', 'Social Studies'],
    'English':   ['English'],
  };

  static const _staticSubjectPills = [
    'All', 'Math', 'Physics', 'Chemistry', 'Biology', 'History', 'English'
  ];

  List<String> get _subjects {
    final fromApi = _gaps.map((g) => g.subject).where((s) => s.isNotEmpty).toSet();
    final covered = <String>{};
    for (final group in _subjectAliases.values) {
      covered.addAll(group);
    }
    final extras = fromApi.where((s) => !covered.contains(s)).toList()..sort();
    return [..._staticSubjectPills, ...extras];
  }

  bool _matchesSubject(LearningGap g, String pill) {
    if (pill == 'All') return true;
    final aliases = _subjectAliases[pill] ?? [pill];
    return aliases.contains(g.subject);
  }

  List<LearningGap> get _filtered =>
      _gaps.where((g) => _matchesSubject(g, _activeSubject)).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      LearningGapService.getHealth(),
      LearningGapService.getGaps(),
    ]);
    if (!mounted) return;
    final gaps = results[1] as List<LearningGap>;
    debugPrint('[LearningGapsListPage] loaded ${gaps.length} gaps');
    for (final g in gaps) {
      debugPrint('  • ${g.id} | ${g.subject} | ${g.topic} | ${g.severity} | mastery=${g.masteryPercent}');
    }
    setState(() {
      _health = results[0] as GapHealth;
      _gaps   = gaps;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AiTutorPage(),
            ),
          );
        },
        backgroundColor: _kOrange,
        shape: const CircleBorder(),
        child: const Icon(Icons.chat_outlined, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _kOrange))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: _kOrange,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildOverview(),
                            const SizedBox(height: 24),
                            _buildGapsSection(),
                            const SizedBox(height: 20),
                            _buildVinCta(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Learning Gap Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.info_outline, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final sev   = _health.severity;
    final total = sev.total == 0 ? 1 : sev.total;
    final crit  = (sev.critical / total * 100).round().clamp(1, 100);
    final mod   = (sev.moderate / total * 100).round().clamp(0, 100);
    final min   = (sev.minor    / total * 100).round().clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _card(child: Column(
            children: [
              const Text('Gap Health Score',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              _HealthRing(score: _health.score, trend: _health.trend),
              const SizedBox(height: 12),
              Text(_health.improvementMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            ],
          )),
          const SizedBox(height: 12),
          _card(child: Row(children: [
            _iconBox(_kOrange, Icons.warning_amber_rounded),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Gaps', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text('${_health.totalGaps}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ]),
          ])),
          const SizedBox(height: 12),
          _card(child: Row(children: [
            _iconBox(AppColors.success, Icons.check_circle_outline),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Resolved', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text('${_health.resolvedGaps}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ]),
          ])),
          const SizedBox(height: 12),
          _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Severity Breakdown',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(height: 8, child: Row(children: [
                  Expanded(flex: crit, child: Container(color: _kOrange)),
                  Expanded(flex: mod,  child: Container(color: AppColors.warning)),
                  Expanded(flex: min,  child: Container(color: AppColors.textHint)),
                ])),
              ),
              const SizedBox(height: 10),
              Row(children: [
                _sevDot(_kOrange, sev.critical, 'CRITICAL'),
                const SizedBox(width: 16),
                _sevDot(AppColors.warning, sev.moderate, 'MODERATE'),
                const SizedBox(width: 16),
                _sevDot(AppColors.textHint, sev.minor, 'MINOR'),
              ]),
            ],
          )),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );

  Widget _iconBox(Color color, IconData icon) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
    child: Icon(icon, color: color, size: 22),
  );

  Widget _sevDot(Color color, int count, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text('$count $label', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ],
  );

  Widget _buildGapsSection() {
    final filtered = _filtered;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Identified Learning Gaps',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _subjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _subjects[i];
                final active = s == _activeSubject;
                return GestureDetector(
                  onTap: () => setState(() => _activeSubject = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? _kOrange : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? _kOrange : AppColors.border),
                    ),
                    child: Text(s,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : AppColors.textSecondary)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No gaps found for this subject.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ...filtered.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _GapCard(
                gap: g,
                onFix: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => GapRemediationPage(gapId: g.id, gap: g))),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildVinCta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _kOrange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kOrange.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _kOrange.withValues(alpha: 0.2))),
            child: const Icon(Icons.psychology_outlined, color: _kOrange, size: 30),
          ),
          const SizedBox(height: 14),
          const Text('Need a customized learning plan?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
              'Lumi can analyze all your current gaps and create a 7-day schedule to get you back on track.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiTutorPage(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kOrange),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Talk to LumiTutor',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kOrange)),
          ),
        ]),
      ),
    );
  }
}

class _HealthRing extends StatelessWidget {
  final int score;
  final String trend;
  const _HealthRing({required this.score, required this.trend});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130, height: 130,
      child: CustomPaint(
        painter: _RingPainter(score / 100),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            RichText(text: TextSpan(children: [
              TextSpan(
                  text: '$score',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const TextSpan(
                  text: '/100',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ])),
            if (trend.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.trending_up, size: 14, color: AppColors.success),
                const SizedBox(width: 2),
                Text(trend,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
              ]),
          ]),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r  = size.width / 2 - 10;
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = const Color(0xFFF1F5F9)..style = PaintingStyle.stroke..strokeWidth = 10);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2, 2 * math.pi * progress, false,
      Paint()..color = _kOrange..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Gap Card ──────────────────────────────────────────────────────────────────
class _GapCard extends StatelessWidget {
  final LearningGap gap;
  final VoidCallback onFix;
  const _GapCard({required this.gap, required this.onFix});

  static const _sevColors  = {'critical': _kOrange, 'moderate': AppColors.warning, 'minor': AppColors.textHint};
  static const _sevLabels  = {'critical': 'CRITICAL', 'moderate': 'MODERATE', 'minor': 'MINOR'};
  static const _actionLabels = {
    'critical': 'Start Fixing This Gap',
    'moderate': 'Retry Concept',
    'minor': 'Quick Review',
  };
  static const _subjectColors = {
    'Math': Color(0xFF7E3AF2), 'Mathematics': Color(0xFF7E3AF2),
    'Physics': Color(0xFF1A56DB), 'Science': Color(0xFF1A56DB),
    'Chemistry': Color(0xFF057A55),
    'Biology': Color(0xFF047481),
    'History': Color(0xFFB45309), 'SST': Color(0xFFB45309),
    'English': Color(0xFFBE185D),
  };

  IconData _cpIcon(String n) {
    switch (n) {
      case 'play_circle': return Icons.play_circle_outline;
      case 'menu_book':   return Icons.menu_book_outlined;
      case 'edit_note':   return Icons.edit_note;
      case 'quiz':        return Icons.quiz_outlined;
      default:            return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sev          = gap.severity.isEmpty ? 'moderate' : gap.severity;
    final sevColor     = _sevColors[sev] ?? AppColors.warning;
    final sevLabel     = _sevLabels[sev] ?? sev.toUpperCase();
    final actionLabel  = _actionLabels[sev] ?? 'Fix Gap';
    final subjectColor = _subjectColors[gap.subject] ?? const Color(0xFF7E3AF2);

    final displaySubject = gap.subject.isEmpty ? 'GENERAL' : gap.subject.toUpperCase();
    final displayTopic = gap.topic.isEmpty ? 'Learning Gap' : gap.topic;
    final displaySubtopic = gap.subtopic.isEmpty ? 'Core concepts' : gap.subtopic;
    final whatWentWrong = gap.aiErrorSummary.isEmpty
        ? 'You showed difficulty with $displayTopic. Review and practice this topic.'
        : gap.aiErrorSummary;
    final coachingNote = gap.aiLastFeedback.isEmpty
        ? 'Focus on the core definition before attempting harder problems.'
        : gap.aiLastFeedback;
    final identifiedFromTitle = gap.identifiedFrom.title.isEmpty
        ? 'Recent Assessment'
        : gap.identifiedFrom.title;
    final impactText = gap.impactAnalysis.isEmpty
        ? 'Mastery is required for upcoming assessments.'
        : gap.impactAnalysis;
    final prereqText = gap.prerequisiteDependency.isEmpty
        ? 'Requires understanding of prior units.'
        : gap.prerequisiteDependency;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: sevColor, width: 4),
          top: const BorderSide(color: Color(0xFFE2E8F0)),
          right: const BorderSide(color: Color(0xFFE2E8F0)),
          bottom: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badges
            Row(children: [
              _badge(displaySubject, subjectColor, subjectColor.withValues(alpha: 0.08)),
              const SizedBox(width: 6),
              _badge(sevLabel, sevColor, sevColor.withValues(alpha: 0.1)),
              const Spacer(),
              const Icon(Icons.more_vert, color: AppColors.textHint, size: 20),
            ]),
            const SizedBox(height: 12),

            // Title
            Text(displayTopic,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(displaySubtopic,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),

            // What Went Wrong
            _infoBox(Icons.error_outline, _kOrange, 'WHAT WENT WRONG',
                _kOrange.withValues(alpha: 0.05), whatWentWrong, _kOrange),
            const SizedBox(height: 10),

            // Lumi's Coaching Note
            _infoBox(Icons.smart_toy_outlined, AppColors.primary, "LUMI'S COACHING NOTE",
                AppColors.primary.withValues(alpha: 0.05), coachingNote, AppColors.textPrimary),
            const SizedBox(height: 16),

            // Identified From
            _metaLabel(Icons.description_outlined, 'IDENTIFIED FROM'),
            const SizedBox(height: 4),
            Row(children: [
              Flexible(
                child: Text(identifiedFromTitle,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kOrange),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new, size: 13, color: _kOrange),
            ]),
            const SizedBox(height: 14),

            // Impact Analysis
            _metaLabel(Icons.trending_up, 'IMPACT ANALYSIS'),
            const SizedBox(height: 4),
            _richLine(impactText, gap.impactSubject),
            const SizedBox(height: 14),

            // Prerequisite
            _metaLabel(Icons.link, 'PREREQUISITE'),
            const SizedBox(height: 4),
            _richLine(prereqText, gap.prerequisiteSubject),
            const SizedBox(height: 16),

            // Mastery
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('MASTERY',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              Text('${gap.masteryPercent}%',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (gap.masteryPercent / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: sevColor,
              ),
            ),
            const SizedBox(height: 16),

            // Corrective path
            if (gap.correctivePath.isNotEmpty) ...[
              _buildCorrectivePathRow(),
              const SizedBox(height: 10),
            ],

            // Ask LumiTutor
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AiTutorPage(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 18),
                label: const Text('Ask LumiTutor',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 10),

            // Primary CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onFix,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(actionLabel,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectivePathRow() {
    final items = gap.correctivePath.take(2).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    if (items.length == 1) {
      return _cpButton(_cpIcon(items[0].icon), items[0].label, items[0].detail);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _cpButton(_cpIcon(items[0].icon), items[0].label, items[0].detail)),
        const SizedBox(width: 8),
        Expanded(child: _cpButton(_cpIcon(items[1].icon), items[1].label, items[1].detail)),
      ],
    );
  }

  Widget _badge(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.4)),
  );

  Widget _infoBox(IconData icon, Color iconColor, String label, Color bg, String text, Color textColor) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: iconColor, letterSpacing: 0.8)),
            ]),
            const SizedBox(height: 6),
            Text(text, style: TextStyle(fontSize: 13, color: textColor, height: 1.5)),
          ],
        ),
      );

  Widget _metaLabel(IconData icon, String label) => Row(children: [
    Icon(icon, size: 13, color: AppColors.textHint),
    const SizedBox(width: 5),
    Text(label,
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
  ]);

  Widget _richLine(String text, String bold) {
    if (bold.isEmpty || !text.contains(bold)) {
      return Text(text,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5));
    }
    final idx = text.indexOf(bold);
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: text.substring(idx + bold.length)),
        ],
      ),
    );
  }

  Widget _cpButton(IconData icon, String label, String detail) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              if (detail.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(detail,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
