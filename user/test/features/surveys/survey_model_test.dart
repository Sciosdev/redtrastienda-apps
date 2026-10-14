import 'package:flutter_sixvalley_ecommerce/features/surveys/domain/models/survey_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses pending surveys with nullable response fields', () {
    final survey = Survey.fromJson({
      'id': 5,
      'title': 'Tu tienda',
      'description': null,
      'is_active': true,
      'questions': [
        {
          'id': 'q1',
          'text': '¿Qué vendes?',
          'options': ['Abarrotes', 'Bebidas'],
          'allow_other': true,
        }
      ],
      'answered': false,
      'answered_at': null,
      'answers': null,
    });

    expect(survey.id, 5);
    expect(survey.description, isEmpty);
    expect(survey.answered, isFalse);
    expect(survey.answers, isEmpty);
    expect(survey.questions.single.allowOther, isTrue);
  });

  test('matches saved responses by question and displays Other text', () {
    final survey = Survey.fromJson({
      'id': '5',
      'title': 'Tu tienda',
      'description': '',
      'is_active': 1,
      'questions': [
        {
          'id': 'q1',
          'text': '¿Qué vendes?',
          'options': ['Abarrotes', 'Bebidas'],
          'allow_other': 1
        },
        {
          'id': 'q2',
          'text': '¿Qué necesitas?',
          'options': ['Surtido'],
          'allow_other': true
        },
      ],
      'answered': true,
      'answered_at': '2026-10-14T12:00:00Z',
      'answers': [
        {
          'question_id': 'q2',
          'option': 'other',
          'other_text': 'Productos locales'
        },
        {'question_id': 'q1', 'option': '1', 'other_text': null},
      ],
    });

    expect(
        survey.questions.first.answerLabel(survey.answerFor('q1')), 'Bebidas');
    expect(survey.questions.last.answerLabel(survey.answerFor('q2')),
        'Otros: Productos locales');
    expect(survey.answeredAt, isNotNull);
  });

  test('serializes only the active option and trims Other response', () {
    expect(
        const SurveyAnswer(
                questionId: 'q1', option: 'other', otherText: '  Locales  ')
            .toJson(),
        {
          'question_id': 'q1',
          'option': 'other',
          'other_text': 'Locales',
        });
    expect(
        const SurveyAnswer(
                questionId: 'q1', option: '0', otherText: 'Previous text')
            .toJson(),
        {
          'question_id': 'q1',
          'option': '0',
          'other_text': null,
        });
  });
}
