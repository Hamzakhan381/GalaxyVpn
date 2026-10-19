import '../../domain/entities/vpn_session.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../../domain/repositories/session_repository.dart';

/// Concrete implementation of SessionRepository storing sessions via PreferencesRepository
class SessionRepositoryImpl implements SessionRepository {
  final PreferencesRepository _prefs;

  SessionRepositoryImpl(this._prefs);

  @override
  List<VpnSession> getSessions() {
    try {
      final raw = _prefs.getSessionHistoryJson();
      final list = <VpnSession>[];
      for (final json in raw) {
        try {
          list.add(VpnSession.fromJson(json));
        } catch (_) {}
      }
      list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveSessions(List<VpnSession> sessions) async {
    final listJson = sessions.map((s) => s.toJson()).toList();
    await _prefs.saveSessionHistoryJson(listJson);
  }

  @override
  Future<void> clearHistory() async {
    await _prefs.clearHistory();
  }
}
