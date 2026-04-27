import 'package:flutter/material.dart';

import '../../rust/api.dart' as rust;

class NewGameDialog extends StatefulWidget {
  const NewGameDialog({super.key});

  @override
  State<NewGameDialog> createState() => _NewGameDialogState();
}

class _NewGameDialogState extends State<NewGameDialog> {
  rust.GameMode _mode = rust.GameMode.hva;
  int _aiDifficulty = 3;
  rust.HumanColorChoice _humanColor = rust.HumanColorChoice.w;
  bool _withClock = false;
  int _initialMinutes = 5;
  int _incrementSeconds = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New game'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<rust.GameMode>(
                segments: const [
                  ButtonSegment(
                    value: rust.GameMode.hva,
                    label: Text('Vs. AI'),
                  ),
                  ButtonSegment(
                    value: rust.GameMode.hvh,
                    label: Text('Two players'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              if (_mode == rust.GameMode.hva) ...[
                const SizedBox(height: 16),
                Text('AI difficulty: $_aiDifficulty',
                    style: Theme.of(context).textTheme.bodyMedium),
                Slider(
                  value: _aiDifficulty.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_aiDifficulty',
                  onChanged: (v) =>
                      setState(() => _aiDifficulty = v.round()),
                ),
                const SizedBox(height: 8),
                const Text('Play as'),
                const SizedBox(height: 6),
                SegmentedButton<rust.HumanColorChoice>(
                  segments: const [
                    ButtonSegment(
                      value: rust.HumanColorChoice.w,
                      label: Text('White'),
                    ),
                    ButtonSegment(
                      value: rust.HumanColorChoice.random,
                      label: Text('Random'),
                    ),
                    ButtonSegment(
                      value: rust.HumanColorChoice.b,
                      label: Text('Black'),
                    ),
                  ],
                  selected: {_humanColor},
                  onSelectionChanged: (s) =>
                      setState(() => _humanColor = s.first),
                ),
              ],
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use a chess clock'),
                value: _withClock,
                onChanged: (v) => setState(() => _withClock = v),
              ),
              if (_withClock) ...[
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        label: 'Minutes',
                        value: _initialMinutes,
                        min: 1,
                        max: 180,
                        onChanged: (v) =>
                            setState(() => _initialMinutes = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberField(
                        label: 'Increment (s)',
                        value: _incrementSeconds,
                        min: 0,
                        max: 60,
                        onChanged: (v) =>
                            setState(() => _incrementSeconds = v),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_buildOpts()),
          child: const Text('Start'),
        ),
      ],
    );
  }

  rust.NewGameOpts _buildOpts() {
    return rust.NewGameOpts(
      mode: _mode,
      aiDifficulty: _mode == rust.GameMode.hva ? _aiDifficulty : null,
      humanColor: _mode == rust.GameMode.hva ? _humanColor : null,
      timeControl: _withClock
          ? rust.TimeControl(
              initialMs: BigInt.from(_initialMinutes * 60 * 1000),
              incrementMs: BigInt.from(_incrementSeconds * 1000),
            )
          : null,
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.value}');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (s) {
        final parsed = int.tryParse(s);
        if (parsed != null) {
          final clamped = parsed.clamp(widget.min, widget.max);
          widget.onChanged(clamped);
        }
      },
    );
  }
}
