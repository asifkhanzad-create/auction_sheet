class AuctionRequest {
  final String chassisNumber;
  final String userId;
  final DateTime createdAt;
  String status; // pending | completed

  AuctionRequest({
    required this.chassisNumber,
    required this.userId,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
        'chassisNumber': chassisNumber,
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };
}
