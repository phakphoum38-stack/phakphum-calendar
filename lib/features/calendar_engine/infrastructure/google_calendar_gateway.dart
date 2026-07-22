import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

import '../domain/calendar_gateway.dart';

class GoogleCalendarGateway implements CalendarGateway {
  GoogleCalendarGateway(this._client);

  final auth.AuthClient _client;

  @override
  Future<void> verifyAccess() async {
    final api = calendar.CalendarApi(_client);
    await api.calendars.get('primary');
  }
}
