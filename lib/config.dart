import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Base URL for vaximobileapi - the app's only backend (login and every
/// module; the vaxiCSR.Api ones were ported to its api/csr* routes). It has
/// no bearer-token auth at all - every call sends the logged-in username as a
/// plain, client-asserted query param instead.
///
/// For local dev against IIS Express (port 48224), swap in the commented
/// URLs - the Android emulator reaches the dev machine as 10.0.2.2, and a
/// real device on the LAN needs the dev machine's LAN IP instead - or pass
/// `--dart-define=API_BASE_URL=http://host:port/` to point a build elsewhere
/// without editing this file.
String get itinerariesApiBaseUrl {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;
  if (kIsWeb) {
    return 'http://shopapi.vaxilifecorp.com/';
    //'http://localhost:48224/';
  }
  if (Platform.isAndroid) {
    return 'http://shopapi.vaxilifecorp.com/';
    //'http://10.0.2.2:48224/';
  }
  return 'http://shopapi.vaxilifecorp.com/';
  //'http://localhost:48224/';
}
