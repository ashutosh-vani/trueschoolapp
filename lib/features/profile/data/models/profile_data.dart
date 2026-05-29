// Models for the student profile feature.
// All fields use safe defaults so the UI degrades gracefully when the API
// returns partial data.

class ProfileData {
  final ProfileHeader header;
  final List<IbTrait> ibTraits;
  final AcademicProgress academicProgress;
  final List<ProjectItem> projects;
  final List<ExtracurricularItem> extracurriculars;
  final List<BadgeItem> badges;
  final List<AppreciationItem> appreciations;

  const ProfileData({
    required this.header,
    required this.ibTraits,
    required this.academicProgress,
    required this.projects,
    required this.extracurriculars,
    required this.badges,
    required this.appreciations,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      header: ProfileHeader.fromJson(
          (json['header'] as Map<String, dynamic>?) ?? {}),
      ibTraits: (json['ib_traits'] as List<dynamic>?)
              ?.map((e) => IbTrait.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      academicProgress: AcademicProgress.fromJson(
          (json['academic_progress'] as Map<String, dynamic>?) ?? {}),
      projects: (json['projects'] as List<dynamic>?)
              ?.map((e) => ProjectItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      extracurriculars: (json['extracurriculars'] as List<dynamic>?)
              ?.map((e) =>
                  ExtracurricularItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => BadgeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      appreciations: (json['appreciations'] as List<dynamic>?)
              ?.map((e) =>
                  AppreciationItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class ProfileHeader {
  final String name;
  final String classLabel;
  final String rollNo;
  final String schoolName;
  final String bio;
  final String? avatarUrl;

  const ProfileHeader({
    required this.name,
    required this.classLabel,
    required this.rollNo,
    required this.schoolName,
    required this.bio,
    this.avatarUrl,
  });

  factory ProfileHeader.fromJson(Map<String, dynamic> json) {
    return ProfileHeader(
      name: json['name'] as String? ?? '',
      classLabel: json['class_label'] as String? ?? '',
      rollNo: json['roll_no'] as String? ?? '',
      schoolName: json['school_name'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// IB Learner Profile
// ---------------------------------------------------------------------------

class IbTrait {
  final String title;
  final int evidenceCount;
  final double progress; // 0.0 – 1.0

  const IbTrait({
    required this.title,
    required this.evidenceCount,
    required this.progress,
  });

  factory IbTrait.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['progress'];
    double progress = 0.0;
    if (rawProgress is num) {
      progress = rawProgress.toDouble().clamp(0.0, 1.0);
    }
    return IbTrait(
      title: json['title'] as String? ?? '',
      evidenceCount: (json['evidence_count'] as num?)?.toInt() ?? 0,
      progress: progress,
    );
  }
}

// ---------------------------------------------------------------------------
// Academic Progress
// ---------------------------------------------------------------------------

class SubjectProgress {
  final String subject;
  final double progress; // 0.0 – 1.0

  const SubjectProgress({required this.subject, required this.progress});

  factory SubjectProgress.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['progress'];
    double progress = 0.0;
    if (rawProgress is num) {
      progress = rawProgress.toDouble().clamp(0.0, 1.0);
    }
    return SubjectProgress(
      subject: json['subject'] as String? ?? '',
      progress: progress,
    );
  }
}

class AcademicProgress {
  final String semester;
  final String year;
  final List<SubjectProgress> subjects;
  final int conceptsMastered;
  final String improvement;
  final String classRank;

  const AcademicProgress({
    required this.semester,
    required this.year,
    required this.subjects,
    required this.conceptsMastered,
    required this.improvement,
    required this.classRank,
  });

  factory AcademicProgress.fromJson(Map<String, dynamic> json) {
    return AcademicProgress(
      semester: json['semester'] as String? ?? '',
      year: json['year'] as String? ?? '',
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((e) =>
                  SubjectProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      conceptsMastered:
          (json['concepts_mastered'] as num?)?.toInt() ?? 0,
      improvement: json['improvement'] as String? ?? '',
      classRank: json['class_rank'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Projects
// ---------------------------------------------------------------------------

class ProjectItem {
  final String title;
  final String category;
  final String description;

  const ProjectItem({
    required this.title,
    required this.category,
    required this.description,
  });

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Extracurriculars
// ---------------------------------------------------------------------------

class ExtracurricularItem {
  final String name;
  final String role;
  final String? iconName; // optional icon hint from backend

  const ExtracurricularItem({
    required this.name,
    required this.role,
    this.iconName,
  });

  factory ExtracurricularItem.fromJson(Map<String, dynamic> json) {
    return ExtracurricularItem(
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      iconName: json['icon'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Badges
// ---------------------------------------------------------------------------

class BadgeItem {
  final String title;
  final String date;
  final String? iconName; // optional icon hint from backend
  final String? colorHex;

  const BadgeItem({
    required this.title,
    required this.date,
    this.iconName,
    this.colorHex,
  });

  factory BadgeItem.fromJson(Map<String, dynamic> json) {
    return BadgeItem(
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      iconName: json['icon'] as String?,
      colorHex: json['color'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Appreciations
// ---------------------------------------------------------------------------

class AppreciationItem {
  final String from;
  final String role;
  final String date;
  final String message;

  const AppreciationItem({
    required this.from,
    required this.role,
    required this.date,
    required this.message,
  });

  factory AppreciationItem.fromJson(Map<String, dynamic> json) {
    return AppreciationItem(
      from: json['from'] as String? ?? '',
      role: json['role'] as String? ?? '',
      date: json['date'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}
