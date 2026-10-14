class Survey {
  final int id;
  final String title;
  final String description;
  final bool isActive;
  final List<SurveyQuestion> questions;
  final bool answered;
  final DateTime? answeredAt;
  final List<SurveyAnswer> answers;

  const Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
    required this.questions,
    required this.answered,
    required this.answeredAt,
    required this.answers,
  });

  factory Survey.fromJson(Map<String, dynamic> json) => Survey(
        id: int.parse(json['id'].toString()),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        isActive: _bool(json['is_active']),
        questions: (json['questions'] as List? ?? [])
            .map((item) =>
                SurveyQuestion.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        answered: _bool(json['answered']),
        answeredAt: DateTime.tryParse(json['answered_at']?.toString() ?? ''),
        answers: (json['answers'] as List? ?? [])
            .map((item) =>
                SurveyAnswer.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );

  SurveyAnswer? answerFor(String questionId) {
    for (final answer in answers) {
      if (answer.questionId == questionId) return answer;
    }
    return null;
  }

  static bool _bool(dynamic value) =>
      value == true || value == 1 || value == '1';
}

class SurveyQuestion {
  final String id;
  final String text;
  final List<String> options;
  final bool allowOther;

  const SurveyQuestion(
      {required this.id,
      required this.text,
      required this.options,
      required this.allowOther});

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) => SurveyQuestion(
        id: json['id'].toString(),
        text: json['text']?.toString() ?? '',
        options: (json['options'] as List? ?? [])
            .map((item) => item.toString())
            .toList(),
        allowOther: Survey._bool(json['allow_other']),
      );

  String answerLabel(SurveyAnswer? answer) {
    if (answer == null) return 'Sin respuesta';
    if (answer.option == 'other') return 'Otros: ${answer.otherText ?? ''}';
    final index = int.tryParse(answer.option);
    return index != null && index >= 0 && index < options.length
        ? options[index]
        : 'Sin respuesta';
  }
}

class SurveyAnswer {
  final String questionId;
  final String option;
  final String? otherText;

  const SurveyAnswer(
      {required this.questionId, required this.option, this.otherText});

  factory SurveyAnswer.fromJson(Map<String, dynamic> json) => SurveyAnswer(
        questionId: json['question_id'].toString(),
        option: json['option'].toString(),
        otherText: json['other_text']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'option': option,
        'other_text': option == 'other' ? otherText?.trim() : null,
      };
}
