import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/surveys/domain/models/survey_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/surveys/domain/repositories/survey_repository.dart';

class SurveyDetailScreen extends StatefulWidget {
  final int id;
  final SurveyRepository repository;
  const SurveyDetailScreen(
      {super.key, required this.id, required this.repository});

  @override
  State<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends State<SurveyDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _options = {};
  final Map<String, TextEditingController> _otherControllers = {};
  Survey? _survey;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _otherControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final survey = await widget.repository.getSurvey(widget.id);
      if (!mounted) return;
      for (final question in survey.questions) {
        _otherControllers.putIfAbsent(question.id, TextEditingController.new);
      }
      setState(() => _survey = survey);
    } catch (error) {
      if (mounted) {
        setState(() => _error = SurveyRequestException.from(error).message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    final answers = _survey!.questions
        .map((question) => SurveyAnswer(
              questionId: question.id,
              option: _options[question.id]!,
              otherText: _otherControllers[question.id]?.text,
            ))
        .toList();
    try {
      await widget.repository.submit(widget.id, answers);
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Gracias. Tu respuesta fue enviada.'),
      ));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final requestError = SurveyRequestException.from(error);
      setState(() {
        _submitting = false;
        _error = requestError.message;
      });
      if (requestError.statusCode == 409) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(requestError.message)));
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final survey = _survey;
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(
            title: const Text('Encuesta'),
            leading: BackButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            )),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : survey == null
                ? Center(
                    child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error ?? 'No se pudo cargar la encuesta.',
                          textAlign: TextAlign.center),
                      TextButton(
                          onPressed: _load, child: const Text('Reintentar')),
                    ]),
                  ))
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(survey.title,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            if (survey.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(survey.description),
                            ],
                            const SizedBox(height: 16),
                            if (survey.answered) ...[
                              const Text(
                                  'Ya respondiste esta encuesta. Estas son tus respuestas.'),
                              const SizedBox(height: 16),
                            ] else if (!survey.isActive) ...[
                              const Text(
                                  'Esta encuesta ya no recibe respuestas.'),
                              const SizedBox(height: 16),
                            ],
                            for (var index = 0;
                                index < survey.questions.length;
                                index++)
                              _question(survey.questions[index], index, survey),
                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Text(_error!,
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error)),
                            ],
                            if (!survey.answered &&
                                survey.isActive &&
                                survey.questions.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              FilledButton(
                                  style: FilledButton.styleFrom(
                                      foregroundColor: Colors.white),
                                  onPressed: _submitting ? null : _submit,
                                  child: _submitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Text('Enviar respuestas')),
                              const SizedBox(height: 8),
                              const Text(
                                  'Puedes enviar una sola respuesta por encuesta.',
                                  textAlign: TextAlign.center),
                            ],
                            const SizedBox(height: 24),
                          ]),
                    ),
                  ),
      ),
    );
  }

  Widget _question(SurveyQuestion question, int index, Survey survey) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${index + 1}. ${question.text}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (survey.answered)
                  Text(question.answerLabel(survey.answerFor(question.id)))
                else if (survey.isActive) ...[
                  FormField<String>(
                    initialValue: _options[question.id],
                    validator: (value) =>
                        value == null ? 'Selecciona una respuesta.' : null,
                    builder: (field) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RadioGroup<String>(
                            groupValue: _options[question.id],
                            onChanged: (value) {
                              if (_submitting || value == null) return;
                              setState(() => _options[question.id] = value);
                              field.didChange(value);
                            },
                            child: Column(children: [
                              for (var option = 0;
                                  option < question.options.length;
                                  option++)
                                RadioListTile<String>(
                                  contentPadding: EdgeInsets.zero,
                                  value: '$option',
                                  title: Text(question.options[option]),
                                  enabled: !_submitting,
                                ),
                              if (question.allowOther)
                                RadioListTile<String>(
                                    contentPadding: EdgeInsets.zero,
                                    value: 'other',
                                    title: const Text('Otros'),
                                    enabled: !_submitting),
                            ]),
                          ),
                          if (field.hasError)
                            Text(field.errorText!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                        ]),
                  ),
                  if (_options[question.id] == 'other')
                    TextFormField(
                      key: ValueKey('other-${question.id}'),
                      controller: _otherControllers[question.id],
                      enabled: !_submitting,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                          labelText: 'Escribe tu respuesta',
                          border: OutlineInputBorder()),
                      minLines: 1,
                      maxLines: 4,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Escribe tu respuesta en Otros.'
                              : null,
                    ),
                ],
              ],
            )),
      );
}
