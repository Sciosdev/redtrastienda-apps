import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/surveys/domain/models/survey_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/surveys/domain/repositories/survey_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/surveys/screens/survey_detail_screen.dart';

class SurveysScreen extends StatefulWidget {
  final SurveyRepository? repository;
  const SurveysScreen({super.key, this.repository});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  late final SurveyRepository _repository;
  List<Survey> _surveys = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SurveyApiRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final surveys = await _repository.getSurveys();
      if (mounted) setState(() => _surveys = surveys);
    } catch (error) {
      if (mounted) {
        setState(() => _error = SurveyRequestException.from(error).message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Survey survey) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) =>
          SurveyDetailScreen(id: survey.id, repository: _repository),
    ));
    if (changed == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _surveys
        .where((survey) => !survey.answered && survey.isActive)
        .toList();
    final answered = _surveys.where((survey) => survey.answered).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Encuestas'), actions: [
        IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh)),
      ]),
      body: _loading && _surveys.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const Text(
                        'Tu opinión ayuda a ANPEC a conocer las necesidades de tu tienda.'),
                    const SizedBox(height: 16),
                    if (_loading) const LinearProgressIndicator(),
                    if (_error != null) ...[
                      Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                              onPressed: _loading ? null : _load,
                              child: const Text('Reintentar'))),
                    ],
                    _section('Pendientes', pending,
                        'No tienes encuestas pendientes.'),
                    const SizedBox(height: 24),
                    _section('Respondidas', answered,
                        'Aún no has respondido encuestas.'),
                  ]),
            ),
    );
  }

  Widget _section(String title, List<Survey> surveys, String emptyMessage) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title (${surveys.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (surveys.isEmpty) Text(emptyMessage),
          ...surveys.map((survey) => Card(
                child: ListTile(
                  leading: Icon(
                      survey.answered
                          ? Icons.task_alt
                          : Icons.assignment_outlined,
                      color: Theme.of(context).primaryColor),
                  title: Text(survey.title),
                  subtitle: Text(survey.answered
                      ? 'Respuesta enviada · Ver mis respuestas'
                      : '${survey.questions.length} ${survey.questions.length == 1 ? 'pregunta' : 'preguntas'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(survey),
                ),
              )),
        ],
      );
}
