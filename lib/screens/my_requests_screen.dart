import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../services/app_auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stream_error_view.dart';
import 'request_detail_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  /// Whether this tab is the currently selected one in MainShell's
  /// IndexedStack. IndexedStack keeps this screen's state alive and never
  /// actually hides it geometrically (it just skips painting), so we can't
  /// detect tab switches via visibility/geometry — MainShell tells us
  /// directly instead.
  final bool isActive;

  const MyRequestsScreen({super.key, this.isActive = true});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieController;
  // Bumped to force the StreamBuilder to re-subscribe on retry — Firestore
  // streams close permanently on error rather than re-emitting, so simply
  // waiting doesn't recover; a fresh subscription is needed.
  int _retryKey = 0;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant MyRequestsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Replay each time this tab transitions from inactive -> active.
    if (widget.isActive && !oldWidget.isActive && _lottieController.duration != null) {
      _lottieController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final userId = AppUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Requests',
          style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary),
        ),
      ),
      body: userId == null
          ? const Center(child: Text('Not signed in.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey(_retryKey),
              stream: FirestoreService.myRequestsStream(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return StreamErrorView(
                    message: 'Couldn\'t load your requests.',
                    onRetry: () => setState(() => _retryKey++),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Align(
                    alignment: const Alignment(0, -0.3), // -1.0 is top, 0.0 is center, 1.0 is bottom
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 220,
                            height: 220,
                            child: Lottie.asset(
                              'assets/animations/empty_box3.json',
                              controller: _lottieController,
                              onLoaded: (composition) {
                                // Slow it down to ~1.5x its original
                                // duration for a calmer, less rushed feel.
                                _lottieController.duration =
                                    composition.duration * 1.5;
                                // Play once on first load.
                                if (_lottieController.value == 0) {
                                  _lottieController.forward();
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No requests yet. Submit a chassis number to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final chassis = (data['chassisNumber'] ?? '').toString();
                    final status = data['status'] ?? 'pending';
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final isCompleted = status == 'completed';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 0,
                      color: context.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: context.border),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isCompleted
                              ? Colors.green.withValues(alpha: 0.15)
                              : context.lilac,
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.hourglass_top_rounded,
                            color: isCompleted ? Colors.green : AppColors.purple,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          chassis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: context.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          createdAt != null ? _relativeTime(createdAt) : '',
                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                        ),
                        trailing: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withValues(alpha: 0.15)
                                : context.lilac,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isCompleted ? 'Completed' : 'Pending',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? Colors.green.shade400 : AppColors.purple,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RequestDetailScreen(chassisNumber: chassis),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}