import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../audio/sound_kind.dart';
import '../rust/api.dart' as rust;
import '../util/fen.dart';
import '../util/illegal_move.dart';

/// Pending promotion (board waits for the user to pick a piece type).
class PendingPromotion {
  const PendingPromotion({
    required this.from,
    required this.to,
    required this.color,
  });

  final String from;
  final String to;
  final rust.Color color;
}

/// Central game state, port of `legacy/svelte/lib/stores/gameStore.svelte.ts`.
class GameController extends ChangeNotifier {
  GameController();

  rust.GameSnapshot? _live;
  final List<rust.GameSnapshot> _snapshots = [];
  int? _scrubIndex;
  String? _selected;
  PendingPromotion? _pendingPromotion;
  rust.Color _orientation = rust.Color.w;
  bool _thinking = false;
  IllegalMoveCopy? _illegalMoveNotice;

  StreamSubscription<rust.BackendEvent>? _eventsSub;
  Timer? _clockTimer;
  DateTime? _clockLastTs;

  final _soundController = StreamController<SoundKind>.broadcast();

  // ----- read-only views -------------------------------------------------

  rust.GameSnapshot? get live => _live;
  List<rust.GameSnapshot> get snapshots => List.unmodifiable(_snapshots);
  int? get scrubIndex => _scrubIndex;
  String? get selected => _selected;
  PendingPromotion? get pendingPromotion => _pendingPromotion;
  rust.Color get orientation => _orientation;
  bool get thinking => _thinking;
  IllegalMoveCopy? get illegalMoveNotice => _illegalMoveNotice;
  bool get isAtLive => _scrubIndex == null;
  Stream<SoundKind> get sounds => _soundController.stream;

  rust.GameSnapshot? get view {
    if (_live == null) return null;
    if (_scrubIndex == null) return _live;
    final idx = _scrubIndex!;
    if (idx >= 0 && idx < _snapshots.length) return _snapshots[idx];
    return _live;
  }

  Map<String, rust.Piece> get board {
    final v = view;
    if (v == null) return const {};
    return parseFenBoard(v.fen);
  }

  rust.Move? get lastMove => view?.lastMove;

  List<String> get legalForSelected {
    final s = _selected;
    final l = _live;
    if (s == null || _scrubIndex != null || l == null) return const [];
    return l.legalMoves[s] ?? const [];
  }

  bool get inputLocked => _scrubIndex != null || _pendingPromotion != null;

  // ----- lifecycle -------------------------------------------------------

  Future<void> init() async {
    _eventsSub ??= rust.subscribeEvents().listen(_handleEvent);
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _clockTimer?.cancel();
    _soundController.close();
    super.dispose();
  }

  // ----- commands --------------------------------------------------------

  Future<void> newGame(rust.NewGameOpts opts) async {
    clearIllegalMoveNotice();
    _selected = null;
    _pendingPromotion = null;
    _scrubIndex = null;
    _thinking = false;
    final snap = await rust.newGame(opts: opts);
    _live = snap;
    _snapshots
      ..clear()
      ..add(snap);
    _orientation = snap.humanColor ?? rust.Color.w;
    _startClockTimerIfNeeded();
    notifyListeners();
    if (snap.mode == rust.GameMode.hva &&
        snap.humanColor != null &&
        snap.turn != snap.humanColor) {
      unawaited(_requestAi());
    }
  }

  Future<bool> tryMove(String from, String to) async {
    final l = _live;
    if (l == null || inputLocked) return false;
    final piece = parseFenBoard(l.fen)[from];
    if (piece == null || piece.color != l.turn) {
      _showIllegalMoveNotice(
        explainIllegalMove(live: l, board: parseFenBoard(l.fen), from: from, to: to),
      );
      return false;
    }
    final legal = l.legalMoves[from] ?? const [];
    if (!legal.contains(to)) {
      _showIllegalMoveNotice(
        explainIllegalMove(live: l, board: parseFenBoard(l.fen), from: from, to: to),
      );
      return false;
    }
    final isPawn = piece.kind == rust.PieceKind.p;
    final lastRank = piece.color == rust.Color.w ? '8' : '1';
    if (isPawn && to.endsWith(lastRank)) {
      _pendingPromotion =
          PendingPromotion(from: from, to: to, color: piece.color);
      notifyListeners();
      return true;
    }
    await _commitMove(from, to, null);
    return true;
  }

  Future<void> commitPromotion(rust.Promotion promo) async {
    final p = _pendingPromotion;
    _pendingPromotion = null;
    notifyListeners();
    if (p == null) return;
    await _commitMove(p.from, p.to, promo);
  }

  void cancelPromotion() {
    _pendingPromotion = null;
    notifyListeners();
  }

