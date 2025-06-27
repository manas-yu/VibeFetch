import 'package:url_launcher/url_launcher.dart';

class UrlLauncherHelper {
  static Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch $url');
    }
  }

  static Future<void> launchYouTube(String youtubeUrl) async {
    await launchURL(youtubeUrl);
  }

  static Future<void> launchSpotify(String spotifyUrl) async {
    await launchURL(spotifyUrl);
  }

  static Future<void> launchAppleMusic(String appleMusicUrl) async {
    await launchURL(appleMusicUrl);
  }
}
