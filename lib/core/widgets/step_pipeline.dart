import 'package:flutter/material.dart';

import '../../data/models/workflow_step.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Horizontal pipeline of step pills.
/// Active step shimmers; completed steps show a check.
class StepPipeline extends StatefulWidget {
  const StepPipeline({
    super.key,
    required this.steps,
    required this.currentStepId,
    this.compact = false,
    this.showLabels = false,
    this.localeCode = 'en',
    this.onStepTap,
  });

  final List<WorkflowStep> steps;
  final String? currentStepId;
  final bool compact;
  final bool showLabels;
  final String localeCode;
  final void Function(WorkflowStep step)? onStepTap;

  @override
  State<StepPipeline> createState() => _StepPipelineState();
}

class _StepPipelineState extends State<StepPipeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.steps.indexWhere((s) => s.id == widget.currentStepId);
    final h = widget.compact ? 26.0 : 32.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < widget.steps.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: _StepBlock(
                  height: h,
                  state: _stateFor(i, idx, widget.steps[i]),
                  index: i + 1,
                  pulse: _ctrl,
                  onTap: widget.onStepTap == null
                      ? null
                      : () => widget.onStepTap!(widget.steps[i]),
                ),
              ),
            ],
          ],
        ),
        if (widget.showLabels) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < widget.steps.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.steps[i].nameFor(widget.localeCode),
                    textAlign: TextAlign.center,
                    style: AppType.caption.copyWith(
                      color: i == idx ? AppColors.ink : AppColors.muted,
                      fontWeight: i == idx ? FontWeight.w500 : FontWeight.w400,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  _StepState _stateFor(int i, int currentIdx, WorkflowStep s) {
    if (currentIdx < 0) return _StepState.pending;
    if (i < currentIdx) return _StepState.done;
    if (i == currentIdx) {
      return s.isComplete ? _StepState.done : _StepState.active;
    }
    return _StepState.pending;
  }
}

enum _StepState { pending, active, done }

class _StepBlock extends StatelessWidget {
  const _StepBlock({
    required this.height,
    required this.state,
    required this.index,
    required this.pulse,
    this.onTap,
  });

  final double height;
  final _StepState state;
  final int index;
  final Animation<double> pulse;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = switch (state) {
      _StepState.active => (bg: AppColors.accentInk, fg: Colors.white),
      _StepState.done => (bg: AppColors.accentSoft, fg: AppColors.accentInk),
      _StepState.pending => (bg: AppColors.bgDeep, fg: AppColors.muted),
    };

    final label = state == _StepState.done
        ? const Icon(Icons.check_rounded, size: 14, color: AppColors.accentInk)
        : Text(
            index.toString().padLeft(2, '0'),
            style: AppType.mono10.copyWith(
              color: colors.fg,
              fontSize: 9,
              letterSpacing: 0.54,
            ),
          );

    final block = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(
            height: height,
            color: colors.bg,
            alignment: Alignment.center,
            child: label,
          ),
          if (state == _StepState.active)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: pulse,
                builder: (_, __) => Transform.translate(
                  offset: Offset(pulse.value * 200 - 100, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white.withAlpha(46),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return block;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: block,
      ),
    );
  }
}
