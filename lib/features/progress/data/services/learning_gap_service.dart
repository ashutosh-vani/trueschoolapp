import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trueschoolapp/config/app_config.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';
import 'package:trueschoolapp/features/progress/data/models/learning_gap_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static fallback data (mirrors web frontend learningGapData.js)
// Used when the API returns empty or errors, just like the web frontend
// ─────────────────────────────────────────────────────────────────────────────

const _fallbackHealth = GapHealth(
  score: 78,
  maxScore: 100,
  trend: '+5%',
  improvementMessage:
      "Great job! You've improved your health score by 12 points this month.",
  totalGaps: 12,
  totalGapsTrend: '-2%',
  resolvedGaps: 8,
  resolvedGapsTrend: '+10%',
  severity: GapSeverityCounts(critical: 3, moderate: 5, minor: 4),
);

final List<LearningGap> _fallbackGaps = [
  LearningGap(
    id: 'lg001',
    subject: 'Math',
    topic: 'Quadratic Equations',
    subtopic: 'Discriminant & Nature of Roots',
    severity: 'critical',
    status: 'active',
    identifiedFrom: const IdentifiedFrom(
      title: 'Unit 3 Quiz: Algebra Foundations',
      type: 'quiz',
      date: '2026-03-20',
    ),
    impactAnalysis:
        'Mastery required for Calculus and complex optimization problems.',
    impactSubject: 'Calculus',
    prerequisiteDependency:
        'Requires full mastery of Basic Algebra and factoring.',
    prerequisiteSubject: 'Basic Algebra',
    masteryPercent: 38,
    recommendedTimeMinutes: 120,
    attempts: const [
      GapAttempt(attemptNumber: 1, score: 40, date: '2026-03-20'),
      GapAttempt(attemptNumber: 2, score: 65, date: '2026-03-23'),
    ],
    prerequisites: const [
      Prerequisite(
          topic: 'Basic Algebra', masteryPercent: 92, status: 'mastered'),
      Prerequisite(
          topic: 'Equation Solving', masteryPercent: 64, status: 'weak'),
      Prerequisite(
          topic: 'Discriminant Logic', masteryPercent: 38, status: 'current'),
    ],
    correctivePath: const [
      CorrectivePath(
          type: 'video',
          label: 'Watch Video',
          detail: 'Nature of Roots (4m)',
          icon: 'play_circle'),
      CorrectivePath(
          type: 'reading',
          label: 'Read Summary',
          detail: 'Key Rules & Formulas',
          icon: 'menu_book'),
      CorrectivePath(
          type: 'practice',
          label: 'Practice',
          detail: '10 targeted questions',
          icon: 'edit_note'),
    ],
    aiErrorSummary:
        "You consistently struggled with identifying the number of roots when D < 0. Specifically, you confused 'No Real Roots' with 'Zero Roots.'",
    aiLastFeedback:
        'In your last attempt, you correctly identified b = -4, but forgot that squaring a negative number results in a positive. Remember: (-4)² = 16. Watch out for this common sign error!',
    visualRef: const VisualRef(
      label: 'Visual Quick-Ref: The Three Cases',
      detail: 'D > 0 (Two Roots), D = 0 (One Root), D < 0 (Complex Roots)',
    ),
    retryQuestion: const RetryQuestion(
      text:
          'Consider the quadratic equation: 3x² - 4x + 5 = 0. Determine the value of the discriminant (D) and state the nature and number of the roots.',
      equation: '3x² - 4x + 5 = 0',
      type: 'typed',
    ),
  ),
  LearningGap(
    id: 'lg002',
    subject: 'Chemistry',
    topic: 'Stoichiometry & Mole Ratios',
    subtopic: 'Balancing Chemical Equations',
    severity: 'moderate',
    status: 'active',
    identifiedFrom: const IdentifiedFrom(
      title: 'Homework #14: Balancing Equations',
      type: 'homework',
      date: '2026-03-22',
    ),
    impactAnalysis:
        'Critical for understanding Limiting Reagents and Gas Laws.',
    impactSubject: 'Limiting Reagents',
    prerequisiteDependency: 'Needs review of Molar Mass Calculations.',
    prerequisiteSubject: 'Molar Mass Calculations',
    masteryPercent: 55,
    recommendedTimeMinutes: 60,
    attempts: const [
      GapAttempt(attemptNumber: 1, score: 55, date: '2026-03-22'),
    ],
    prerequisites: const [
      Prerequisite(
          topic: 'Atomic Structure', masteryPercent: 88, status: 'mastered'),
      Prerequisite(
          topic: 'Molar Mass Calculations',
          masteryPercent: 70,
          status: 'weak'),
      Prerequisite(
          topic: 'Stoichiometry', masteryPercent: 55, status: 'current'),
    ],
    correctivePath: const [
      CorrectivePath(
          type: 'video',
          label: 'Watch Video',
          detail: 'Mole Ratios Explained (6m)',
          icon: 'play_circle'),
      CorrectivePath(
          type: 'practice',
          label: 'Practice',
          detail: '8 targeted questions',
          icon: 'edit_note'),
    ],
    aiErrorSummary:
        'You struggled with converting between moles and grams when the molar mass involves decimal values.',
    aiLastFeedback:
        'Remember to always write out the mole ratio from the balanced equation before doing any calculations.',
    retryQuestion: const RetryQuestion(
      text: 'How many moles of H₂O are produced when 2 moles of H₂ react with excess O₂?',
      equation: '2H₂ + O₂ → 2H₂O',
      type: 'mcq',
    ),
  ),
  LearningGap(
    id: 'lg003',
    subject: 'Physics',
    topic: "Newton's Third Law",
    subtopic: 'Action-Reaction Pairs',
    severity: 'minor',
    status: 'active',
    identifiedFrom: const IdentifiedFrom(
      title: 'Chapter Review: Dynamics',
      type: 'quiz',
      date: '2026-03-18',
    ),
    impactAnalysis: 'Minor impact on Orbital Mechanics calculations.',
    impactSubject: 'Orbital Mechanics',
    prerequisiteDependency:
        'Understood well, just needs Vector Addition refresher.',
    prerequisiteSubject: 'Vector Addition',
    masteryPercent: 72,
    recommendedTimeMinutes: 30,
    attempts: const [
      GapAttempt(attemptNumber: 1, score: 72, date: '2026-03-18'),
    ],
    prerequisites: const [
      Prerequisite(
          topic: "Newton's First Law", masteryPercent: 95, status: 'mastered'),
      Prerequisite(
          topic: "Newton's Second Law",
          masteryPercent: 88,
          status: 'mastered'),
      Prerequisite(
          topic: "Newton's Third Law", masteryPercent: 72, status: 'current'),
    ],
    correctivePath: const [
      CorrectivePath(
          type: 'video',
          label: 'Watch Video',
          detail: 'Action-Reaction (3m)',
          icon: 'play_circle'),
    ],
    aiErrorSummary:
        'You correctly identified action-reaction pairs in simple cases but struggled with complex multi-body systems.',
    aiLastFeedback:
        'Focus on identifying the two objects involved in each force pair. The forces are always equal in magnitude but opposite in direction.',
    retryQuestion: const RetryQuestion(
      text:
          'A book rests on a table. Identify the action-reaction pair for the gravitational force on the book.',
      type: 'typed',
    ),
  ),
  LearningGap(
    id: 'lg004',
    subject: 'Math',
    topic: 'Trigonometry',
    subtopic: 'Sine & Cosine Rules',
    severity: 'moderate',
    status: 'in_progress',
    identifiedFrom: const IdentifiedFrom(
      title: 'Unit 4 Test: Trigonometry',
      type: 'test',
      date: '2026-03-15',
    ),
    impactAnalysis: 'Required for advanced calculus and wave mechanics.',
    impactSubject: 'Calculus',
    prerequisiteDependency: 'Requires Pythagoras theorem mastery.',
    prerequisiteSubject: 'Pythagoras Theorem',
    masteryPercent: 60,
    recommendedTimeMinutes: 90,
    attempts: const [
      GapAttempt(attemptNumber: 1, score: 45, date: '2026-03-15'),
      GapAttempt(attemptNumber: 2, score: 60, date: '2026-03-24'),
    ],
    prerequisites: const [
      Prerequisite(
          topic: 'Pythagoras Theorem', masteryPercent: 90, status: 'mastered'),
      Prerequisite(
          topic: 'Basic Trig Ratios', masteryPercent: 75, status: 'weak'),
      Prerequisite(
          topic: 'Sine & Cosine Rules', masteryPercent: 60, status: 'current'),
    ],
    correctivePath: const [
      CorrectivePath(
          type: 'video',
          label: 'Watch Video',
          detail: 'Sine Rule Derivation (5m)',
          icon: 'play_circle'),
      CorrectivePath(
          type: 'reading',
          label: 'Read Summary',
          detail: 'Formula Sheet',
          icon: 'menu_book'),
      CorrectivePath(
          type: 'practice',
          label: 'Practice',
          detail: '12 targeted questions',
          icon: 'edit_note'),
    ],
    aiErrorSummary:
        'You applied the sine rule correctly but made errors in the ambiguous case (two possible triangles).',
    aiLastFeedback:
        'When using the sine rule, always check if the angle could be obtuse. If sin(A) gives a valid angle, check if 180° - A also works.',
    retryQuestion: const RetryQuestion(
      text: 'In triangle ABC, a = 7, b = 10, A = 30°. Find angle B.',
      type: 'typed',
    ),
  ),
];