  Future<void> _commitMove(String from, String to, rust.Promotion? promo) async {
    final l = _live;
    if (l == null) return;
    try {
      await rust.makeMove(
        gameId: l.gameId,
        from: from,
        to: to,
        promotion: promo,
      );
    } on rust.ApiError {
      _showIllegalMoveNotice(moveRejectedCopy());
    }
  }

  Future<void> undo() async {
    final l = _live;
    if (l == null || _snapshots.length <= 1) return;
    try {
      final snap = await rust.undoMove(gameId: l.gameId);
      if (_snapshots.isNotEmpty) _snapshots.removeLast();
      _live = _snapshots.isNotEmpty ? _snapshots.last : snap;
      _scrubIndex = null;
      _selected = null;
      notifyListeners();
    } on rust.ApiError {
      // ignore
    }
  }

  Future<void> resign() async {
    final l = _live;
    if (l == null) return;
    try {
      await rust.resign(gameId: l.gameId);
    } on rust.ApiError {
      // ignore
    }
  }

  Future<String> exportPgn() async {
    final l = _live;
    if (l == null) return '';
    try {
      return await rust.exportPgn(gameId: l.gameId);
    } on rust.ApiError {
      return l.history.map((m) => m.san).join(' ');
    }
  }

  Future<void> loadPgn(String pgn) async {
    final snap = await rust.loadPgn(pgn: pgn);
    _live = snap;
    _snapshots
      ..clear()
      ..add(snap);
    _scrubIndex = null;
    _selected = null;
    _orientation = snap.humanColor ?? rust.Color.w;
    notifyListeners();
  }

  // ----- selection -------------------------------------------------------

  void select(String? sq) {
    if (inputLocked) return;
    if (sq == null) {
      _selected = null;
      notifyListeners();
      return;
    }
    if (_selected == sq) {
      _selected = null;
      notifyListeners();
      return;
    }
    final l = _live;
    if (_selected != null) {
      final legal = l?.legalMoves[_selected!] ?? const [];
      if (legal.contains(sq)) {
        final from = _selected!;
        _selected = null;
        notifyListeners();
        unawaited(tryMove(from, sq));
        return;
      }
      final piece = parseFenBoard(l?.fen ?? '')[_selected!];
      if (piece != null && l != null && piece.color == l.turn && sq != _selected) {
        final destPiece = parseFenBoard(l.fen)[sq];
        if (destPiece != null && destPiece.color == l.turn) {
          _selected = sq;
          notifyListeners();
          return;
        }
        final from = _selected!;
        _selected = null;
        notifyListeners();
        unawaited(tryMove(from, sq));
        return;
      }
    }
    final piece = parseFenBoard(l?.fen ?? '')[sq];
    if (piece != null && l != null && piece.color == l.turn) {
      _selected = sq;
    } else {
      _selected = null;
    }
    notifyListeners();
  }

  void deselect() {
    _selected = null;
    notifyListeners();
  }

  // ----- history scrub ---------------------------------------------------

  void scrubTo(int? index) {
    if (index == null) {
      _scrubIndex = null;
      notifyListeners();
      return;
    }
    var i = index;
    if (i < 0) i = 0;
    if (i >= _snapshots.length) i = _snapshots.length - 1;
    _scrubIndex = i == _snapshots.length - 1 ? null : i;
    _selected = null;
    notifyListeners();
  }

  void scrubStep(int delta) {
    final cur = _scrubIndex ?? _snapshots.length - 1;
    scrubTo(cur + delta);
  }

  void scrubLive() {
    _scrubIndex = null;
    notifyListeners();
  }

  // ----- orientation -----------------------------------------------------

  void flip() {
    _orientation = _orientation == rust.Color.w ? rust.Color.b : rust.Color.w;
    notifyListeners();
  }

  void setOrientation(rust.Color c) {
    _orientation = c;
    notifyListeners();
  }

  // ----- illegal move ----------------------------------------------------

  void _showIllegalMoveNotice(IllegalMoveCopy copy) {
    _illegalMoveNotice = copy;
    notifyListeners();
  }

  void clearIllegalMoveNotice() {
    _illegalMoveNotice = null;
    notifyListeners();
  }

  // ----- AI --------------------------------------------------------------

  Future<void> _requestAi() async {
    final l = _live;
    if (l == null) return;
    _thinking = true;
    notifyListeners();
    try {
      await rust.requestAiMove(gameId: l.gameId);
    } on rust.ApiError {
      _thinking = false;
      notifyListeners();
    }
  }

  // ----- event handling --------------------------------------------------

