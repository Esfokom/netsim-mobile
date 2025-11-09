// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shadcn_ui/shadcn_ui.dart';
// import '../../../../core/utils/snackbar_helper.dart';
// import '../../data/models/scenario_model.dart';
// import '../../logic/scenarios_provider.dart';
// import '../providers/scenario_provider.dart';
//
// class EditScenarioModal extends ConsumerStatefulWidget {
//   final Scenario scenario;
//
//   const EditScenarioModal({super.key, required this.scenario});
//
//   @override
//   ConsumerState<EditScenarioModal> createState() => _EditScenarioModalState();
// }
//
// class _EditScenarioModalState extends ConsumerState<EditScenarioModal> {
//   late TextEditingController _descriptionController;
//   late TextEditingController _timeLimitController;
//   late String _selectedDifficulty;
//   bool _isSaving = false;
//
//   final List<String> _difficulties = ['easy', 'medium', 'hard'];
//
//   @override
//   void initState() {
//     super.initState();
//     _descriptionController = TextEditingController(
//       text: widget.scenario.metadata.description,
//     );
//     _timeLimitController = TextEditingController(
//       text: widget.scenario.timeLimit.toString(),
//     );
//     _selectedDifficulty = widget.scenario.difficulty;
//   }
//
//   @override
//   void dispose() {
//     _descriptionController.dispose();
//     _timeLimitController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _saveChanges() async {
//     final timeLimit = int.tryParse(_timeLimitController.text);
//     if (timeLimit == null || timeLimit <= 0) {
//       SnackBarHelper.showError(context, 'Time limit must be a positive number');
//       return;
//     }
//
//     setState(() => _isSaving = true);
//
//     try {
//       final updatedScenario = widget.scenario.copyWith(
//         difficulty: _selectedDifficulty,
//         timeLimit: timeLimit,
//         metadata: widget.scenario.metadata.copyWith(
//           description: _descriptionController.text.trim(),
//         ),
//       );
//
//       final dataSource = ref.read(scenarioDataSourceProvider);
//       await dataSource.updateScenario(updatedScenario);
//
//       ref.invalidate(scenariosProvider);
//
//       if (mounted) {
//         setState(() => _isSaving = false);
//         Navigator.of(
//           context,
//         ).pop({'scenario': updatedScenario, 'success': true});
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isSaving = false);
//         SnackBarHelper.showError(context, 'Failed to update scenario: $e');
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = ShadTheme.of(context);
//
//     return Container(
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).viewInsets.bottom,
//       ),
//       child: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Text(
//                 'Edit Scenario',
//                 style: theme.textTheme.h3,
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 24),
//               const Text('Description'),
//               const SizedBox(height: 8),
//               ShadInput(
//                 controller: _descriptionController,
//                 placeholder: const Text('Scenario description'),
//                 maxLines: 3,
//               ),
//               const SizedBox(height: 16),
//               const Text('Time Limit (seconds)'),
//               const SizedBox(height: 8),
//               ShadInput(
//                 controller: _timeLimitController,
//                 placeholder: const Text('Time limit'),
//                 keyboardType: TextInputType.number,
//               ),
//               const SizedBox(height: 16),
//               const Text('Difficulty'),
//               const SizedBox(height: 8),
//               ShadSelect<String>(
//                 placeholder: const Text('Select difficulty'),
//                 options: _difficulties
//                     .map(
//                       (d) => ShadOption(value: d, child: Text(d.toUpperCase())),
//                     )
//                     .toList(),
//                 selectedOptionBuilder: (context, value) {
//                   return Text(value.toUpperCase());
//                 },
//                 initialValue: _selectedDifficulty,
//                 onChanged: (value) {
//                   if (value != null) {
//                     setState(() => _selectedDifficulty = value);
//                   }
//                 },
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 children: [
//                   Expanded(
//                     child: ShadButton.outline(
//                       onPressed: _isSaving
//                           ? null
//                           : () => Navigator.of(context).pop(),
//                       child: const Text('Cancel'),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ShadButton(
//                       onPressed: _isSaving ? null : _saveChanges,
//                       child: _isSaving
//                           ? const SizedBox(
//                               height: 16,
//                               width: 16,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             )
//                           : const Text('Save'),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
