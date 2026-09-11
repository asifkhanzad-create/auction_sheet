import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  /// Creates the request doc at requests/{chassisNumber}
  static Future<void> createRequest({
    required String chassisNumber,
    required String userId,
    required String userName,
  }) async {
    await _db.collection('requests').doc(chassisNumber).set({
      'chassisNumber': chassisNumber,
      'userId': userId,
      'userName': userName,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Live status stream (pending -> completed)
  static Stream<DocumentSnapshot<Map<String, dynamic>>> statusStream(
      String chassisNumber) {
    return _db.collection('requests').doc(chassisNumber).snapshots();
  }

  /// Stream of ALL requests, newest first — used by the admin dashboard.
  static Stream<QuerySnapshot<Map<String, dynamic>>> allRequestsStream() {
    return _db
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream of a single user's own requests, newest first — used by the
  /// customer app's "My Requests" history tab.
  static Stream<QuerySnapshot<Map<String, dynamic>>> myRequestsStream(
      String userId) {
    return _db
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Marks a request as completed — used by the admin panel.
  static Future<void> markCompleted(String chassisNumber) async {
    await _db.collection('requests').doc(chassisNumber).update({
      'status': 'completed',
    });
  }

    /// Marks a request as in_progress (admin has started sourcing) — used by the admin panel.
  static Future<void> markInProgress(String chassisNumber) async {
    await _db.collection('requests').doc(chassisNumber).update({
      'status': 'in_progress',
    });
  }

  /// Deletes a request doc and its entire chat subcollection.
  static Future<void> deleteRequest(String chassisNumber) async {
    final messagesRef = _db
        .collection('chats')
        .doc(chassisNumber)
        .collection('messages');
    final messages = await messagesRef.get();
    final batch = _db.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('chats').doc(chassisNumber));
    batch.delete(_db.collection('requests').doc(chassisNumber));
    await batch.commit();
  }

  /// Deletes multiple requests (and their chats) at once.
  static Future<void> deleteRequests(List<String> chassisNumbers) async {
    for (final chassis in chassisNumbers) {
      await deleteRequest(chassis);
    }
  }

  /// Live chat messages stream
  static Stream<QuerySnapshot<Map<String, dynamic>>> chatStream(
      String chassisNumber) {
    return _db
        .collection('chats')
        .doc(chassisNumber)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  /// Sends a plain text message (unchanged behavior). Also stamps
  /// lastCustomerMessageAt on the request doc when the customer sends —
  /// used by the admin dashboard's unread-message indicator, avoiding an
  /// extra subcollection query per row.
  static Future<void> sendMessage({
    required String chassisNumber,
    required String senderId,
    required String text,
  }) async {
    await _db
        .collection('chats')
        .doc(chassisNumber)
        .collection('messages')
        .add({
      'senderId': senderId,
      'type': 'text',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (senderId != 'admin') {
      await _db.collection('requests').doc(chassisNumber).update({
        'lastCustomerMessageAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Adds a file to the request's official "deliverables" list — shown in the
  /// dedicated report panel on the customer's screen, separate from chat.
  /// [fileType] should be "pdf" or "image".
  static Future<void> addDeliverable({
    required String chassisNumber,
    required String fileUrl,
    required String fileName,
    required String fileType,
  }) async {
    await _db.collection('requests').doc(chassisNumber).update({
      'deliverables': FieldValue.arrayUnion([
        {
          'fileUrl': fileUrl,
          'fileName': fileName,
          'fileType': fileType, // "pdf" | "image"
          // FieldValue.serverTimestamp() can't be used inside arrayUnion
          // items (Firestore restriction), so we use a client timestamp.
          // Fine here — this is just "when the admin uploaded it", shown
          // as a rough relative time, not something needing server-exact
          // precision.
          'sentAt': Timestamp.now(),
        }
      ]),
    });
  }

  /// Sends a file message (image or document) — used after a Cloudinary upload.
  /// [fileType] should be "image" or "file" (see CloudinaryUploadResult.displayType).
  /// Also stamps lastCustomerMessageAt on the request doc when the customer
  /// sends — used by the admin dashboard's unread-message indicator.
  static Future<void> sendFileMessage({
    required String chassisNumber,
    required String senderId,
    required String fileUrl,
    required String fileName,
    required String fileType,
  }) async {
    await _db
        .collection('chats')
        .doc(chassisNumber)
        .collection('messages')
        .add({
      'senderId': senderId,
      'type': 'file',
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType, // "image" | "file"
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (senderId != 'admin') {
      await _db.collection('requests').doc(chassisNumber).update({
        'lastCustomerMessageAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Marks a request's chat as read by the admin — called when the admin
  /// opens AdminChatScreen. Clears the unread indicator on the dashboard.
  static Future<void> markReadByAdmin(String chassisNumber) async {
    await _db.collection('requests').doc(chassisNumber).update({
      'lastAdminReadAt': FieldValue.serverTimestamp(),
    });
  }
}