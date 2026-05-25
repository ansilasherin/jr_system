import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/applications_view_model.dart';

class McqExamPage extends StatelessWidget {
  const McqExamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ApplicationsViewModel>();
    final questions = vm.questions;

    return Scaffold(
      appBar: AppBar(title: const Text('MCQ Test')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            vm.selectedApplication?.jobTitle ?? 'Screening Test',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          ...questions.indexed.map((entry) {
            final index = entry.$1;
            final question = entry.$2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: .35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${question.question}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    ...question.options.map(
                      (option) => RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(option),
                        value: option,
                        groupValue: vm.answers[question.id],
                        onChanged:
                            vm.submitting
                                ? null
                                : (value) {
                                  if (value == null) return;
                                  vm.selectAnswer(question, value);
                                },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (vm.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                vm.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton.icon(
            onPressed:
                vm.submitting || vm.answers.length != questions.length
                    ? null
                    : () => _submit(context, vm),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label:
                vm.submitting
                    ? const Text('Submitting...')
                    : const Text('Submit MCQ'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, ApplicationsViewModel vm) async {
    final ok = await vm.submitMcq();
    if (!context.mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(vm.successMessage ?? 'MCQ submitted.')),
    );
    Navigator.of(context).pop();
  }
}
