import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide display preferences, saved on the phone.
class SettingsProvider extends ChangeNotifier {
  static const _textScaleKey = 'settings_text_scale';

  static const minTextScale = 0.8;
  static const maxTextScale = 1.3;

  /// Multiplier on every text size in the app (1.0 = default). Applied on
  /// top of the phone's own accessibility font size in main.dart.
  double textScale = 1.0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    textScale = (prefs.getDouble(_textScaleKey) ?? 1.0).clamp(minTextScale, maxTextScale);
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    textScale = value.clamp(minTextScale, maxTextScale);
    notifyListeners();
    await (await SharedPreferences.getInstance()).setDouble(_textScaleKey, textScale);
  }
}