  void _handleEvent(rust.BackendEvent event) {
    if (event is rust.BackendEvent_MoveMade) {
      _onMoveEvent(event.field0);
    } else if (event is rust.BackendEvent_GameOver) {
      _onOverEvent(event.field0);
    } else if (event is rust.BackendEvent_ClockTick) {
      _onClockEvent(event.field0);
    }
    // ai-progress is informational; the active controller doesn't react.
  }

  void _onMoveEvent(rust.MoveMadeEvent e) {
    final l = _live;
    if (l == null || e.gameId != l.gameId) return;
    _thinking = false;
    _live = e.snapshot;
    _snapshots.add(e.snapshot);
    _selected = null;
    _scrubIndex = null;

    if (e.mv.isCastle) {
      _soundController.add(SoundKind.castle);
    } else if (e.mv.captured != null) {
      _soundController.add(SoundKind.capture);
    } else {
      _soundController.add(SoundKind.move);
    }
    if (e.mv.promotion != null) {
      _soundController.add(SoundKind.promote);
    }
    if (e.mv.isCheck && !e.mv.isMate) {
      _soundController.add(SoundKind.check);
    }
    _startClockTimerIfNeeded();
    notifyListeners();

    final s = e.snapshot;
    if (s.mode == rust.GameMode.hva &&
        s.status == rust.GameStatus.active &&
        s.humanColor != null &&
        s.turn != s.humanColor) {
      unawaited(_requestAi());
    }
  }

  void _onOverEvent(rust.GameOverEvent e) {
    final l = _live;
    if (l == null || e.gameId != l.gameId) return;
    _thinking = false;
    final updated = rust.GameSnapshot(
      gameId: l.gameId,
      fen: l.fen,
      turn: l.turn,
      inCheck: l.inCheck,
      status: e.reason,
      result: e.result,
      history: l.history,
      legalMoves: l.legalMoves,
      clock: l.clock,
      mode: l.mode,
      aiDifficulty: l.aiDifficulty,
      humanColor: l.humanColor,
      lastMove: l.lastMove,
    );
    _live = updated;
    if (_snapshots.isNotEmpty) {
      _snapshots[_snapshots.length - 1] = updated;
    }
    _soundController.add(SoundKind.end);
    _stopClockTimer();
    notifyListeners();
  }

  void _onClockEvent(rust.ClockTickEvent e) {
    final l = _live;
    if (l == null || e.gameId != l.gameId || l.clock == null) return;
    _live = rust.GameSnapshot(
      gameId: l.gameId,
      fen: l.fen,
      turn: l.turn,
      inCheck: l.inCheck,
      status: l.status,
      result: l.result,
      history: l.history,
      legalMoves: l.legalMoves,
      clock: rust.ClockState(
        whiteMs: e.whiteMs,
        blackMs: e.blackMs,
        active: e.active,
        paused: l.clock!.paused,
      ),
      mode: l.mode,
      aiDifficulty: l.aiDifficulty,
      humanColor: l.humanColor,
      lastMove: l.lastMove,
    );
    notifyListeners();
  }

  // ----- clock interpolation --------------------------------------------

  void _startClockTimerIfNeeded() {
    _stopClockTimer();
    if (_live?.clock == null) return;
    if (_live!.status != rust.GameStatus.active) return;
    _clockLastTs = DateTime.now();
    _clockTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) => _tickLocalClock());
  }

  void _stopClockTimer() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  void _tickLocalClock() {
    final l = _live;
    if (l == null || l.clock == null) return;
    final clock = l.clock!;
    if (clock.paused || clock.active == null) return;
    if (l.status != rust.GameStatus.active) {
      _stopClockTimer();
      return;
    }
    final now = DateTime.now();
    final deltaMs =
        math.max(0, now.difference(_clockLastTs ?? now).inMilliseconds);
    _clockLastTs = now;
    final whiteMs = clock.active == rust.Color.w
        ? BigInt.from(math.max(0, clock.whiteMs.toInt() - deltaMs))
        : clock.whiteMs;
    final blackMs = clock.active == rust.Color.b
        ? BigInt.from(math.max(0, clock.blackMs.toInt() - deltaMs))
        : clock.blackMs;
    _live = rust.GameSnapshot(
      gameId: l.gameId,
      fen: l.fen,
      turn: l.turn,
      inCheck: l.inCheck,
      status: l.status,
      result: l.result,
      history: l.history,
      legalMoves: l.legalMoves,
      clock: rust.ClockState(
        whiteMs: whiteMs,
        blackMs: blackMs,
        active: clock.active,
        paused: clock.paused,
      ),
      mode: l.mode,
      aiDifficulty: l.aiDifficulty,
      humanColor: l.humanColor,
      lastMove: l.lastMove,
    );
    notifyListeners();
  }
}

