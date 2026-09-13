/// ML initialization and model download screen.
///
/// Shown on first launch (or after a manifest version bump) to download
/// on-device ML models from CDN and initialize the ONNX inference sessions
/// and ObjectBox vector store.
///
/// Navigates to `/home` automatically on successful completion.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';

import 'model_download_manager.dart';
import '../../providers/engine_providers.dart';

// ─── Init Step Definitions ────────────────────────────────────────────────────

enum _InitStep {
  checkCache,
  downloadModels,
  openDatabase,
  loadOcr,
  loadEmbedding,
  done;

  String get label {
    switch (this) {
      case _InitStep.checkCache:
        return 'Checking cached models…';
      case _InitStep.downloadModels:
        return 'Downloading AI models…';
      case _InitStep.openDatabase:
        return 'Opening local memory store…';
      case _InitStep.loadOcr:
        return 'Loading OCR engine…';
      case _InitStep.loadEmbedding:
        return 'Loading embedding engine…';
      case _InitStep.done:
        return 'Memory engine ready!';
    }
  }

  String get icon {
    switch (this) {
      case _InitStep.checkCache:
        return '📦';
      case _InitStep.downloadModels:
        return '⬇️';
      case _InitStep.openDatabase:
        return '🗄️';
      case _InitStep.loadOcr:
        return '👁️';
      case _InitStep.loadEmbedding:
        return '🧠';
      case _InitStep.done:
        return '✅';
    }
  }
}

// ─── State ────────────────────────────────────────────────────────────────────

class _MlInitState {
  final _InitStep currentStep;
  final double overallProgress; // 0.0 – 1.0
  final String? downloadingAsset;
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;
  final bool isComplete;

  const _MlInitState({
    this.currentStep = _InitStep.checkCache,
    this.overallProgress = 0.0,
    this.downloadingAsset,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.isComplete = false,
  });

