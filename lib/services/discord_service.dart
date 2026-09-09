import 'dart:convert';
import 'package:http/http.dart' as http;

class DiscordService {
  // TODO: paste your Discord webhook URL here
  static const String webhookUrl = 'https://discord.com/api/webhooks/1545426568912830545/umBwsPzvg-Q3rkjI1kUNz6ebEtBNoT61Pc_1EYCDq04dPsbbqJEG8Ub5MqkOd03qqwLv';

  static Future<void> sendNewRequestAlert({
    required String chassisNumber,
    required String userId,
    required String userName,
  }) async {
    final time = DateTime.now();
    final formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    final content = '🚨 **New Auction Sheet Request!**\n'
        '• Chassis: `$chassisNumber`\n'
        '• Name: `$userName`\n'
        '• Time: $formattedTime';

    try {
      await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      );
    } catch (e) {
      // fail silently on the UI, log for yourself
      // ignore: avoid_print
      print('Discord webhook failed: $e');
    }
  }
}