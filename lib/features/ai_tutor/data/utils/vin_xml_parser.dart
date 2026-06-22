// Incremental XML parser for Lumi streaming responses.
// Mirrors the logic in web/schoolai/frontend/src/utils/xmlParser.js
class VinXmlParser {
  /// Parse an (possibly incomplete) XML buffer into a [VinResponse].
  static VinResponse parse(String xmlBuffer) {
    return VinResponse(
      subject: _extractTag(xmlBuffer, 'subject'),
      content: _extractContent(xmlBuffer),
      hint: _extractTag(xmlBuffer, 'hint'),
      steps: _extractSteps(xmlBuffer),
      question: _extractQuestion(xmlBuffer),
      followups: _extractFollowups(xmlBuffer),
      complete: xmlBuffer.contains('</response>'),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String? _extractTag(String xml, String tag) {
    final re = RegExp('<$tag[^>]*>(.*?)</$tag>', dotAll: true);
    final m = re.firstMatch(xml);
    return m?.group(1)?.trim();
  }

  /// Extracts <content> even during streaming (before </content> arrives).
  static String _extractContent(String xml) {
    const open = '<content>';
    final start = xml.indexOf(open);
    if (start == -1) return '';
    final contentStart = start + open.length;
    final closeIdx = xml.indexOf('</content>');
    if (closeIdx != -1) {
      return xml.substring(contentStart, closeIdx).trim();
    }
    // Streaming: strip any incomplete tag at the end
    final partial = xml.substring(contentStart);
    return partial.replaceAll(RegExp(r'<[^>]*$'), '').trim();
  }

  static List<VinStep> _extractSteps(String xml) {
    final stepsRe = RegExp(r'<steps>(.*?)</steps>', dotAll: true);
    final stepsMatch = stepsRe.firstMatch(xml);
    if (stepsMatch == null) return [];
    final inner = stepsMatch.group(1)!;
    final stepRe = RegExp(r'<step number="(\d+)">(.*?)</step>', dotAll: true);
    return stepRe.allMatches(inner).map((m) {
      return VinStep(
        number: int.tryParse(m.group(1)!) ?? 0,
        text: m.group(2)!.trim(),
      );
    }).toList();
  }

  static VinQuestion? _extractQuestion(String xml) {
    final qRe = RegExp(r'<question>(.*?)</question>', dotAll: true);
    final qMatch = qRe.firstMatch(xml);
    if (qMatch == null) return null;
    final inner = qMatch.group(1)!;
    final optRe = RegExp(r'<option correct="(true|false)">(.*?)</option>', dotAll: true);
    final options = optRe.allMatches(inner).toList();
    if (options.isEmpty) return null;
    // Question text = inner with all <option> tags removed
    final questionText = inner
        .replaceAll(RegExp(r'<option.*?</option>', dotAll: true), '')
        .trim();
    return VinQuestion(
      text: questionText,
      options: List.generate(options.length, (i) {
        final m = options[i];
        return VinOption(
          id: String.fromCharCode(65 + i), // A, B, C, D
          text: m.group(2)!.trim(),
          correct: m.group(1) == 'true',
        );
      }),
    );
  }

  static List<String> _extractFollowups(String xml) {
    final fuRe = RegExp(r'<followups>(.*?)</followups>', dotAll: true);
    final fuMatch = fuRe.firstMatch(xml);
    if (fuMatch == null) return [];
    final inner = fuMatch.group(1)!;
    final itemRe = RegExp(r'<followup>(.*?)</followup>', dotAll: true);
    return itemRe.allMatches(inner).map((m) => m.group(1)!.trim()).toList();
  }

  /// Strip HTML-like tags (e.g. <b>) from content for plain-text display.
  static String stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]+>'), '').trim();
}

// ── Data classes ──────────────────────────────────────────────────────────────

class VinResponse {
  final String? subject;
  final String content;
  final String? hint;
  final List<VinStep> steps;
  final VinQuestion? question;
  final List<String> followups;
  final bool complete;

  const VinResponse({
    this.subject,
    required this.content,
    this.hint,
    required this.steps,
    this.question,
    required this.followups,
    required this.complete,
  });

  bool get hasContent => content.isNotEmpty;
}

class VinStep {
  final int number;
  final String text;
  const VinStep({required this.number, required this.text});
}

class VinQuestion {
  final String text;
  final List<VinOption> options;
  const VinQuestion({required this.text, required this.options});
}

class VinOption {
  final String id; // A, B, C, D
  final String text;
  final bool correct;
  const VinOption({required this.id, required this.text, required this.correct});
}
