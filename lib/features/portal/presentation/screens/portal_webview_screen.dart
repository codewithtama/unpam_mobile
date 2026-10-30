import 'main_navigation_screen.dart';

export 'main_navigation_screen.dart';

/// Wrapper kompatibilitas mundur untuk PortalWebViewScreen.
/// Seluruh arsitektur kini berjalan di atas [MainNavigationScreen] 100% native Flutter
/// tanpa beban memori WebView ganda di latar belakang.
class PortalWebViewScreen extends MainNavigationScreen {
  const PortalWebViewScreen({
    super.key,
    super.initialUrl = 'https://mentari.unpam.ac.id/',
  });

  /// Whitelist domain navigasi resmi kampus dan SSO login UNPAM.
  static bool isAllowedInAppNavigation(String url) =>
      MainNavigationScreen.isAllowedInAppNavigation(url);
}
