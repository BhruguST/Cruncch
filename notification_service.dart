import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  // Replace with your FCM server key from Firebase Console > Project Settings > Cloud Messaging
  final String _serverKey = 'YOUR_FCM_SERVER_KEY';

  Future<void> sendNotification(String to, String title, String body) async {
    if (_serverKey == 'YOUR_FCM_SERVER_KEY') {
      print('Error: FCM server key not set. Please update _serverKey in notification_service.dart.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'to': to,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'type': 'message',
          },
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully to $to: $title - $body');
      } else {
        print('Failed to send notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}