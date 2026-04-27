import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ChessAboutDialog extends StatelessWidget {
  const ChessAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('About'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chess — a polished, native cross-platform chess game.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Built with Flutter for the UI and Rust for the engine + AI, '
              'connected through flutter_rust_bridge.',
            ),
            const SizedBox(height: 12),
            const Text(
              'AI uses a custom Rust minimax engine for difficulty 1–3, and '
              'Stockfish 17 for 4–10 on platforms where it is available '
              '(macOS, Windows, Linux desktop, and Android). On iOS the '
              'sandbox forbids spawning external binaries, so levels 4–10 '
              'transparently use the strongest custom-engine setting; '
              'gameplay is fully functional, but the engine is weaker than '
              'desktop Stockfish at high levels.',
            ),
            const SizedBox(height: 12),
            Text(
              defaultTargetPlatform == TargetPlatform.iOS
                  ? 'You are on iOS, which uses the custom Rust engine.'
                  : 'Stockfish is bundled with the desktop and Android builds.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
