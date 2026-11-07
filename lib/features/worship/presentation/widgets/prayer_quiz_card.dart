import 'dart:math';

import 'package:flutter/material.dart';
import 'package:muslim/core/utils/arabic_digits.dart';

import '../../data/repositories/worship_learning_repository.dart';
import '../../data/worship_ui_strings.dart';

class PrayerQuizCard extends StatefulWidget {
  const PrayerQuizCard({super.key, this.lessonId = 'prayer'});

  final String lessonId;

  @override
  State<PrayerQuizCard> createState() => _PrayerQuizCardState();
}

class _PrayerQuizCardState extends State<PrayerQuizCard> {
  static const _questionCount = 6;
  bool get _isWudu => widget.lessonId == 'wudu';
  List<PrayerQuizQuestionData> get _questionBank =>
      _isWudu ? WorshipUiStrings.wuduQuizQuestions : WorshipUiStrings.quizQuestions;
  final _random = Random();
  final _repository = WorshipLearningRepository();
  late List<_QuizQuestion> _questions;
  List<String?> _answers = [];
  var _questionIndex = 0;
  var _score = 0;
  String? _selectedAnswer;
  var _finished = false;
  var _ready = false;
  Future<void> _persistTail = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _restoreQuiz();
  }

  Future<void> _restoreQuiz() async {
    final attempt = await _repository.quizAttempt(widget.lessonId);
    if (!mounted) return;
    if (attempt == null || !_restoreAttempt(attempt)) {
      _newQuiz();
      await _persist();
    }
    if (mounted) setState(() => _ready = true);
  }

  bool _restoreAttempt(Map<String, dynamic> attempt) {
    final rawQuestions = attempt['questions'];
    final rawAnswers = attempt['answers'];
    final rawIndex = attempt['questionIndex'];
    if (rawQuestions is! List || rawAnswers is! List || rawIndex is! int ||
        rawQuestions.length != _questionCount || rawAnswers.length != _questionCount) {
      return false;
    }
    final source = {for (final q in _questionBank) q.question: q};
    final restored = <_QuizQuestion>[];
    for (final raw in rawQuestions) {
      if (raw is! Map || raw['question'] is! String || raw['options'] is! List) return false;
      final data = source[raw['question']];
      final options = raw['options'];
      if (data == null || options.length != data.options.length ||
          options.any((option) => option is! String || !data.options.contains(option))) {
        return false;
      }
      restored.add(_QuizQuestion(question: data.question, options: options.cast<String>(),
          answer: data.answer, explanation: data.explanation));
    }
    final answers = <String?>[];
    for (var i = 0; i < rawAnswers.length; i++) {
      final answer = rawAnswers[i];
      if (answer != null && (answer is! String || !restored[i].options.contains(answer))) return false;
      answers.add(answer as String?);
    }
    if (rawIndex < 0 || rawIndex >= _questionCount) return false;
    final finished = attempt['finished'] == true;
    if (finished != answers.every((answer) => answer != null)) return false;
    _questions = restored;
    _answers = answers;
    _questionIndex = rawIndex;
    _score = [for (var i = 0; i < answers.length; i++) if (answers[i] == restored[i].answer) 1].length;
    _selectedAnswer = finished ? null : answers[_questionIndex];
    _finished = finished;
    return true;
  }

  Future<void> _persist() {
    final snapshot = <String, dynamic>{
      'questionIndex': _questionIndex,
      'finished': _finished,
      'questions': [for (final q in _questions) {'question': q.question, 'options': q.options}],
      'answers': _answers,
    };
    _persistTail = _persistTail.then((_) => _repository.saveQuizAttempt(snapshot, widget.lessonId));
    return _persistTail;
  }

  void _newQuiz() {
    final questions = [..._questionBank]..shuffle(_random);
    _questions = questions.take(_questionCount).map((question) {
      final options = [...question.options]..shuffle(_random);
      return _QuizQuestion(
        question: question.question,
        options: options,
        answer: question.answer,
        explanation: question.explanation,
      );
    }).toList();
    _questionIndex = 0;
    _answers = List<String?>.filled(_questions.length, null);
    _score = 0;
    _selectedAnswer = null;
    _finished = false;
  }

  void _answer(String answer) {
    if (_selectedAnswer != null) return;
    setState(() {
      _selectedAnswer = answer;
      _answers[_questionIndex] = answer;
      if (answer == _questions[_questionIndex].answer) _score++;
    });
    _persist();
  }

  void _next() {
    setState(() {
      if (_questionIndex == _questions.length - 1) {
        _finished = true;
      } else {
        _questionIndex++;
        _selectedAnswer = null;
      }
    });
    _persist();
  }

  void _restart() {
    setState(() {
      _newQuiz();
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (!_ready) return const Card(child: SizedBox(height: 120));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.quiz_rounded, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isWudu ? WorshipUiStrings.wuduQuizTitle : WorshipUiStrings.prayerQuizTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(_isWudu ? WorshipUiStrings.wuduQuizIntro : WorshipUiStrings.prayerQuizIntro,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_finished)
              _buildResults(theme)
            else
              _buildQuestion(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(ThemeData theme) {
    final colors = theme.colorScheme;
    final question = _questions[_questionIndex];
    final answered = _selectedAnswer != null;
    final correct = answered && _selectedAnswer == question.answer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          WorshipUiStrings.quizQuestionProgress(
            current: toArabicIndicDigits(_questionIndex + 1),
            total: toArabicIndicDigits(_questions.length),
          ),
          style: theme.textTheme.labelLarge?.copyWith(
              color: colors.primary, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: (_questionIndex + (answered ? 1 : 0)) / _questions.length,
            minHeight: 6,
            backgroundColor: colors.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 17),
        Text(question.question,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800, height: 1.5)),
        const SizedBox(height: 12),
        for (final option in question.options) ...[
          _AnswerOption(
            label: option,
            isEnabled: !answered,
            isCorrect: answered && option == question.answer,
            isSelected: option == _selectedAnswer,
            onTap: () => _answer(option),
          ),
          const SizedBox(height: 8),
        ],
        if (answered) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (correct ? colors.tertiaryContainer : colors.errorContainer)
                  .withValues(alpha: .72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  correct ? Icons.check_circle_rounded : Icons.info_rounded,
                  size: 19,
                  color: correct ? colors.onTertiaryContainer : colors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${correct ? WorshipUiStrings.quizCorrect : WorshipUiStrings.quizIncorrect} ${correct ? '' : question.explanation}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.5,
                      color: correct
                          ? colors.onTertiaryContainer
                          : colors.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _next,
            child: Text(_questionIndex == _questions.length - 1
                ? WorshipUiStrings.quizSeeResults
                : WorshipUiStrings.quizContinue),
          ),
        ],
      ],
    );
  }

  Widget _buildResults(ThemeData theme) {
    final colors = theme.colorScheme;
    final message = _score >= 5
        ? (_isWudu ? WorshipUiStrings.wuduQuizGreatMessage : WorshipUiStrings.quizGreatMessage)
        : _score >= 3
            ? WorshipUiStrings.quizGoodMessage
            : WorshipUiStrings.quizTryAgainMessage;
    return Column(
      children: [
        Icon(Icons.emoji_events_rounded, size: 54, color: colors.primary),
        const SizedBox(height: 6),
        Text(WorshipUiStrings.quizResultsTitle,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(
          WorshipUiStrings.quizScore(
            score: toArabicIndicDigits(_score),
            total: toArabicIndicDigits(_questions.length),
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 5),
        Text(message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _restart,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text(WorshipUiStrings.quizRestart),
        ),
      ],
    );
  }
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final String answer;
  final String explanation;
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.isEnabled,
    required this.isCorrect,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isEnabled;
  final bool isCorrect;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color borderColor = isCorrect
        ? colors.tertiary
        : isSelected
            ? colors.error
            : colors.outlineVariant;
    final Color background = isCorrect
        ? colors.tertiaryContainer.withValues(alpha: .55)
        : isSelected
            ? colors.errorContainer.withValues(alpha: .55)
            : colors.surface;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          alignment: AlignmentDirectional.centerStart,
          child: Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCorrect ? colors.onTertiaryContainer : null,
                  )),
        ),
      ),
    );
  }
}
