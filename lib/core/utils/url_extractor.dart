/// Utility class for extracting web URLs from shared text and identifying platforms.
abstract final class UrlExtractor {
  /// Regular expression to find web URLs in text.
  static final RegExp _urlRegex = RegExp(
    r'https?://[^\s/$.?#].[^\s]*',
    caseSensitive: false,
  );

  /// Characters that should be trimmed from the end of a matched URL
  /// (e.g. punctuation attached at the end of a sentence).
  static final RegExp _trailingPunctuation = RegExp(r'[.,;:)\]\>!]+$');

  /// Extracts the first valid HTTP/HTTPS URL from [text].
  ///
  /// Returns `null` if no valid URL is found.
  static String? extractUrl(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    final match = _urlRegex.firstMatch(text);
    if (match == null) {
      return null;
    }

    var candidate = match.group(0)!;
    candidate = candidate.replaceAll(_trailingPunctuation, '');

    final uri = Uri.tryParse(candidate);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      return candidate;
    }

    return null;
  }

  /// Detects the platform identifier ('twitter', 'instagram', 'youtube', 'article')
  /// from a given [url].
  static String detectPlatform(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return 'article';
    }

    final host = uri.host.toLowerCase();

    if (host == 'x.com' ||
        host.endsWith('.x.com') ||
        host == 'twitter.com' ||
        host.endsWith('.twitter.com') ||
        host == 't.co') {
      return 'twitter';
    }

    if (host == 'instagram.com' ||
        host.endsWith('.instagram.com') ||
        host == 'instagr.am') {
      return 'instagram';
    }

    if (host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtu.be') {
      return 'youtube';
    }

    if (host == 'tiktok.com' || host.endsWith('.tiktok.com')) {
      return 'tiktok';
    }

    if (host == 'reddit.com' || host.endsWith('.reddit.com')) {
      return 'reddit';
    }

    return 'article';
  }
}
