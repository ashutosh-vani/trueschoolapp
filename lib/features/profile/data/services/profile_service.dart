import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trueschoolapp/config/app_config.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';
import 'package:trueschoolapp/features/profile/data/models/profile_data.dart';

class ProfileService {
  static final String _baseUrl = AppConfig.apiUrl;

  // ── Fallback data (used when backend collections are empty) ──────────────

  static const List<IbTrait> _fallbackIbTraits = [
    IbTrait(title: 'Principled', evidenceCount: 12, progress: 0.85),
    IbTrait(title: 'Balanced',   evidenceCount: 8,  progress: 0.70),
    IbTrait(title: 'Thinker',    evidenceCount: 15, progress: 0.95),
    IbTrait(title: 'Caring',     evidenceCount: 10, progress: 0.90),
  ];

  static const AcademicProgress _fallbackAcademicProgress = AcademicProgress(
    semester: 'Semester 2',
    year: '2026',
    subjects: [
      SubjectProgress(subject: 'Mathematics',        progress: 0.85),
      SubjectProgress(subject: 'Science',            progress: 0.92),
      SubjectProgress(subject: 'English Literature', progress: 0.78),
      SubjectProgress(subject: 'Computer Science',   progress: 0.92),
      SubjectProgress(subject: 'History',            progress: 0.74),
    ],
    conceptsMastered: 0,
    improvement: '+12%',
    classRank: 'Top 15%',
  );

  static const List<ProjectItem> _fallbackProjects = [
    ProjectItem(
      title: 'Noticed Great Focus at Home',
      category: 'General',
      description: 'Alice Johnson spent 2 hours on homework without any reminders this week. Very proud!',
    ),
  ];

  static const List<ExtracurricularItem> _fallbackExtracurriculars = [
    ExtracurricularItem(name: 'Coding Club',    role: 'President',   iconName: 'coding'),
    ExtracurricularItem(name: 'Math Society',   role: 'Member',      iconName: 'math'),
    ExtracurricularItem(name: 'School Cricket', role: 'Player',      iconName: 'cricket'),
    ExtracurricularItem(name: 'Debate Team',    role: 'Participant', iconName: 'debate'),
  ];

  static const List<BadgeItem> _fallbackBadges = [
    BadgeItem(title: 'Streak Master',  date: 'Mar 12', iconName: 'streak'),
    BadgeItem(title: 'Excellence',     date: 'Feb 28', iconName: 'excellence'),
    BadgeItem(title: 'Sportsmanship',  date: 'Jan 15', iconName: 'sports'),
  ];

  static const List<AppreciationItem> _fallbackAppreciations = [
    AppreciationItem(
      from: 'Teacher',
      role: 'Teacher',
      date: 'Mar 10, 2026',
      message: 'Alice Johnson has been actively participating in class discussions and helping peers understand concepts.',
    ),
  ];

  static const String _fallbackBio =
      'Class 10-A student passionate about Mathematics and Computer Science. Aspiring software engineer.';

  // ── Auth headers ──────────────────────────────────────────────────────────

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Mirrors exactly what the web Portfolio.jsx does:
  ///   1. GET /student/profile          → user doc (name, class, roll, school, bio)
  ///   2. GET /student/portfolio-summary → bio, ibProfile, academicProgress, badges, extracurricular, stats
  ///   3. GET /portfolio/student         → portfolio entries (projects, teacher_note, achievement)
  static Future<ProfileData> getProfile() async {
    final headers = await _authHeaders();

    // ── 1. User document ─────────────────────────────────────────────────
    Map<String, dynamic> userDoc = {};
    try {
      final r = await http.get(Uri.parse('$_baseUrl/student/profile'), headers: headers);
      debugPrint('[ProfileService] GET /student/profile → ${r.statusCode}');
      debugPrint('[ProfileService] body: ${r.body}');
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        if (body is Map<String, dynamic>) userDoc = body;
      }
    } catch (e) {
      debugPrint('[ProfileService] /student/profile error: $e');
    }

