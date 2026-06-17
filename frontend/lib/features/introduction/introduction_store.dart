import 'package:shared_preferences/shared_preferences.dart';

class IntroductionStore {
  static const String _seenKey = 'introduction_v1_seen';

  static Future<bool> sudahDilihat() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool(_seenKey) ?? false;
  }

  static Future<void> tandaiSudahDilihat() async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool(_seenKey, true);
  }
}
