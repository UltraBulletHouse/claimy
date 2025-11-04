import 'package:claimy/core/localization/app_localizations.dart';

String formatRelativeTime(DateTime dateTime, AppLocalizations l10n) =>
    l10n.formatRelativeTime(dateTime);

String formatMediumDate(DateTime dateTime, AppLocalizations l10n) =>
    l10n.formatMediumDate(dateTime);