final List<QuizSummary> _fallbackQuizSummaries = [
  const QuizSummary(
    id: 'quiz001',
    title: 'Quadratic Equations - Easy',
    subject: 'Math',
    topic: 'Quadratic Equations',
    difficulty: 'easy',
    totalQuestions: 5,
    estimatedMinutes: 15,
  ),
  const QuizSummary(
    id: 'quiz002',
    title: 'Stoichiometry - Medium',
    subject: 'Chemistry',
    topic: 'Stoichiometry',
    difficulty: 'medium',
    totalQuestions: 8,
    estimatedMinutes: 20,
  ),
];

final Quiz _fallbackQuiz001 = Quiz(
  id: 'quiz001',
  title: 'Quadratic Equations - Easy',
  subject: 'Math',
  topic: 'Quadratic Equations',
  difficulty: 'easy',
  totalQuestions: 5,
  estimatedMinutes: 15,
  questions: [
    QuizQuestion(
      id: 'qq1',
      number: 1,
      difficulty: 'Easy',
      prompt: 'Solve for x:',
      equation: 'x² - 4 = 0',
      options: const [
        QuizOption(id: 'A', text: 'x = 0', isCorrect: false),
        QuizOption(id: 'B', text: 'x = ±2', isCorrect: true),
        QuizOption(id: 'C', text: 'x = 4', isCorrect: false),
        QuizOption(id: 'D', text: 'x = 1', isCorrect: false),
      ],
      explanation:
          'The square root of 4 is both 2 and -2, therefore x² = 4 leads to x = ±2. Remember to always consider both positive and negative roots.',
      hint: 'Always isolate the squared term first before taking the square root.',
    ),
    QuizQuestion(
      id: 'qq2',
      number: 2,
      difficulty: 'Easy',
      prompt: 'What is the discriminant of:',
      equation: 'x² + 6x + 9 = 0',
      options: const [
        QuizOption(id: 'A', text: 'D = 0', isCorrect: true),
        QuizOption(id: 'B', text: 'D = 36', isCorrect: false),
        QuizOption(id: 'C', text: 'D = -36', isCorrect: false),
        QuizOption(id: 'D', text: 'D = 9', isCorrect: false),
      ],
      explanation:
          'D = b² - 4ac = 36 - 4(1)(9) = 36 - 36 = 0. Since D = 0, there is exactly one repeated real root.',
      hint: 'Use D = b² - 4ac. Here a=1, b=6, c=9.',
    ),
    QuizQuestion(
      id: 'qq3',
      number: 3,
      difficulty: 'Easy',
      prompt: 'Solve for x:',
      equation: 'x² + 5x + 6 = 0',
      options: const [
        QuizOption(id: 'A', text: 'x = -2, -3', isCorrect: true),
        QuizOption(id: 'B', text: 'x = 2, 3', isCorrect: false),
        QuizOption(id: 'C', text: 'x = -1, -6', isCorrect: false),
        QuizOption(id: 'D', text: 'x = 1, 6', isCorrect: false),
      ],
      explanation:
          'Factor: (x+2)(x+3) = 0, so x = -2 or x = -3.',
      hint: 'Find two numbers that multiply to 6 and add to 5.',
    ),
    QuizQuestion(
      id: 'qq4',
      number: 4,
      difficulty: 'Medium',
      prompt: 'How many real roots does this equation have?',
      equation: '2x² + 3x + 5 = 0',
      options: const [
        QuizOption(id: 'A', text: 'Two real roots', isCorrect: false),
        QuizOption(id: 'B', text: 'One real root', isCorrect: false),
        QuizOption(id: 'C', text: 'No real roots', isCorrect: true),
        QuizOption(id: 'D', text: 'Infinite roots', isCorrect: false),
      ],
      explanation:
          'D = 9 - 40 = -31 < 0. Since D < 0, there are no real roots.',
      hint: 'Calculate the discriminant first. If D < 0, there are no real roots.',
    ),
    QuizQuestion(
      id: 'qq5',
      number: 5,
      difficulty: 'Medium',
      prompt: 'Using the quadratic formula, solve:',
      equation: 'x² - 5x + 6 = 0',
      options: const [
        QuizOption(id: 'A', text: 'x = 2, 3', isCorrect: true),
        QuizOption(id: 'B', text: 'x = -2, -3', isCorrect: false),
        QuizOption(id: 'C', text: 'x = 1, 6', isCorrect: false),
        QuizOption(id: 'D', text: 'x = -1, -6', isCorrect: false),
      ],
      explanation:
          'D = 25 - 24 = 1. x = (5 ± 1)/2, so x = 3 or x = 2.',
      hint: 'Apply x = (-b ± √D) / 2a with a=1, b=-5, c=6.',
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class LearningGapService {
  static final String _base = AppConfig.apiUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Health ──────────────────────────────────────────────────────────────────

  static Future<GapHealth> getHealth() async {
    try {
      final r = await http.get(
        Uri.parse('$_base/learning-gaps/health'),
        headers: await _headers(),
      );
      debugPrint('[LGService] GET /learning-gaps/health → ${r.statusCode}');
      if (r.statusCode == 200) {
        return GapHealth.fromJson(
            jsonDecode(r.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[LGService] getHealth error: $e');
    }
    return _fallbackHealth;
  }

  // ── Gaps list ───────────────────────────────────────────────────────────────

  static Future<List<LearningGap>> getGaps() async {
    try {
      final r = await http.get(
        Uri.parse('$_base/learning-gaps/'),
        headers: await _headers(),
      );
      debugPrint('[LGService] GET /learning-gaps/ → ${r.statusCode}');
      if (r.statusCode == 200) {
        final List<dynamic> data = jsonDecode(r.body);
        if (data.isNotEmpty) {
          // Enrich each backend gap with fallback content for missing fields
          // (mirrors the web frontend pattern of using seeded mock data + API overlay)
          return data
              .map((d) => _enrichGap(d as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[LGService] getGaps error: $e');
    }
    return _fallbackGaps;
  }

  /// Fills in missing fields the seeded backend doesn't include
  /// (aiErrorSummary, prerequisites, attempts, full corrective paths, etc.)
  /// so the UI is never blank.
  static LearningGap _enrichGap(Map<String, dynamic> j) {
    final topic    = (j['topic'] ?? '').toString();
    final subject  = (j['subject'] ?? '').toString();
    final severity = (j['severity'] ?? 'minor').toString();

    // Provide content where backend left fields empty/missing
    j['aiErrorSummary'] = j['aiErrorSummary']?.toString().isNotEmpty == true
        ? j['aiErrorSummary']
        : 'You showed difficulty with $topic. Several questions on this topic '
            'were answered incorrectly, indicating gaps in your understanding.';

    j['aiLastFeedback'] = j['aiLastFeedback']?.toString().isNotEmpty == true
        ? j['aiLastFeedback']
        : 'Focus on the core definition and common patterns in $topic before '
            'attempting harder problems.';

    j['impactAnalysis'] = j['impactAnalysis']?.toString().isNotEmpty == true
        ? j['impactAnalysis']
        : 'Mastery of $topic is required for upcoming $subject assessments and '
            'related advanced topics.';

    j['impactSubject'] = j['impactSubject']?.toString().isNotEmpty == true
        ? j['impactSubject']
        : subject;

    j['prerequisiteDependency'] =
        j['prerequisiteDependency']?.toString().isNotEmpty == true
            ? j['prerequisiteDependency']
            : 'Requires understanding of basic $subject concepts and prior '
                'units before this topic.';

    j['prerequisiteSubject'] =
        j['prerequisiteSubject']?.toString().isNotEmpty == true
            ? j['prerequisiteSubject']
            : 'Basic $subject';

    j['subtopic'] = j['subtopic']?.toString().isNotEmpty == true
        ? j['subtopic']
        : 'Core concepts in $topic';

    // Mastery score: backend uses `score` (0-100), web uses `masteryPercent`
    if (j['masteryPercent'] == null && j['score'] != null) {
      j['masteryPercent'] = j['score'];
    }

    // identifiedFrom — flesh out missing type/date
    final idf = j['identifiedFrom'];
    if (idf is Map) {
      idf['type'] = idf['type']?.toString().isNotEmpty == true
          ? idf['type']
          : 'homework';
      idf['date'] = idf['date']?.toString().isNotEmpty == true
          ? idf['date']
          : '';
    } else {
      j['identifiedFrom'] = {
        'title': 'Recent Assessment',
        'type': 'homework',
        'date': '',
      };
    }

    // correctivePath — add detail strings if missing, ensure at least 2 items
    final cp = j['correctivePath'];
    if (cp is List && cp.isNotEmpty) {
      for (var i = 0; i < cp.length; i++) {
        final item = cp[i];
        if (item is Map) {
          item['detail'] = item['detail']?.toString().isNotEmpty == true
              ? item['detail']
              : (item['type'] == 'video'
                  ? 'Watch focused explanation'
                  : item['type'] == 'reading'
                      ? 'Read key rules & summary'
                      : 'Targeted practice set');
        }
      }
    } else {
      j['correctivePath'] = [
        {
          'type': 'video',
          'label': 'Watch Explanation',
          'detail': '$topic basics',
          'icon': 'play_circle',
        },
        {
          'type': 'practice',
          'label': 'Practice Problems',
          'detail': 'Targeted questions',
          'icon': 'edit_note',
        },
      ];
    }

    // Severity color/label is handled in UI; ensure value is one of the known keys
    if (severity != 'critical' && severity != 'moderate' && severity != 'minor') {
      j['severity'] = 'moderate';
    }

    return LearningGap.fromJson(j);
  }

  // ── Single gap ──────────────────────────────────────────────────────────────

  static Future<LearningGap?> getGap(String gapId) async {
    try {
      final r = await http.get(
        Uri.parse('$_base/learning-gaps/$gapId'),
        headers: await _headers(),
      );
      if (r.statusCode == 200) {
        return _enrichGap(jsonDecode(r.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[LGService] getGap error: $e');
    }
    // Fallback to local list
    try {
      return _fallbackGaps.firstWhere((g) => g.id == gapId);
    } catch (_) {
      return null;
    }
  }

  // ── Remediation ─────────────────────────────────────────────────────────────

  static Future<RemediationContent?> getRemediation(String gapId) async {
    try {
      final r = await http.get(
        Uri.parse('$_base/learning-gaps/$gapId/remediation'),
        headers: await _headers(),
      );
      debugPrint(
          '[LGService] GET /learning-gaps/$gapId/remediation → ${r.statusCode}');
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final rem = data['remediation'] as Map<String, dynamic>?;
        if (rem != null) return RemediationContent.fromJson(rem);
      }
    } catch (e) {
      debugPrint('[LGService] getRemediation error: $e');
    }
    return null;
  }

  // ── Quiz list ───────────────────────────────────────────────────────────────

  static Future<List<QuizSummary>> getQuizList() async {
    try {
      final r = await http.get(
        Uri.parse('$_base/learning-gaps/quizzes'),
        headers: await _headers(),
      );
      debugPrint('[LGService] GET /learning-gaps/quizzes → ${r.statusCode}');
      if (r.statusCode == 200) {
        final List<dynamic> data = jsonDecode(r.body);
        if (data.isNotEmpty) {
          return data
              .map((d) => QuizSummary.fromJson(d as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[LGService] getQuizList error: $e');
    }
    return _fallbackQuizSummaries;
  }

  // ── Single quiz ─────────────────────────────────────────────────────────────

  static Future<Quiz?> getQuiz(String quizId) async {
    try {
      final r = await http.get(
        Uri.parse('$_base/learning-gaps/quiz/$quizId'),
        headers: await _headers(),
      );
      debugPrint(
          '[LGService] GET /learning-gaps/quiz/$quizId → ${r.statusCode}');
      if (r.statusCode == 200) {
        final q = Quiz.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
        if (q.questions.isNotEmpty) return q;
      }
    } catch (e) {
      debugPrint('[LGService] getQuiz error: $e');
    }
    // Fallback
    if (quizId == 'quiz001') return _fallbackQuiz001;
    return null;
  }

  // ── Submit quiz ─────────────────────────────────────────────────────────────

  static Future<QuizResult?> submitQuiz(
      String quizId, List<QuizAnswer> answers) async {
    try {
      final r = await http.post(
        Uri.parse('$_base/learning-gaps/quiz/submit'),
        headers: await _headers(),
        body: jsonEncode({
          'quiz_id': quizId,
          'answers': answers.map((a) => a.toJson()).toList(),
        }),
      );
      debugPrint('[LGService] POST /learning-gaps/quiz/submit → ${r.statusCode}');
      if (r.statusCode == 200) {
        return QuizResult.fromJson(
            jsonDecode(r.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[LGService] submitQuiz error: $e');
    }
    return null;
  }
}
