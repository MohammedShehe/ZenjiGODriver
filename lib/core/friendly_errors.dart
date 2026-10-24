/// Maps technical exceptions into short, driver-friendly messages (EN + SW).
class FriendlyErrors {
  FriendlyErrors._();

  static String message(Object error, {bool swahili = false}) {
    final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    final lower = raw.toLowerCase();

    String pick(String en, String sw) => swahili ? sw : en;

    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('cannot reach server')) {
      return pick(
        'No internet connection. Check your data or Wi‑Fi and try again.',
        'Hakuna muunganisho wa intaneti. Angalia data au Wi‑Fi kisha jaribu tena.',
      );
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return pick(
        'The request took too long. Please try again.',
        'Ombi limechelewa sana. Tafadhali jaribu tena.',
      );
    }
    if (lower.contains('401') || lower.contains('unauthorized') || lower.contains('token')) {
      return pick(
        'Your session expired. Please sign in again.',
        'Kipindi chako kimekwisha. Tafadhali ingia tena.',
      );
    }
    if (lower.contains('403') || lower.contains('forbidden')) {
      return pick(
        'You do not have permission for this action.',
        'Huna ruhusa ya kufanya hatua hii.',
      );
    }
    if (lower.contains('404') || lower.contains('not found')) {
      return pick(
        'We could not find that item. It may have been removed.',
        'Hatukuweza kupata kitu hicho. Huenda kimeondolewa.',
      );
    }
    if (lower.contains('409') || lower.contains('conflict') || lower.contains('already')) {
      return pick(
        'This action conflicts with the current status. Refresh and try again.',
        'Hatua hii inagongana na hali ya sasa. Onyesha upya kisha jaribu tena.',
      );
    }
    if (lower.contains('422') || lower.contains('validation') || lower.contains('invalid')) {
      return pick(
        'Some details look incorrect. Please check and try again.',
        'Baadhi ya taarifa si sahihi. Tafadhali angalia kisha jaribu tena.',
      );
    }
    if (lower.contains('429') || lower.contains('too many')) {
      return pick(
        'Too many attempts. Wait a moment and try again.',
        'Umejaribu mara nyingi. Subiri kidogo kisha jaribu tena.',
      );
    }
    if (lower.contains('500') || lower.contains('server error') || lower.contains('internal')) {
      return pick(
        'Something went wrong on our side. Please try again shortly.',
        'Kuna hitilafu upande wetu. Tafadhali jaribu tena baadaye kidogo.',
      );
    }
    if (lower.contains('location') || lower.contains('permission') || lower.contains('gps')) {
      return pick(
        'Location access is needed. Enable GPS and allow location for this app.',
        'Inahitajika ruhusa ya eneo. Washa GPS na ruhusu eneo kwa programu hii.',
      );
    }
    if (lower.contains('settlement') || lower.contains('commission') || lower.contains('threshold')) {
      return pick(
        'Please settle your balance with ZenjiGO before accepting new rides.',
        'Tafadhali lipa deni lako kwa ZenjiGO kabla ya kukubali safari mpya.',
      );
    }
    if (lower.contains('offline') || lower.contains('go online')) {
      return pick(
        'Go online to receive and accept rides.',
        'Nenda mtandaoni ili upokee na ukubali safari.',
      );
    }
    if (lower.contains('document') || lower.contains('expired') || lower.contains('license')) {
      return pick(
        'A required document is missing or expired. Update it in Profile.',
        'Hati muhimu haipo au imeisha muda. Isasishe kwenye Wasifu.',
      );
    }

    // Prefer backend message if it already looks human-readable (no stack traces).
    if (raw.isNotEmpty &&
        raw.length < 180 &&
        !raw.contains('at ') &&
        !lower.contains('socketexception') &&
        !lower.contains('http://') &&
        !lower.contains('package:')) {
      return raw;
    }

    return pick(
      'Something went wrong. Please try again.',
      'Kuna hitilafu. Tafadhali jaribu tena.',
    );
  }
}
