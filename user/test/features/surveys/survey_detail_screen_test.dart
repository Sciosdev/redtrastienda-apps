import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/surveys/domain/models/survey_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/surveys/domain/repositories/survey_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/surveys/screens/survey_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements SurveyRepository {
  bool answered = false;
  SurveyRequestException? submissionError;
  List<SurveyAnswer>? submittedAnswers;
  int submitCount = 0;

  Survey get survey => Survey(
        id: 1,
        title: 'Encuesta de prueba',
        description: '',
        isActive: true,
        questions: const [
          SurveyQuestion(
              id: 'q1',
              text: '¿Qué necesitas?',
              options: ['Surtido', 'Crédito'],
              allowOther: true)
        ],
        answered: answered,
        answeredAt: null,
        answers: answered
            ? const [
                SurveyAnswer(
                    questionId: 'q1',
                    option: 'other',
                    otherText: 'Productos locales')
              ]
            : [],
      );

  @override
  Future<Survey> getSurvey(int id) async => survey;
  @override
  Future<List<Survey>> getSurveys() async => [survey];
  @override
  Future<Survey> submit(int id, List<SurveyAnswer> answers) async {
    submitCount++;
    submittedAnswers = answers;
    if (submissionError != null) throw submissionError!;
    return survey;
  }
}

Future<void> _show(WidgetTester tester, _FakeRepository repository) async {
  await tester.pumpWidget(
      MaterialApp(home: SurveyDetailScreen(id: 1, repository: repository)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Other requires text and preserves it after a network failure',
      (tester) async {
    final repository = _FakeRepository()
      ..submissionError =
          const SurveyRequestException('Sin conexión. Inténtalo de nuevo.');
    await _show(tester, repository);
    await tester.tap(find.text('Otros'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enviar respuestas'));
    await tester.tap(find.text('Enviar respuestas'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu respuesta en Otros.'), findsOneWidget);
    expect(repository.submitCount, 0);

    await tester.enterText(
        find.byKey(const ValueKey('other-q1')), 'Productos locales');
    await tester.ensureVisible(find.text('Enviar respuestas'));
    await tester.tap(find.text('Enviar respuestas'));
    await tester.pumpAndSettle();
    expect(repository.submitCount, 1);
    expect(repository.submittedAnswers!.single.toJson(), {
      'question_id': 'q1',
      'option': 'other',
      'other_text': 'Productos locales',
    });
    expect(find.text('Productos locales'), findsOneWidget);
    expect(find.text('Sin conexión. Inténtalo de nuevo.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
  });

  testWidgets('unanswered questions prevent submission', (tester) async {
    final repository = _FakeRepository();
    await _show(tester, repository);
    await tester.tap(find.text('Enviar respuestas'));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona una respuesta.'), findsOneWidget);
    expect(repository.submitCount, 0);
  });

  testWidgets('answered survey shows saved response without editable inputs',
      (tester) async {
    final repository = _FakeRepository()..answered = true;
    await _show(tester, repository);
    expect(find.text('Otros: Productos locales'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(RadioListTile<String>), findsNothing);
    expect(find.text('Enviar respuestas'), findsNothing);
  });
}
