import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local/preferences_local_data_source.dart';
import '../../data/repositories/preferences_repository_impl.dart';

/// Legacy service wrapper delegating cleanly to Clean Architecture PreferencesRepositoryImpl
/// without any testing mock leaks in production code.
class PreferencesService extends PreferencesRepositoryImpl {
  PreferencesService(SharedPreferences rawPrefs)
      : super(PreferencesLocalDataSource(rawPrefs));

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }
}
