class McqQuestion {
  const McqQuestion({
    required this.id,
    required this.question,
    required this.options,
  });

  final int id;
  final String question;
  final List<String> options;

  factory McqQuestion.fromJson(Map<String, dynamic> json) {
    return McqQuestion(
      id: json['id'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      options: List<String>.from(json['options'] as List? ?? const []),
    );
  }
}
