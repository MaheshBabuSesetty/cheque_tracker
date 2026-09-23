import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/app_environment.dart';

/// Per-environment leaf-certificate SHA-256 pins (pentest V-13 — the mobile
/// client validated TLS against the system trust store only, with no
/// pinning). Each `*_CERT_PINS` value is a comma-separated list of
/// base64-encoded SHA-256 fingerprints of the full DER certificate, e.g. the
/// output of:
///
/// ```
/// openssl s_client -connect HOST:443 -servername HOST < /dev/null 2>/dev/null \
///   | openssl x509 -outform der \
///   | openssl dgst -sha256 -binary | openssl enc -base64
/// ```
///
/// Defaults to empty for every environment, which leaves [isEnabled] false
/// and [configureCertificatePinning] a no-op — TLS validation is untouched
/// (system trust store, as today) until ops publishes real fingerprints via
/// `--dart-define-from-file=.env`. Shipping this unconditionally-on, before
/// the real hosts' fingerprints are known, would risk locking every build
/// out of its own API the moment it's enabled.
///
/// List at least two pins per host — the current leaf plus the next
/// certificate that will replace it (or a backup/intermediate), so a
/// routine renewal on the API side doesn't brick connectivity before an app
/// update carrying the new pin can ship.
class CertificatePinning {
  const CertificatePinning._();

  static const String _devPins = String.fromEnvironment('DEV_CERT_PINS', defaultValue: '');
  static const String _uatPins = String.fromEnvironment('UAT_CERT_PINS', defaultValue: '');
  static const String _prodPins = String.fromEnvironment('PROD_CERT_PINS', defaultValue: '');

  static List<String> get activePins {
    final raw = AppEnvironment.isProd ? _prodPins : (AppEnvironment.isUat ? _uatPins : _devPins);
    return raw.split(',').map((pin) => pin.trim()).where((pin) => pin.isNotEmpty).toList(growable: false);
  }

  static bool get isEnabled => activePins.isNotEmpty;
}

/// Wires SHA-256 certificate pinning into [dio]'s native HTTP client when
/// pins are configured for the active environment; otherwise a no-op (see
/// [CertificatePinning]). Only applies on Android/iOS — [dio]'s adapter is
/// not an [IOHttpClientAdapter] on web, and pinning a browser's TLS stack
/// isn't meaningful there anyway.
void configureCertificatePinning(Dio dio) {
  if (!CertificatePinning.isEnabled) return;
  final adapter = dio.httpClientAdapter;
  if (adapter is! IOHttpClientAdapter) return;

  final pins = CertificatePinning.activePins;
  adapter.createHttpClient = () {
    final client = HttpClient(context: SecurityContext(withTrustedRoots: false));
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      final fingerprint = base64.encode(sha256.convert(cert.der).bytes);
      return pins.contains(fingerprint);
    };
    return client;
  };
}
