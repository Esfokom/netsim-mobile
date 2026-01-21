import 'package:flutter/material.dart';

/// A compact, hideable bottom action bar that replaces the FAB speed dial.
/// Actions are displayed horizontally and can be collapsed/expanded with a slide gesture.
class CompactBottomActionBar extends StatefulWidget {
  /// List of action items to display
  final List<ActionBarItem> items;

  /// Whether the bar is initially expanded
  final bool initiallyExpanded;

  const CompactBottomActionBar({
    super.key,
    required this.items,
    this.initiallyExpanded = true,
  });

  @override
  State<CompactBottomActionBar> createState() => _CompactBottomActionBarState();
}

class _CompactBottomActionBarState extends State<CompactBottomActionBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (!_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Collapsed state - just show expand button
                  if (_slideAnimation.value > 0.5)
                    FadeTransition(
                      opacity: _slideAnimation,
                      child: _buildExpandButton(colorScheme),
                    ),

                  // Expanded state - show action bar
                  if (_slideAnimation.value < 1.0)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildActionBar(colorScheme),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExpandButton(ColorScheme colorScheme) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: colorScheme.primaryContainer,
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chevron_left,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                'Actions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(ColorScheme colorScheme) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe right to collapse
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          _toggleExpanded();
        }
      },
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(28),
        color: colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Action items
              ...widget.items.map(
                (item) => _ActionButton(item: item, colorScheme: colorScheme),
              ),

              // Collapse button
              const SizedBox(width: 4),
              _buildCollapseButton(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton(ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.chevron_right,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Individual action button in the action bar
class _ActionButton extends StatelessWidget {
  final ActionBarItem item;
  final ColorScheme colorScheme;

  const _ActionButton({required this.item, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: item.isHighlighted
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                Text(
                  item.shortLabel ?? _shortenLabel(item.label),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: item.isHighlighted
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _shortenLabel(String label) {
    // Shorten common labels
    final words = label.split(' ');
    if (words.length > 1) {
      return words.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join('');
    }
    return label.length > 6 ? '${label.substring(0, 5)}.' : label;
  }
}

/// Represents an action item in the bottom action bar
class ActionBarItem {
  final IconData icon;
  final String label;
  final String? shortLabel;
  final VoidCallback onTap;
  final bool isHighlighted;

  const ActionBarItem({
    required this.icon,
    required this.label,
    this.shortLabel,
    required this.onTap,
    this.isHighlighted = false,
  });
}
