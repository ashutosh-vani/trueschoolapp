import 'package:flutter/material.dart';

class CareerDomain {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;

  const CareerDomain({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.gradientColors,
  });

  factory CareerDomain.fromJson(Map<String, dynamic> json) {
    final name = json['name'] ?? '';
    return CareerDomain(
      id: json['_id'] ?? json['id'] ?? '',
      name: name,
      description: json['description'] ?? '',
      icon: _iconFromName(name),
      gradientColors: _colorsFromName(name),
    );
  }

  static IconData _iconFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('technology') || lower.contains('engineering')) {
      return Icons.grid_view_rounded;
    } else if (lower.contains('medical') || lower.contains('health')) {
      return Icons.medical_services_outlined;
    } else if (lower.contains('government') || lower.contains('defence') || lower.contains('defense')) {
      return Icons.account_balance_outlined;
    } else if (lower.contains('business') || lower.contains('finance')) {
      return Icons.account_balance_wallet_outlined;
    } else if (lower.contains('law') || lower.contains('policy')) {
      return Icons.gavel_outlined;
    } else if (lower.contains('education') || lower.contains('research')) {
      return Icons.school_outlined;
    } else if (lower.contains('arts') || lower.contains('media') || lower.contains('design')) {
      return Icons.palette_outlined;
    } else if (lower.contains('social') || lower.contains('environment') ||
        lower.contains('sustainability') || lower.contains('eco')) {
      return Icons.eco_outlined;
    } else if (lower.contains('infrastructure') || lower.contains('travel') ||
        lower.contains('transport')) {
      return Icons.apartment_outlined;
    } else if (lower.contains('sports') || lower.contains('events')) {
      return Icons.sports_soccer_outlined;
    }
    return Icons.work_outline;
  }

  static List<Color> _colorsFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('technology') || lower.contains('engineering')) {
      return const [Color(0xFF7C3AED), Color(0xFFA78BFA)];
    } else if (lower.contains('medical') || lower.contains('health')) {
      return const [Color(0xFF10B981), Color(0xFF6EE7B7)];
    } else if (lower.contains('government') || lower.contains('defence')) {
      return const [Color(0xFF3B82F6), Color(0xFF93C5FD)];
    } else if (lower.contains('business') || lower.contains('finance')) {
      return const [Color(0xFFF59E0B), Color(0xFFFCD34D)];
    } else if (lower.contains('law') || lower.contains('policy')) {
      return const [Color(0xFF4B5563), Color(0xFF9CA3AF)];
    } else if (lower.contains('education') || lower.contains('research')) {
      return const [Color(0xFFEC4899), Color(0xFFF9A8D4)];
    } else if (lower.contains('arts') || lower.contains('media') || lower.contains('design')) {
      return const [Color(0xFFA855F7), Color(0xFFD8B4FE)];
    } else if (lower.contains('sports') || lower.contains('events')) {
      return const [Color(0xFFEF4444), Color(0xFFFCA5A5)];
    } else if (lower.contains('environment') || lower.contains('sustainability')) {
      return const [Color(0xFF059669), Color(0xFF6EE7B7)];
    }
    return const [Color(0xFF5B4CDB), Color(0xFF7C6FE8)];
  }
}

// ── Education path step ──────────────────────────────────────────────────
class EducationStep {
  final int step;
  final String title;
  final String description;
  final String status; // 'done' | 'current' | 'upcoming'

  const EducationStep({
    required this.step,
    required this.title,
    required this.description,
    required this.status,
  });

  factory EducationStep.fromJson(Map<String, dynamic> json) {
    return EducationStep(
      step: json['step'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'upcoming',
    );
  }
}

// ── Key skill with level & category ─────────────────────────────────────
class CareerSkill {
  final String skill;
  final int level;
  final String category;

  const CareerSkill({
    required this.skill,
    required this.level,
    required this.category,
  });

  factory CareerSkill.fromJson(Map<String, dynamic> json) {
    return CareerSkill(
      skill: json['skill'] ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
      category: json['category'] ?? 'Technical',
    );
  }
}

// ── Top college entry ────────────────────────────────────────────────────
class TopCollege {
  final String name;
  final String exam;
  final String type;

  const TopCollege({
    required this.name,
    required this.exam,
    required this.type,
  });

  factory TopCollege.fromJson(Map<String, dynamic> json) {
    return TopCollege(
      name: json['name'] ?? '',
      exam: json['exam'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

// ── Similar career reference ─────────────────────────────────────────────
class SimilarCareer {
  final String id;
  final String title;
  final int matchPercent;

  const SimilarCareer({
    required this.id,
    required this.title,
    required this.matchPercent,
  });

  factory SimilarCareer.fromJson(Map<String, dynamic> json) {
    return SimilarCareer(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      matchPercent: (json['matchPercent'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Career ───────────────────────────────────────────────────────────────
class Career {
  final String id;
  final String domainId;
  final String title;
  final String description;
  final String? salary;
  final String? education;
  final List<String> skills;

  // Rich detail fields (populated from /career/:domainId/:careerId)
  final int? matchPercent;
  final String? avgSalary;
  final String? growthOutlook;
  final String? jobOpenings;
  final String? yearsToQualify;
  final String? whatTheyDo;
  final String? domain;
  final List<String> dayInLife;
  final List<EducationStep> educationPath;
  final List<CareerSkill> keySkills;
  final List<TopCollege> topColleges;
  final List<SimilarCareer> similarCareers;

  const Career({
    required this.id,
    required this.domainId,
    required this.title,
    required this.description,
    this.salary,
    this.education,
    this.skills = const [],
    this.matchPercent,
    this.avgSalary,
    this.growthOutlook,
    this.jobOpenings,
    this.yearsToQualify,
    this.whatTheyDo,
    this.domain,
    this.dayInLife = const [],
    this.educationPath = const [],
    this.keySkills = const [],
    this.topColleges = const [],
    this.similarCareers = const [],
  });

  factory Career.fromJson(Map<String, dynamic> json) {
    return Career(
      id: json['_id'] ?? json['id'] ?? '',
      domainId: json['domain_id'] ?? json['domainId'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      salary: json['salary'],
      education: json['education'],
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      matchPercent: (json['matchPercent'] as num?)?.toInt(),
      avgSalary: json['avgSalary'],
      growthOutlook: json['growthOutlook'],
      jobOpenings: json['jobOpenings'],
      yearsToQualify: json['yearsToQualify'],
      whatTheyDo: json['whatTheyDo'],
      domain: json['domain'],
      dayInLife: (json['dayInLife'] as List<dynamic>?)?.cast<String>() ?? [],
      educationPath: (json['educationPath'] as List<dynamic>?)
              ?.map((e) => EducationStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      keySkills: (json['keySkills'] as List<dynamic>?)
              ?.map((e) => CareerSkill.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topColleges: (json['topColleges'] as List<dynamic>?)
              ?.map((e) => TopCollege.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      similarCareers: (json['similarCareers'] as List<dynamic>?)
              ?.map((e) => SimilarCareer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
