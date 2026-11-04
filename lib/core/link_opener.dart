import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens https / tel / wa.me outside the app.
abstract class LinkOpener {
  Future<bool> open(Uri uri);
}

class UrlLinkOpener implements LinkOpener {
  const UrlLinkOpener();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

final linkOpenerProvider = Provider<LinkOpener>(
  (Ref ref) => const UrlLinkOpener(),
);
