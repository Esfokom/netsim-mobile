import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/network_scenario.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';

/// Widget for editing scenario metadata (title, description, difficulty)
class ScenarioPropertiesEditor extends ConsumerStatefulWidget {
  const ScenarioPropertiesEditor({super.key});

  @override
  ConsumerState<ScenarioPropertiesEditor> createState() =>
      _ScenarioPropertiesEditorState();
}

class _ScenarioPropertiesEditorState
    extends ConsumerState<ScenarioPropertiesEditor> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  String _pendingTitle = '';
  String _pendingDescription = '';
  bool _isTitleEditing = false;
  bool _isDescriptionEditing = false;

  @override
  void initState() {
    super.initState();
    final scenario = ref.read(scenarioProvider).scenario;
    _titleController = TextEditingController(text: scenario.title);
    _descriptionController = TextEditingController(text: scenario.description);
    _pendingTitle = scenario.title;
    _pendingDescription = scenario.description;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scenario = ref.watch(scenarioProvider).scenario;

    // Update controllers if scenario changes externally
    if (!_isTitleEditing && _titleController.text != scenario.title) {
      _titleController.text = scenario.title;
      _pendingTitle = scenario.title;
    }
    if (!_isDescriptionEditing &&
        _descriptionController.text != scenario.description) {
      _descriptionController.text = scenario.description;
      _pendingDescription = scenario.description;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with validation
          Text(
            'Title',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter scenario title',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    errorText: _isTitleEditing && _pendingTitle.trim().isEmpty
                        ? 'Title cannot be empty'
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _pendingTitle = value;
                      _isTitleEditing = true;
                    });
                  },
                ),
              ),
              if (_isTitleEditing) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _pendingTitle.trim().isEmpty
                      ? null
                      : () {
                          ref
                              .read(scenarioProvider.notifier)
                              .updateMetadata(title: _pendingTitle.trim());
                          setState(() => _isTitleEditing = false);
                        },
                  tooltip: 'Accept',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _titleController.text = scenario.title;
                      _pendingTitle = scenario.title;
                      _isTitleEditing = false;
                    });
                  },
                  tooltip: 'Cancel',
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Description with validation
          Text(
            'Description',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Enter scenario description',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText:
                      _isDescriptionEditing &&
                          _pendingDescription.trim().isEmpty
                      ? 'Description cannot be empty'
                      : null,
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _pendingDescription = value;
                    _isDescriptionEditing = true;
                  });
                },
              ),
              if (_isDescriptionEditing) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Cancel'),
                      onPressed: () {
                        setState(() {
                          _descriptionController.text = scenario.description;
                          _pendingDescription = scenario.description;
                          _isDescriptionEditing = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      onPressed: _pendingDescription.trim().isEmpty
                          ? null
                          : () {
                              ref
                                  .read(scenarioProvider.notifier)
                                  .updateMetadata(
                                    description: _pendingDescription.trim(),
                                  );
                              setState(() => _isDescriptionEditing = false);
                            },
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Difficulty with icon buttons
          Text(
            'Difficulty',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: ScenarioDifficulty.values.map((difficulty) {
              final isSelected = scenario.difficulty == difficulty;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _DifficultyButton(
                    difficulty: difficulty,
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(scenarioProvider.notifier)
                          .updateMetadata(difficulty: difficulty);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Last Modified (read-only)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Last Modified: ${_formatDate(scenario.lastModified ?? DateTime.now())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      }
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Difficulty button widget
class _DifficultyButton extends StatelessWidget {
  final ScenarioDifficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getDifficultyColor(difficulty);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getDifficultyIcon(difficulty),
              color: isSelected ? color : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              difficulty.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(ScenarioDifficulty difficulty) {
    switch (difficulty) {
      case ScenarioDifficulty.easy:
        return Colors.green;
      case ScenarioDifficulty.medium:
        return Colors.orange;
      case ScenarioDifficulty.hard:
        return Colors.red;
    }
  }

  IconData _getDifficultyIcon(ScenarioDifficulty difficulty) {
    switch (difficulty) {
      case ScenarioDifficulty.easy:
        return Icons.sentiment_satisfied;
      case ScenarioDifficulty.medium:
        return Icons.sentiment_neutral;
      case ScenarioDifficulty.hard:
        return Icons.sentiment_very_dissatisfied;
    }
  }
}
