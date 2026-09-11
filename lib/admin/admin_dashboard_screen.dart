import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../widgets/stream_error_view.dart';
import 'admin_auth_service.dart';
import 'admin_chat_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  bool _selectionMode = false;
  final Set<String> _selectedChassis = {};
  // Bumped to force the requests StreamBuilder to re-subscribe on retry —
  // Firestore streams close permanently on error rather than re-emitting.
  int _retryKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Exit selection mode when switching tabs to avoid confusing cross-tab selections.
      if (_selectionMode) _exitSelectionMode();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _enterSelectionMode(String chassis) {
    setState(() {
      _selectionMode = true;
      _selectedChassis.add(chassis);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedChassis.clear();
    });
  }

  void _toggleSelection(String chassis) {
    setState(() {
      if (_selectedChassis.contains(chassis)) {
        _selectedChassis.remove(chassis);
        if (_selectedChassis.isEmpty) _selectionMode = false;
      } else {
        _selectedChassis.add(chassis);
      }
    });
  }

  void _selectAll(List<String> visibleChassisNumbers) {
    setState(() {
      _selectedChassis
        ..clear()
        ..addAll(visibleChassisNumbers);
      _selectionMode = _selectedChassis.isNotEmpty;
    });
  }

  Future<void> _confirmAndDeleteSelected() async {
    final count = _selectedChassis.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count request${count == 1 ? '' : 's'}?'),
        content: const Text(
            'This permanently deletes the request and its full chat history. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final toDelete = _selectedChassis.toList();
    _exitSelectionMode();

    await FirestoreService.deleteRequests(toDelete);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $count request${count == 1 ? '' : 's'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.black87),
                onPressed: _exitSelectionMode,
              )
            : null,
        title: Text(
          _selectionMode ? '${_selectedChassis.length} selected' : 'Requests',
          style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w600),
        ),
        actions: _selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  tooltip: 'Delete selected',
                  onPressed: _selectedChassis.isEmpty ? null : _confirmAndDeleteSelected,
                ),
                const SizedBox(width: 8),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.black54),
                  onPressed: () => AdminAuthService.signOut(),
                  tooltip: 'Sign out',
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: Column(
        children: [
          if (!_selectionMode)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by chassis number...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F8),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey(_retryKey),
              stream: FirestoreService.allRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return StreamErrorView(
                    message: 'Couldn\'t load requests.',
                    onRetry: () => setState(() => _retryKey++),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs;

                bool _isUnread(Map<String, dynamic> data) {
                  final lastCustomerMsg =
                      (data['lastCustomerMessageAt'] as Timestamp?)?.toDate();
                  final lastAdminRead =
                      (data['lastAdminReadAt'] as Timestamp?)?.toDate();
                  return lastCustomerMsg != null &&
                      (lastAdminRead == null ||
                          lastCustomerMsg.isAfter(lastAdminRead));
                }

                final pendingUnreadCount = docs.where((doc) {
                  final data = doc.data();
                  final status = data['status'] ?? 'pending';
                  if (status != 'pending' && status != 'in_progress') return false;
                  return _isUnread(data);
                }).length;

                final completedUnreadCount = docs.where((doc) {
                  final data = doc.data();
                  if ((data['status'] ?? 'pending') != 'completed') return false;
                  return _isUnread(data);
                }).length;

                final allUnreadCount =
                    docs.where((doc) => _isUnread(doc.data())).length;

                return Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF6C63FF),
                      unselectedLabelColor: Colors.black45,
                      indicatorColor: const Color(0xFF6C63FF),
                      tabs: [
                        _tabWithBadge('Pending', pendingUnreadCount),
                        _tabWithBadge('Completed', completedUnreadCount),
                        _tabWithBadge('All', allUnreadCount),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // "Pending" tab now includes both fresh requests and ones
                          // actively being sourced — only fully completed ones move out.
                          _buildList(docs, filterStatuses: const ['pending', 'in_progress']),
                          _buildList(docs, filterStatuses: const ['completed']),
                          _buildList(docs, filterStatuses: null),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabWithBadge(String label, int unreadCount) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (unreadCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required List<String>? filterStatuses,
  }) {
    var filtered = docs.where((doc) {
      final data = doc.data();
      final chassis = (data['chassisNumber'] ?? '').toString().toLowerCase();
      final status = data['status'] ?? 'pending';

      if (filterStatuses != null && !filterStatuses.contains(status)) return false;
      if (_searchQuery.isNotEmpty && !chassis.contains(_searchQuery)) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No requests here yet.', style: TextStyle(color: Colors.black45)),
      );
    }

    final visibleChassisNumbers = filtered
        .map((d) => (d.data()['chassisNumber'] ?? '').toString())
        .toList();
    final allSelected = _selectionMode &&
        visibleChassisNumbers.isNotEmpty &&
        visibleChassisNumbers.every(_selectedChassis.contains);

    return Column(
      children: [
        if (_selectionMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => allSelected
                    ? _exitSelectionMode()
                    : _selectAll(visibleChassisNumbers),
                icon: Icon(
                  allSelected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18,
                ),
                label: Text(allSelected ? 'Deselect all' : 'Select all'),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final data = filtered[index].data();
              final chassis = (data['chassisNumber'] ?? '').toString();
              final userId = data['userId'] ?? '';
              final userName = data['userName'] ?? userId;
              final status = data['status'] ?? 'pending';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final isPending = status == 'pending';
              final isInProgress = status == 'in_progress';
              final isCompleted = status == 'completed';
              final isSelected = _selectedChassis.contains(chassis);

              // Unread if the customer's last message is newer than the
              // admin's last read time (or the admin has never opened it).
              final lastCustomerMsg =
                  (data['lastCustomerMessageAt'] as Timestamp?)?.toDate();
              final lastAdminRead =
                  (data['lastAdminReadAt'] as Timestamp?)?.toDate();
              final isUnread = lastCustomerMsg != null &&
                  (lastAdminRead == null || lastCustomerMsg.isAfter(lastAdminRead));

              // Per-status visuals
              final Color badgeBg;
              final Color badgeFg;
              final IconData leadingIcon;
              final String statusLabel;

              if (isCompleted) {
                badgeBg = Colors.green.shade50;
                badgeFg = Colors.green.shade700;
                leadingIcon = Icons.check_circle_rounded;
                statusLabel = 'Completed';
              } else if (isInProgress) {
                badgeBg = Colors.orange.shade50;
                badgeFg = Colors.orange.shade700;
                leadingIcon = Icons.bolt_rounded;
                statusLabel = 'Sourcing';
              } else {
                badgeBg = const Color(0xFFEDEBFF);
                badgeFg = const Color(0xFF6C63FF);
                leadingIcon = Icons.hourglass_top_rounded;
                statusLabel = 'Pending';
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 0,
                color: isSelected ? const Color(0xFFEDEBFF) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isSelected
                      ? const BorderSide(color: Color(0xFF6C63FF), width: 1.5)
                      : BorderSide.none,
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _selectionMode
                      ? Checkbox(
                          value: isSelected,
                          activeColor: const Color(0xFF6C63FF),
                          onChanged: (_) => _toggleSelection(chassis),
                        )
                      : Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              backgroundColor: badgeBg,
                              child: Icon(leadingIcon, color: badgeFg, size: 20),
                            ),
                            if (isUnread)
                              Positioned(
                                top: -1,
                                right: -1,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                  title: Text(
                    chassis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: Text(
                    '$userName · ${createdAt != null ? _relativeTime(createdAt) : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  trailing: _selectionMode
                      ? null
                      : Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: badgeFg,
                            ),
                          ),
                        ),
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelection(chassis);
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminChatScreen(
                          chassisNumber: chassis,
                          userId: userId,
                          userName: userName,
                          initialStatus: status,
                        ),
                      ),
                    );
                  },
                  onLongPress: () {
                    if (!_selectionMode) _enterSelectionMode(chassis);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}