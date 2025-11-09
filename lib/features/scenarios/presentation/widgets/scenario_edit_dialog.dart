// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:netsim_mobile/features/scenarios/data/models/scenario_model.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shadcn_ui/shadcn_ui.dart';
// import '../providers/scenario_provider.dart';
// import '../../../../core/widgets/root_scaffold.dart';
//
// class ScenarioEditDialog {
//   Future<void> showEditDialog(BuildContext context, Scenario scenario) async {
//     final timeLimitController = TextEditingController(
//       text: scenario.timeLimit.toString(),
//     );
//     final descriptionController = TextEditingController(
//       text: scenario.metadata.description,
//     );
//     final formKey = GlobalKey<FormState>();
//
//     String selectedDifficulty = scenario.difficulty;
//     bool isSaving = false;
//
//     final result = await showModalBottomSheet<Map<String, dynamic>?>(
//       context: context,
//       isScrollControlled: true,
//       useSafeArea: true,
//       backgroundColor: Theme.of(context).colorScheme.surface,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (sheetContext) {
//         return Consumer(
//           builder: (consumerContext, ref, child) {
//             return StatefulBuilder(
//               builder: (statefulContext, setState) {
//                 final theme = Theme.of(statefulContext);
//                 Future<void> onSave() async {
//                   if (isSaving) return;
//                   if (!formKey.currentState!.validate()) return;
//
//                   setState(() => isSaving = true);
//                   try {
//                     final newTimeLimit = int.parse(
//                       timeLimitController.text.trim(),
//                     );
//                     final newDescription = descriptionController.text.trim();
//
//                     final updatedMetadata = scenario.metadata.copyWith(
//                       description: newDescription,
//                     );
//
//                     final updatedScenario = scenario.copyWith(
//                       difficulty: selectedDifficulty,
//                       timeLimit: newTimeLimit,
//                       metadata: updatedMetadata,
//                     );
//
//                     final notifier = ref.read(
//                       scenarioNotifierProvider.notifier,
//                     );
//                     await notifier.updateScenario(updatedScenario);
//
//                     if (!statefulContext.mounted) return;
//                     if (Navigator.of(statefulContext).canPop()) {
//                       Navigator.of(statefulContext).pop({
//                         'success': true,
//                         'message': 'Scenario updated successfully',
//                       });
//                     }
//                   } catch (e) {
//                     if (!statefulContext.mounted) return;
//                     if (Navigator.of(statefulContext).canPop()) {
//                       Navigator.of(statefulContext).pop({
//                         'success': false,
//                         'message': 'Failed to update scenario: $e',
//                       });
//                     }
//                   } finally {
//                     if (statefulContext.mounted) {
//                       setState(() => isSaving = false);
//                     }
//                   }
//                 }
//
//                 Widget difficultyChips() {
//                   final options = const [
//                     ('easy', 'Easy'),
//                     ('medium', 'Medium'),
//                     ('hard', 'Hard'),
//                   ];
//
//                   Color chipColor(String value, ThemeData theme) {
//                     switch (value) {
//                       case 'easy':
//                         return Colors.green;
//                       case 'medium':
//                         return Colors.amber;
//                       case 'hard':
//                         return Colors.red;
//                       default:
//                         return theme.colorScheme.primary;
//                     }
//                   }
//
//                   return Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: [
//                       for (final (value, label) in options)
//                         ChoiceChip(
//                           label: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 value == 'easy'
//                                     ? Icons.sentiment_satisfied_alt
//                                     : value == 'medium'
//                                     ? Icons.swap_horiz
//                                     : Icons.whatshot,
//                                 size: 16,
//                               ),
//                               const SizedBox(width: 6),
//                               Text(label),
//                             ],
//                           ),
//                           selected: selectedDifficulty == value,
//                           selectedColor: chipColor(
//                             value,
//                             theme,
//                           ).withValues(alpha: 0.15),
//                           backgroundColor:
//                               theme.colorScheme.surfaceContainerHighest,
//                           shape: StadiumBorder(
//                             side: BorderSide(
//                               color: selectedDifficulty == value
//                                   ? chipColor(value, theme)
//                                   : theme.dividerColor,
//                             ),
//                           ),
//                           onSelected: (selected) {
//                             if (selected)
//                               setState(() => selectedDifficulty = value);
//                           },
//                         ),
//                     ],
//                   );
//                 }
//
//                 return SingleChildScrollView(
//                   child: Padding(
//                     padding: EdgeInsets.only(
//                       left: 16,
//                       right: 16,
//                       bottom:
//                           MediaQuery.of(statefulContext).viewInsets.bottom + 16,
//                       top: 8,
//                     ),
//                     child: Form(
//                       key: formKey,
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           const SizedBox(height: 6),
//                           Center(
//                             child: Container(
//                               width: 40,
//                               height: 4,
//                               decoration: BoxDecoration(
//                                 color: theme.dividerColor,
//                                 borderRadius: BorderRadius.circular(2),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           Text(
//                             'Edit Scenario',
//                             style: theme.textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.w600,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             scenario.name,
//                             style: theme.textTheme.bodyMedium?.copyWith(
//                               color: theme.textTheme.bodyMedium?.color
//                                   ?.withValues(alpha: 0.7),
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                           const SizedBox(height: 20),
//
//                           // Difficulty
//                           Text('Difficulty', style: theme.textTheme.labelLarge),
//                           const SizedBox(height: 8),
//                           difficultyChips(),
//
//                           const SizedBox(height: 16),
//                           // Time limit
//                           const SizedBox(height: 8),
//                           ShadInputFormField(
//                             controller: timeLimitController,
//                             description: Text("Enter time in seconds"),
//                             label: Text("Time Limit (seconds)"),
//                             keyboardType: TextInputType.number,
//                             inputFormatters: [
//                               FilteringTextInputFormatter.digitsOnly,
//                             ],
//                             validator: (v) {
//                               if (v.trim().isEmpty) {
//                                 return 'Please enter time limit';
//                               }
//                               final parsed = int.tryParse(v.trim());
//                               if (parsed == null || parsed <= 0) {
//                                 return 'Please enter a positive number';
//                               }
//                               return null;
//                             },
//                           ),
//
//                           const SizedBox(height: 16),
//                           // Description
//                           ShadInputFormField(
//                             controller: descriptionController,
//                             label: Text("Description"),
//                             description: Text("Briefly describe the scenario"),
//                             maxLines: 3,
//                             validator: (v) => v.trim().isEmpty
//                                 ? 'Please enter a description'
//                                 : null,
//                           ),
//
//                           const SizedBox(height: 20),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ShadButton.outline(
//                                   onPressed: isSaving
//                                       ? null
//                                       : () {
//                                           Navigator.of(
//                                             statefulContext,
//                                           ).pop(null);
//                                         },
//                                   child: const Text('Cancel'),
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: ShadButton(
//                                   onPressed: isSaving ? null : onSave,
//                                   child: isSaving
//                                       ? const SizedBox(
//                                           height: 18,
//                                           width: 18,
//                                           child: CircularProgressIndicator(
//                                             strokeWidth: 2,
//                                           ),
//                                         )
//                                       : const Text('Save'),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//
//     if (result != null && context.mounted) {
//       if (result['success'] == true) {
//         RootScaffold.showSuccessSnackBar(context, result['message'] as String);
//       } else {
//         RootScaffold.showErrorSnackBar(context, result['message'] as String);
//       }
//     }
//   }
// }
