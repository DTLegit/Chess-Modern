import 'package:flutter/material.dart';

class WelcomeDialog extends StatelessWidget {
  const WelcomeDialog({
    super.key,
    required this.onNewGame,
    required this.onSettings,
  });

  final VoidCallback onNewGame;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Welcome to Chess'),
      content: const SizedBox(
        width: 420,
        child: Text(
          'Pick how to play: a quick match against the AI, or a local two-player '
          'game. Tap a piece to select it, tap a destination to move.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSettings();
          },
          child: const Text('Settings'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onNewGame();
          },
          child: const Text('Start a game'),
        ),
      ],
    );
  }
}
