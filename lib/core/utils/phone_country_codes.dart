/// Calling codes this app recognizes when a rep's mobile is typed/pasted
/// with a country code already on it (e.g. "+91 98765 43210"), plus the
/// expected local-number length for each — used to auto-detect the code
/// and to validate the number once split. UAE (+971) is the default for
/// plain local-digit entry with no leading '+'/'00'.
///
/// Ordered longest-code-first so e.g. "+971..." is matched against the
/// 3-digit UAE code before any shorter code could coincidentally match a
/// prefix of it (in practice none of the codes below collide that way,
/// but checking longest-first keeps that true by construction).
const Map<String, int> phoneCountryCodes = {
  '+971': 9, // UAE
  '+966': 9, // Saudi Arabia
  '+968': 8, // Oman
  '+973': 8, // Bahrain
  '+974': 8, // Qatar
  '+965': 8, // Kuwait
  '+880': 10, // Bangladesh
  '+977': 10, // Nepal
  '+962': 9, // Jordan
  '+961': 8, // Lebanon
  '+91': 10, // India
  '+92': 10, // Pakistan
  '+94': 9, // Sri Lanka
  '+63': 10, // Philippines
  '+20': 10, // Egypt
  '+44': 10, // United Kingdom
  '+1': 10, // US/Canada
};

const String defaultPhoneCountryCode = '+971';

/// Result of successfully splitting a full number into its country code
/// and local digits.
class DetectedPhoneNumber {
  const DetectedPhoneNumber({required this.countryCode, required this.localNumber});

  final String countryCode;
  final String localNumber;
}

/// If [raw] starts with '+' or '00' (international dialing prefix),
/// matches it against [phoneCountryCodes] (longest code first) and splits
/// off the local digits. Returns `null` if [raw] has no such prefix, or
/// the prefix doesn't match any known code — callers should treat that as
/// "not a full number", not an error, and leave the input as plain local
/// digits.
DetectedPhoneNumber? detectPhoneCountryCode(String raw) {
  final trimmed = raw.trim();
  final normalized = trimmed.startsWith('00') ? '+${trimmed.substring(2)}' : trimmed;
  if (!normalized.startsWith('+')) return null;

  final digitsOnly = normalized.substring(1).replaceAll(RegExp(r'\D'), '');
  final codesByLengthDesc = phoneCountryCodes.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  for (final code in codesByLengthDesc) {
    final codeDigits = code.substring(1);
    if (digitsOnly.startsWith(codeDigits)) {
      return DetectedPhoneNumber(countryCode: code, localNumber: digitsOnly.substring(codeDigits.length));
    }
  }
  return null;
}
