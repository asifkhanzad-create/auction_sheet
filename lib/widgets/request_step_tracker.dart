import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A premium horizontal 3-step progress tracker matching the app's
/// purple/lilac theme. Steps: Request received -> Sourcing -> Sheet ready.
class RequestStepTracker extends StatelessWidget {
  final String status; // "pending" | "in_progress" | "completed"

  const RequestStepTracker({super.key, required this.status});

  int get _activeIndex {
    switch (status) {
      case 'completed':
        return 2;
      case 'in_progress':
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Request received', 'Sourcing sheet', 'Sheet ready'];
    final active = _activeIndex;
    const purple = AppColors.purple;
    final lilac = context.lilac;
    final dark = context.textPrimary;
    final connectorEmpty = context.border;
    final activeCircleBg = context.card;

    return Row(
      children: List.generate(labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          // connector line between step i~2 and i~2+1
          final leftStepIndex = (i - 1) ~/ 2;
          final connectorFilled = leftStepIndex < active;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                height: 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    color: connectorFilled ? purple : connectorEmpty,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isDone = stepIndex < active;
        final isActive = stepIndex == active;
        final isUpcoming = stepIndex > active;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: isActive ? 34 : 28,
              height: isActive ? 34 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? purple
                    : isActive
                        ? activeCircleBg
                        : lilac,
                border: isActive
                    ? Border.all(color: purple, width: 2.5)
                    : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: purple.withValues(alpha: 0.18),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : isActive
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: purple,
                            ),
                          )
                        : Text(
                            '${stepIndex + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFA9A4E0),
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 74,
              child: Text(
                labels[stepIndex],
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isUpcoming ? context.textSecondary : dark,
                  height: 1.2,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}