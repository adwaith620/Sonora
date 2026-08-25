import 'package:flutter/material.dart';

class AlphabeticalScrollBar extends StatefulWidget {
  const AlphabeticalScrollBar({
    super.key,
    required this.letters,
    required this.onLetterTapped,
  });

  final List<String> letters;
  final void Function(String) onLetterTapped;

  @override
  State<AlphabeticalScrollBar> createState() => _AlphabeticalScrollBarState();
}

class _AlphabeticalScrollBarState extends State<AlphabeticalScrollBar> {
  int _selectedIndex = -1;

  void _handleDrag(Offset localPosition, double height) {
    if (widget.letters.isEmpty) return;

    final itemHeight = height / widget.letters.length;
    final index = (localPosition.dy / itemHeight).floor().clamp(
      0,
      widget.letters.length - 1,
    );

    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
      widget.onLetterTapped(widget.letters[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.letters.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onVerticalDragDown: (details) =>
              _handleDrag(details.localPosition, constraints.maxHeight),
          onVerticalDragUpdate: (details) =>
              _handleDrag(details.localPosition, constraints.maxHeight),
          onVerticalDragEnd: (_) => setState(() => _selectedIndex = -1),
          onVerticalDragCancel: () => setState(() => _selectedIndex = -1),
          child: Container(
            width: 24,
            color: Colors.transparent, // Capture gestures
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(widget.letters.length, (index) {
                final isSelected = index == _selectedIndex;
                return Text(
                  widget.letters[index],
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: isSelected ? 12 : 10,
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