    // ── 2. Portfolio summary ──────────────────────────────────────────────
    Map<String, dynamic> summary = {};
    try {
      final r = await http.get(Uri.parse('$_baseUrl/student/portfolio-summary'), headers: headers);
      debugPrint('[ProfileService] GET /student/portfolio-summary → ${r.statusCode}');
      debugPrint('[ProfileService] body: ${r.body}');
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        if (body is Map<String, dynamic>) summary = body;
      }
    } catch (e) {
      debugPrint('[ProfileService] /student/portfolio-summary error: $e');
    }

    // ── 3. Portfolio entries (projects + appreciations) ───────────────────
    List<dynamic> entries = [];
    try {
      final r = await http.get(Uri.parse('$_baseUrl/portfolio/student'), headers: headers);
      debugPrint('[ProfileService] GET /portfolio/student → ${r.statusCode}');
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        if (body is List) entries = body;
      }
    } catch (e) {
      debugPrint('[ProfileService] /portfolio/student error: $e');
    }

    return _buildProfile(userDoc, summary, entries);
  }

  // ── Builder ───────────────────────────────────────────────────────────────

  static ProfileData _buildProfile(
    Map<String, dynamic> userDoc,
    Map<String, dynamic> summary,
    List<dynamic> entries,
  ) {
    // ── Header ──────────────────────────────────────────────────────────────
    String classLabel = userDoc['class_name'] as String? ?? '';
    if (classLabel.isEmpty) {
      final grade   = userDoc['grade_number'] as String? ?? '';
      final section = userDoc['section_name'] as String? ?? '';
      if (grade.isNotEmpty || section.isNotEmpty) {
        classLabel = [
          if (grade.isNotEmpty)   'Grade $grade',
          if (section.isNotEmpty) section,
        ].join(' - ');
      }
    }

    // Bio: summary > userDoc > fallback (same priority as web's `d.bio`)
    final bio = _firstNonEmpty([
      summary['bio'] as String?,
      userDoc['bio'] as String?,
    ]) ?? _fallbackBio;

    final header = ProfileHeader(
      name:       userDoc['name']        as String? ?? '',
      classLabel: classLabel,
      rollNo:     userDoc['roll_no']     as String? ?? userDoc['roll_number'] as String? ?? '',
      schoolName: userDoc['school_name'] as String? ?? userDoc['school']      as String? ?? '',
      bio:        bio,
      avatarUrl:  userDoc['avatar']      as String? ?? userDoc['avatar_url']  as String?,
    );

    // ── IB Learner Profile ───────────────────────────────────────────────
    // summary.ibProfile: [{trait, icon, color, evidenceCount, percent}, ...]
    final ibRaw = summary['ibProfile'] as List<dynamic>? ?? [];
    final ibTraits = ibRaw.whereType<Map<String, dynamic>>().map((p) {
      final pct = (p['percent'] as num?)?.toDouble() ?? 0.0;
      return IbTrait(
        title:         p['trait']         as String? ?? '',
        evidenceCount: (p['evidenceCount'] as num?)?.toInt() ?? 0,
        progress:      (pct / 100).clamp(0.0, 1.0),
      );
    }).toList();

    // ── Academic Progress ────────────────────────────────────────────────
    // summary.academicProgress: [{subject, percent, semester}, ...]
    // summary.stats: {conceptsMastered, improvement, classRank, ...}
    final apRaw  = summary['academicProgress'] as List<dynamic>? ?? [];
    final stats  = summary['stats']            as Map<String, dynamic>? ?? {};
    final subjects = apRaw.whereType<Map<String, dynamic>>().map((s) {
      final pct = (s['percent'] as num?)?.toDouble() ?? 0.0;
      return SubjectProgress(
        subject:  s['subject'] as String? ?? '',
        progress: (pct / 100).clamp(0.0, 1.0),
      );
    }).toList();

    // Extract semester label from first subject entry
    final semesterRaw = apRaw.isNotEmpty
        ? (apRaw.first as Map<String, dynamic>)['semester'] as String? ?? ''
        : '';
    final semParts = semesterRaw.split('•').map((s) => s.trim()).toList();

    final academicProgress = AcademicProgress(
      semester:         semParts.isNotEmpty ? semParts[0] : '',
      year:             semParts.length > 1  ? semParts[1] : '',
      subjects:         subjects,
      conceptsMastered: (stats['conceptsMastered'] as num?)?.toInt() ?? 0,
      improvement:      stats['improvement'] as String? ?? '',
      classRank:        stats['classRank']   as String? ?? '',
    );

    // ── Badges ───────────────────────────────────────────────────────────
    // summary.badges: [{id, label, icon, color, date}, ...]
    final badgeRaw = summary['badges'] as List<dynamic>? ?? [];
    final badges = badgeRaw.whereType<Map<String, dynamic>>().map((b) => BadgeItem(
      title:    b['label'] as String? ?? b['title'] as String? ?? '',
      date:     b['date']  as String? ?? '',
      iconName: b['icon']  as String?,
      colorHex: b['color'] as String?,
    )).toList();

    // ── Extracurricular ──────────────────────────────────────────────────
    // summary.extracurricular: [{id, name, role, icon}, ...]
    final ecRaw = summary['extracurricular'] as List<dynamic>? ?? [];
    final extracurriculars = ecRaw.whereType<Map<String, dynamic>>().map((e) => ExtracurricularItem(
      name:     e['name'] as String? ?? '',
      role:     e['role'] as String? ?? '',
      iconName: e['icon'] as String?,
    )).toList();

    // ── Projects & Appreciations from portfolio entries ──────────────────
    // entries: [{type, title, subject, text/description, grade, created_at, tags, author, ...}, ...]
    final projectEntries = entries
        .whereType<Map<String, dynamic>>()
        .where((e) => e['type'] == 'project' || e['type'] == 'parent_reflection')
        .toList();

    final projects = projectEntries.map((e) => ProjectItem(
      title:       e['title']       as String? ?? '',
      category:    e['subject']     as String? ?? 'General',
      description: e['text']        as String? ?? e['description'] as String? ?? '',
    )).toList();

    final appreciationEntries = entries
        .whereType<Map<String, dynamic>>()
        .where((e) => e['type'] == 'teacher_note' || e['type'] == 'achievement')
        .toList();

    final appreciations = appreciationEntries.map((e) {
      final createdAt = e['created_at'] as String? ?? '';
      String dateStr = e['date'] as String? ?? '';
      if (dateStr.isEmpty && createdAt.isNotEmpty) {
        try {
          final dt = DateTime.parse(createdAt);
          const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
          dateStr = '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
        } catch (_) {}
      }
      return AppreciationItem(
        from:    e['author'] as String? ?? 'Teacher',
        role:    e['type'] == 'teacher_note' ? 'Teacher' : 'Achievement',
        date:    dateStr,
        message: e['text'] as String? ?? '',
      );
    }).toList();

    // ── Apply fallbacks for empty sections ───────────────────────────────
    return ProfileData(
      header:           header,
      ibTraits:         ibTraits.isNotEmpty         ? ibTraits         : _fallbackIbTraits,
      academicProgress: subjects.isNotEmpty         ? academicProgress : _fallbackAcademicProgress,
      projects:         projects.isNotEmpty         ? projects         : _fallbackProjects,
      extracurriculars: extracurriculars.isNotEmpty ? extracurriculars : _fallbackExtracurriculars,
      badges:           badges.isNotEmpty           ? badges           : _fallbackBadges,
      appreciations:    appreciations.isNotEmpty    ? appreciations    : _fallbackAppreciations,
    );
  }

  // ── Update profile ────────────────────────────────────────────────────────

  /// PATCH /student/profile  — editable fields: name and bio
  static Future<({bool success, String? error})> updateProfile({
    required String name,
    required String bio,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/student/profile'),
        headers: headers,
        body: jsonEncode({'name': name, 'bio': bio}),
      );

      debugPrint('[ProfileService] PATCH /student/profile → ${response.statusCode}');
      debugPrint('[ProfileService] body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        await TokenStorage.saveToken(
          token:  await TokenStorage.getToken()  ?? '',
          userId: await TokenStorage.getUserId() ?? '',
          role:   await TokenStorage.getRole()   ?? '',
          name:   name,
        );
        return (success: true, error: null);
      }

      String? message;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['detail'] as String? ?? body['message'] as String?;
      } catch (_) {}
      return (success: false, error: message ?? 'Update failed (${response.statusCode})');
    } catch (e) {
      debugPrint('[ProfileService] updateProfile error: $e');
      return (success: false, error: 'Network error. Please check your connection.');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}