  _MlInitState copyWith({
    _InitStep? currentStep,
    double? overallProgress,
    String? downloadingAsset,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
    bool? isComplete,
  }) {
    return _MlInitState(
      currentStep: currentStep ?? this.currentStep,
      overallProgress: overallProgress ?? this.overallProgress,
      downloadingAsset: downloadingAsset ?? this.downloadingAsset,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

/// First-launch ML initialization screen.
///
/// Orchestrates the full pipeline:
/// 1. Checks if models are already cached (skip download if so).
/// 2. Downloads missing models from GitHub Releases CDN.
/// 3. Opens the ObjectBox vector store.
/// 4. Initializes the OCR engine ONNX sessions.
/// 5. Initializes the CLIP embedding engine ONNX sessions.
/// 6. Navigates to `/home`.
class MlInitScreen extends ConsumerStatefulWidget {
  const MlInitScreen({super.key});

  @override
  ConsumerState<MlInitScreen> createState() => _MlInitScreenState();
}

class _MlInitScreenState extends ConsumerState<MlInitScreen>
    with SingleTickerProviderStateMixin {
  _MlInitState _initState = const _MlInitState();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Kick off initialization after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _runInit());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Init Pipeline ────────────────────────────────────────────────────────

  Future<void> _runInit() async {
    try {
      // ── Step 1: Check cache ──────────────────────────────────────────────
      _setStep(_InitStep.checkCache, 0.05);
      final manager = ModelDownloadManager();
      final ready = await manager.areModelsReady();

      // ── Step 2: Download models (skip if cached) ─────────────────────────
      if (!ready) {
        _setStep(_InitStep.downloadModels, 0.10);

        // Calculate total download size for normalised progress
        final totalSize = ModelManifest.assets
            .fold<int>(0, (sum, a) => sum + a.sizeBytes);

        int downloadedSoFar = 0;

        await manager.downloadAllIfNeeded(
          onProgress: (assetName, received, total) {
            downloadedSoFar = (downloadedSoFar + received).clamp(0, totalSize);
            final dlProgress = downloadedSoFar / totalSize;

            if (mounted) {
              setState(() {
                _initState = _initState.copyWith(
                  downloadingAsset: assetName,
                  downloadedBytes: received,
                  totalBytes: total,
                  overallProgress: 0.10 + (dlProgress * 0.50),
                );
              });
            }
          },
        );
      } else {
        _setStep(_InitStep.downloadModels, 0.60);
      }

      // ── Step 3: Open ObjectBox store ─────────────────────────────────────
      _setStep(_InitStep.openDatabase, 0.65);
      await ref.read(objectBoxStoreProvider.future);

      // ── Step 4: Initialize OCR engine ────────────────────────────────────
      _setStep(_InitStep.loadOcr, 0.75);
      final paths = await manager.resolvedPaths();
      final ocrEngine = ref.read(onnxOcrEngineProvider(paths));
      await ocrEngine.initialize();

      // ── Step 5: Initialize embedding engine ──────────────────────────────
      _setStep(_InitStep.loadEmbedding, 0.88);
      final embeddingEngine = ref.read(onnxClipEngineProvider(paths));
      await embeddingEngine.initialize();

      // ── Step 6: Done ─────────────────────────────────────────────────────
      _setStep(_InitStep.done, 1.0);
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initState = _initState.copyWith(
            errorMessage: e.toString(),
          );
        });
      }
    }
  }

  void _setStep(_InitStep step, double progress) {
    if (mounted) {
      setState(() {
        _initState = _initState.copyWith(
          currentStep: step,
          overallProgress: progress,
        );
      });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? NeoColors.bgMainDark : NeoColors.bgMain;
    final fg = isDark ? NeoColors.textMainDark : NeoColors.textMain;
    final card = isDark ? NeoColors.bgCardDark : NeoColors.bgCard;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // ── Logo + Title ────────────────────────────────────────────
              _buildHeader(fg),

              const SizedBox(height: 48),

              // ── Main card ───────────────────────────────────────────────
              _buildMainCard(card, fg, isDark),

              const SizedBox(height: 24),

              // ── Error message ────────────────────────────────────────────
              if (_initState.errorMessage != null)
                _buildErrorCard(isDark),

              const Spacer(flex: 3),

              // ── Footer note ──────────────────────────────────────────────
              _buildFooterNote(fg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color fg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Neo-brutal logo tile
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: NeoColors.yellow,
            border: Border.all(color: NeoColors.black, width: 3),
            boxShadow: const [
              BoxShadow(
                color: NeoColors.black,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Center(
            child: Text('P', style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: NeoColors.black,
            )),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Setting up your\nmemory engine.',
          style: NeoTypography.displaySmall.copyWith(
            color: NeoColors.black,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Downloading AI models — this only happens once.',
          style: NeoTypography.bodyMedium.copyWith(
            color: NeoColors.gray600,
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard(Color card, Color fg, bool isDark) {
    final progress = _initState.overallProgress.clamp(0.0, 1.0);
    final step = _initState.currentStep;

    return Container(
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: NeoColors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: NeoColors.black,
            offset: Offset(5, 5),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step label row
          Row(
            children: [
              ScaleTransition(
                scale: _pulseAnim,
                child: Text(step.icon, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.label,
                  style: NeoTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: NeoTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: NeoColors.yellow,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Neo-brutal progress bar
          _NeoProgressBar(progress: progress),

          // Download detail line
          if (step == _InitStep.downloadModels &&
              _initState.downloadingAsset != null) ...[
            const SizedBox(height: 12),
            Text(
              '↳ ${_initState.downloadingAsset}  '
              '${_formatBytes(_initState.downloadedBytes)} / '
              '${_formatBytes(_initState.totalBytes)}',
              style: NeoTypography.bodySmall.copyWith(
                fontFamily: 'JetBrainsMono',
                color: NeoColors.gray400,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Step checklist
          ..._InitStep.values
              .where((s) => s != _InitStep.done)
              .map((s) => _buildStepRow(s, step, fg)),
        ],
      ),
    );
  }

  Widget _buildStepRow(_InitStep s, _InitStep current, Color fg) {
    final isDone = s.index < current.index;
    final isActive = s == current;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isDone
                  ? NeoColors.green
                  : isActive
                      ? NeoColors.yellow
                      : Colors.transparent,
              border: Border.all(color: NeoColors.black, width: 2),
            ),
            child: isDone
                ? const Icon(Icons.check, size: 12, color: NeoColors.black)
                : isActive
                    ? const SizedBox()
                    : null,
          ),
          const SizedBox(width: 10),
          Text(
            s.label,
            style: NeoTypography.bodySmall.copyWith(
              color: isDone
                  ? NeoColors.gray400
                  : isActive
                      ? fg
                      : NeoColors.gray400,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: NeoColors.error.withValues(alpha: 0.08),
        border: Border.all(color: NeoColors.error, width: 2),
        boxShadow: const [
          BoxShadow(
            color: NeoColors.error,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: NeoColors.error, size: 18),
              SizedBox(width: 8),
              Text(
                'INITIALIZATION FAILED',
                style: TextStyle(
                  color: NeoColors.error,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _initState.errorMessage ?? 'Unknown error',
            style: NeoTypography.bodySmall.copyWith(
              color: NeoColors.error,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _initState = const _MlInitState();
              });
              _runInit();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: NeoColors.error,
                border: Border.all(color: NeoColors.black, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: NeoColors.black,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Text(
                'RETRY',
                style: TextStyle(
                  color: NeoColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote(Color fg) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          color: NeoColors.cyan,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Models are cached locally. Your data never leaves your device.',
            style: NeoTypography.bodySmall.copyWith(color: NeoColors.gray400),
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// ─── Neo Progress Bar ─────────────────────────────────────────────────────────

class _NeoProgressBar extends StatelessWidget {
  final double progress;

  const _NeoProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(color: NeoColors.black, width: 2),
        color: NeoColors.gray100,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Track stripes
              Positioned.fill(
                child: CustomPaint(painter: _StripePainter()),
              ),
              // Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: constraints.maxWidth * progress,
                color: NeoColors.yellow,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeoColors.black.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 12.0;
    for (double x = 0; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
