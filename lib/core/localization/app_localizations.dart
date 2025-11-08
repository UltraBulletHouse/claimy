import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('en'), Locale('pl')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get localeName => locale.languageCode;

  String _languageKey() =>
      supportedLocales.any((l) => l.languageCode == locale.languageCode)
      ? locale.languageCode
      : 'en';

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Claimy',
      'loginFailed': 'Login failed: {error}',
      'termsAndPrivacy':
          "By continuing you agree to Claimy's Terms and Privacy Policy.",
      'loginHeading': 'Sign in',
      'loginSubtitle': 'Enter your details to access your dashboard.',
      'emailLabel': 'Email',
      'emailRequired': 'Enter an email',
      'emailInvalid': 'Enter a valid email',
      'passwordLabel': 'Password',
      'passwordRequired': 'Enter your password',
      'passwordMin': 'Use at least 6 characters',
      'forgotPassword': 'Forgot password?',
      'loginButton': 'Log in',
      'newToClaimy': 'New to Claimy?',
      'createAccountCta': 'Create an account',
      'signInTagline': 'Sign in to continue managing your claims and rewards.',
      'signUpFailed': 'Sign up failed: {error}',
      'createAccountTitle': 'Create account',
      'signUpHeading': 'Let’s get you started',
      'fullNameLabel': 'Full name',
      'nameRequired': 'Enter your name',
      'passwordHelper': 'Use at least 8 characters',
      'passwordCreateRequired': 'Create a password',
      'signUpButton': 'Sign up',
      'alreadyHaveAccount': 'Already have an account?',
      'backToLogin': 'Back to login',
      'enterValidEmail': 'Enter a valid email to continue',
      'resetLinkSent': 'Check {email} for a link to reset your password.',
      'resetEmailFailed': 'Failed to send reset email: {error}',
      'resetPasswordTitle': 'Reset password',
      'resetPasswordDescription': 'We\'ll email you a reset link.',
      'sendResetLink': 'Send reset link',
      'claimSubmitted': 'Claim submitted. We\'ll keep you posted!',
      'homeUnreadSingle': 'You have 1 case update waiting.',
      'homeUnreadFew': 'You have {count} case updates waiting.',
      'homeUnreadMany': 'You have {count} case updates waiting.',
      'homeUnreadNone': 'All caught up! No new updates.',
      'newClaim': 'New claim',
      'homeGreeting': 'Hey, {name}',
      'signOut': 'Sign out',
      'tabCases': 'My cases',
      'tabRewards': 'My rewards',
      'filterAllCases': 'All cases',
      'casesSearchHint': 'Search store or product',
      'casesEmptyTitle': 'No cases found',
      'casesEmptyBody': 'Try adjusting your filters or creating a new claim.',
      'caseSyncTitle': 'Syncing your cases',
      'caseSyncBody': 'Fetching the latest updates for you…',
      'caseSyncErrorTitle': 'We couldn\'t refresh your cases',
      'tryAgain': 'Try again',
      'rewardsIntro':
          'Use your vouchers instantly while shopping in-store or online.',
      'rewardsEmptyTitle': 'No active rewards yet',
      'rewardsEmptyBody':
          'Submit claims to unlock vouchers and cashback offers.',
      'caseUpdated': 'Updated {time}',
      'caseNewUpdate': 'New update',
      'caseNeedsInfo': 'We need one quick detail from you.',
      'statusPending': 'Pending',
      'statusInReview': 'In review',
      'statusNeedsInfo': 'Need info',
      'statusApproved': 'Approved',
      'statusRejected': 'Declined',
      'infoResponseNoted': 'Thanks! We noted "{response}".',
      'caseNotFound': 'Case not found',
      'caseCreated': 'Created {date}',
      'caseLastUpdate': 'Last update {time}',
      'statusHistory': 'Status history',
      'receiptImage': 'Receipt image',
      'receiptHelp': 'Open or copy the receipt image link if needed.',
      'couldNotOpen': 'Could not open: {url}',
      'open': 'Open',
      'receiptLinkCopied': 'Receipt link copied to clipboard',
      'copy': 'Copy',
      'timelineYou': 'You',
      'timelineSupport': 'Support',
      'timelineSubmitted': 'Submitted',
      'timelineInReview': 'We\'re reviewing your claim',
      'timelineNeedsInfo': 'We\'ve requested additional info',
      'timelineApproved': 'Approved',
      'timelineRejected': 'Declined',
      'filePickFailed': 'Could not pick file: {error}',
      'answerRequired': 'Please provide an answer',
      'fileRequired': 'Please attach a file as requested',
      'infoReceived': 'Thanks! We received your info.',
      'yes': 'Yes',
      'no': 'No',
      'uploadedPhoto': 'Uploaded photo',
      'uploadPhoto': 'Upload photo',
      'languageEnglish': 'English',
      'languagePolish': 'Polish',
      'voucherExpiresOne': 'Expires in 1 day',
      'voucherExpiresOther': 'Expires in {days} days',
      'voucherExpired': 'Expired',
      'voucherReadyToUse': 'Ready to use',
      'voucherRedeemed': 'Redeemed',
      'voucherCopied': 'Voucher code copied to clipboard',
      'voucherReadyToShare': 'Voucher details copied to clipboard',
      'voucherMarkAsUsed': 'Mark as used',
      'voucherMarkedAsUsed': 'Marked as used',
      'answerOrFileRequired': 'Please provide an answer or attach a file',
      'fileReceived': 'Thanks! We received your file.',
      'submitFailed': 'Failed to submit: {error}',
      'fileSubmitFailed': 'Failed to submit file: {error}',
      'requestedOn': 'Requested {date}',
      'fileUploadRequired': 'File upload required',
      'responseSubmitted': 'Response submitted',
      'attachFile': 'Attach File',
      'respond': 'Respond',
      'answerHint': 'Type your answer...',
      'submit': 'Submit',
      'cancel': 'Cancel',
      'relativeJustNow': 'just now',
      'relativeMinutes': '{count} min ago',
      'relativeHours': '{count} h ago',
      'relativeDays': '{count} d ago',
      'photoAdded': 'Photo added',
      'tapToAdd': 'Tap to add',
      'tapToCopy': 'Tap to copy',
      'storeLoadFailed': 'Failed to load stores: {error}',
      'selectStore': 'Select a store to continue.',
      'productNamePrompt': 'Tell us the product name.',
      'addPhotosPrompt': 'Please add both photos before continuing.',
      'imageUploadFailed': 'Image upload failed: {error}',
      'claimSubmittedSuccess': 'Claim submitted successfully.',
      'submissionFailed': 'Submission failed.',
      'back': 'Back',
      'submitClaim': 'Submit claim',
      'continue': 'Continue',
      'whereBought': 'Where did you buy it?',
      'storeDescription':
          'Choose the store so we can route your claim to the right team.',
      'noStoresConfigured':
          'No stores are configured yet. Ask support to configure store options.',
      'storeRefreshError':
          'We couldn\'t refresh the store list. Please retry or try again shortly.',
      'retry': 'Retry',
      'whatBought': 'What did you buy?',
      'productDescription':
          'Be specific so the store can identify the product quickly.',
      'productName': 'Product name',
      'productHint': 'e.g. Organic almond milk 1L',
      'describeWhatHappened': 'Describe what happened',
      'descriptionSubtitle':
          'Let us know what went wrong. Keep it short and friendly.',
      'descriptionLabel': 'Describe the issue (optional)',
      'descriptionHint': 'Tell us what went wrong so we can fix it.',
      'photosTitle': 'Add your photos',
      'photosDescription':
          'Upload a product photo and the receipt so we can verify your claim.',
      'productPhoto': 'Product photo',
      'receiptPhoto': 'Receipt photo',
      'imageSizeMessage': 'Please choose an image under 10 MB (jpg, png, webp).',
      'failedToReadFile': 'Failed to read the selected file.',
      'failedToPickFile': 'Failed to pick file: {error}',
    },
    'pl': {
      'appTitle': 'Claimy',
      'loginFailed': 'Logowanie nie powiodło się: {error}',
      'termsAndPrivacy':
          'Kontynuując, akceptujesz Regulamin i Politykę Prywatności Claimy.',
      'loginHeading': 'Zaloguj się',
      'loginSubtitle': 'Podaj swoje dane, aby przejść do panelu.',
      'emailLabel': 'Adres e-mail',
      'emailRequired': 'Podaj adres e-mail',
      'emailInvalid': 'Podaj poprawny adres e-mail',
      'passwordLabel': 'Hasło',
      'passwordRequired': 'Podaj hasło',
      'passwordMin': 'Użyj co najmniej 6 znaków',
      'forgotPassword': 'Zapomniałeś hasła?',
      'loginButton': 'Zaloguj się',
      'newToClaimy': 'Pierwszy raz w Claimy?',
      'createAccountCta': 'Załóż konto',
      'signInTagline': 'Zaloguj się, aby zarządzać zgłoszeniami i nagrodami.',
      'signUpFailed': 'Rejestracja nie powiodła się: {error}',
      'createAccountTitle': 'Utwórz konto',
      'signUpHeading': 'Zacznijmy',
      'fullNameLabel': 'Imię i nazwisko',
      'nameRequired': 'Podaj swoje imię i nazwisko',
      'passwordHelper': 'Użyj co najmniej 8 znaków',
      'passwordCreateRequired': 'Utwórz hasło',
      'signUpButton': 'Zarejestruj się',
      'alreadyHaveAccount': 'Masz już konto?',
      'backToLogin': 'Wróć do logowania',
      'enterValidEmail': 'Podaj poprawny adres e-mail, aby kontynuować',
      'resetLinkSent': 'Sprawdź {email}, aby znaleźć link do resetu hasła.',
      'resetEmailFailed':
          'Nie udało się wysłać wiadomości resetującej: {error}',
      'resetPasswordTitle': 'Resetuj hasło',
      'resetPasswordDescription': 'Wyślemy Ci link do resetu hasła.',
      'sendResetLink': 'Wyślij link resetujący',
      'claimSubmitted': 'Zgłoszenie wysłane. Będziemy Cię informować!',
      'homeUnreadSingle': 'Masz 1 aktualizację sprawy.',
      'homeUnreadFew': 'Masz {count} aktualizacje spraw.',
      'homeUnreadMany': 'Masz {count} aktualizacji spraw.',
      'homeUnreadNone': 'Wszystko nadrobione! Brak nowych aktualizacji.',
      'newClaim': 'Nowe zgłoszenie',
      'homeGreeting': 'Cześć, {name}',
      'signOut': 'Wyloguj się',
      'tabCases': 'Moje sprawy',
      'tabRewards': 'Moje nagrody',
      'filterAllCases': 'Wszystkie',
      'casesSearchHint': 'Szukaj sklepu lub produktu',
      'casesEmptyTitle': 'Brak spraw',
      'casesEmptyBody': 'Zmień filtry lub utwórz nowe zgłoszenie.',
      'caseSyncTitle': 'Synchronizujemy Twoje sprawy',
      'caseSyncBody': 'Pobieramy najnowsze aktualizacje…',
      'caseSyncErrorTitle': 'Nie udało się odświeżyć spraw',
      'tryAgain': 'Spróbuj ponownie',
      'rewardsIntro':
          'Korzystaj z kuponów od razu podczas zakupów w sklepie lub online.',
      'rewardsEmptyTitle': 'Brak aktywnych nagród',
      'rewardsEmptyBody': 'Składaj zgłoszenia, aby odblokować kupony i zwroty.',
      'caseUpdated': 'Zaktualizowano {time}',
      'caseNewUpdate': 'Nowa aktualizacja',
      'caseNeedsInfo': 'Potrzebujemy od Ciebie krótkiej informacji.',
      'statusPending': 'Oczekujące',
      'statusInReview': 'W trakcie',
      'statusNeedsInfo': 'Informacja',
      'statusApproved': 'Uznany',
      'statusRejected': 'Odrzucone',
      'infoResponseNoted': 'Dziękujemy! Zanotowaliśmy „{response}”.',
      'caseNotFound': 'Nie znaleziono sprawy',
      'caseCreated': 'Utworzono {date}',
      'caseLastUpdate': 'Ostatnia aktualizacja {time}',
      'statusHistory': 'Historia statusów',
      'receiptImage': 'Zdjęcie paragonu',
      'receiptHelp':
          'Otwórz lub skopiuj link do zdjęcia paragonu, jeśli potrzebujesz.',
      'couldNotOpen': 'Nie można otworzyć: {url}',
      'open': 'Otwórz',
      'receiptLinkCopied': 'Link do paragonu skopiowany do schowka',
      'copy': 'Kopiuj',
      'timelineYou': 'Ty',
      'timelineSupport': 'Wsparcie',
      'timelineSubmitted': 'Zgłoszono',
      'timelineInReview': 'Rozpatrujemy Twoją reklamację',
      'timelineNeedsInfo': 'Poprosiliśmy o dodatkowe informacje',
      'timelineApproved': 'Zaakceptowano',
      'timelineRejected': 'Odrzucono',
      'filePickFailed': 'Nie można wybrać pliku: {error}',
      'answerRequired': 'Podaj odpowiedź',
      'fileRequired': 'Dołącz wymagany plik',
      'infoReceived': 'Dziękujemy! Otrzymaliśmy Twoje informacje.',
      'yes': 'Tak',
      'no': 'Nie',
      'uploadedPhoto': 'Przesłane zdjęcie',
      'uploadPhoto': 'Prześlij zdjęcie',
      'languageEnglish': 'Angielski',
      'languagePolish': 'Polski',
      'voucherExpiresOne': 'Wygasa za 1 dzień',
      'voucherExpiresOther': 'Wygasa za {days} dni',
      'voucherExpired': 'Wygasło',
      'voucherReadyToUse': 'Gotowy do użycia',
      'voucherRedeemed': 'Zrealizowany',
      'voucherCopied': 'Kod kuponu skopiowany do schowka',
      'voucherReadyToShare': 'Szczegóły kuponu skopiowane do schowka',
      'voucherMarkAsUsed': 'Oznacz jako użyty',
      'voucherMarkedAsUsed': 'Oznaczony jako użyty',
      'answerOrFileRequired': 'Podaj odpowiedź lub dołącz plik',
      'fileReceived': 'Dziękujemy! Otrzymaliśmy Twój plik.',
      'submitFailed': 'Nie udało się wysłać: {error}',
      'fileSubmitFailed': 'Nie udało się wysłać pliku: {error}',
      'requestedOn': 'Poproszono {date}',
      'fileUploadRequired': 'Wymagane przesłanie pliku',
      'responseSubmitted': 'Odpowiedź wysłana',
      'attachFile': 'Dołącz plik',
      'respond': 'Odpowiedz',
      'answerHint': 'Wpisz swoją odpowiedź...',
      'submit': 'Wyślij',
      'cancel': 'Anuluj',
      'relativeJustNow': 'przed chwilą',
      'relativeMinutes': '{count} min temu',
      'relativeHours': '{count} godz. temu',
      'relativeDays': '{count} dni temu',
      'photoAdded': 'Zdjęcie dodane',
      'tapToAdd': 'Dotknij, aby dodać',
      'tapToCopy': 'Dotknij, aby skopiować',
      'storeLoadFailed': 'Nie udało się wczytać sklepów: {error}',
      'selectStore': 'Wybierz sklep, aby kontynuować.',
      'productNamePrompt': 'Podaj nazwę produktu.',
      'addPhotosPrompt': 'Dodaj oba zdjęcia, zanim przejdziesz dalej.',
      'imageUploadFailed': 'Przesyłanie zdjęcia nie powiodło się: {error}',
      'claimSubmittedSuccess': 'Zgłoszenie zostało wysłane.',
      'submissionFailed': 'Wysyłka nie powiodła się.',
      'back': 'Wstecz',
      'submitClaim': 'Wyślij zgłoszenie',
      'continue': 'Dalej',
      'whereBought': 'Gdzie dokonano zakupu?',
      'storeDescription':
          'Wybierz sklep, aby przekazać zgłoszenie do właściwego zespołu.',
      'noStoresConfigured':
          'Żadne sklepy nie zostały jeszcze skonfigurowane. Skontaktuj się z pomocą, aby je dodać.',
      'storeRefreshError':
          'Nie udało się odświeżyć listy sklepów. Spróbuj ponownie teraz lub za chwilę.',
      'retry': 'Spróbuj ponownie',
      'whatBought': 'Jaki produkt kupiono?',
      'productDescription':
          'Podaj szczegóły, aby sklep mógł szybko zidentyfikować produkt.',
      'productName': 'Nazwa produktu',
      'productHint': 'np. Mleko migdałowe bio 1 l',
      'describeWhatHappened': 'Opisz, co się stało',
      'descriptionSubtitle': 'Napisz, co poszło nie tak. Krótko i na temat.',
      'descriptionLabel': 'Opisz problem (opcjonalnie)',
      'descriptionHint':
          'Powiedz, co poszło nie tak, abyśmy mogli to naprawić.',
      'photosTitle': 'Dodaj zdjęcia',
      'photosDescription':
          'Prześlij zdjęcie produktu i paragon, abyśmy mogli zweryfikować zgłoszenie.',
      'productPhoto': 'Zdjęcie produktu',
      'receiptPhoto': 'Zdjęcie paragonu',
      'imageSizeMessage': 'Wybierz obraz do 10 MB (jpg, png, webp).',
      'failedToReadFile': 'Nie udało się odczytać wybranego pliku.',
      'failedToPickFile': 'Nie udało się wybrać pliku: {error}',
    },
  };

  String _lookup(String key) {
    final lang = _languageKey();
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }

  String _format(String key, Map<String, String> params) {
    var value = _lookup(key);
    params.forEach((placeholder, replacement) {
      value = value.replaceAll('{$placeholder}', replacement);
    });
    return value;
  }

  String get appTitle => _lookup('appTitle');
  String get termsAndPrivacy => _lookup('termsAndPrivacy');
  String get loginHeading => _lookup('loginHeading');
  String get loginSubtitle => _lookup('loginSubtitle');
  String get emailLabel => _lookup('emailLabel');
  String get emailRequired => _lookup('emailRequired');
  String get emailInvalid => _lookup('emailInvalid');
  String get passwordLabel => _lookup('passwordLabel');
  String get passwordRequired => _lookup('passwordRequired');
  String get passwordMin => _lookup('passwordMin');
  String get forgotPassword => _lookup('forgotPassword');
  String get loginButton => _lookup('loginButton');
  String get newToClaimy => _lookup('newToClaimy');
  String get createAccountCta => _lookup('createAccountCta');
  String get signInTagline => _lookup('signInTagline');
  String get createAccountTitle => _lookup('createAccountTitle');
  String get signUpHeading => _lookup('signUpHeading');
  String get fullNameLabel => _lookup('fullNameLabel');
  String get nameRequired => _lookup('nameRequired');
  String get passwordHelper => _lookup('passwordHelper');
  String get passwordCreateRequired => _lookup('passwordCreateRequired');
  String get signUpButton => _lookup('signUpButton');
  String get alreadyHaveAccount => _lookup('alreadyHaveAccount');
  String get backToLogin => _lookup('backToLogin');
  String get enterValidEmail => _lookup('enterValidEmail');
  String get resetPasswordTitle => _lookup('resetPasswordTitle');
  String get resetPasswordDescription => _lookup('resetPasswordDescription');
  String get sendResetLink => _lookup('sendResetLink');
  String get claimSubmitted => _lookup('claimSubmitted');
  String get newClaim => _lookup('newClaim');
  String get signOut => _lookup('signOut');
  String get tabCases => _lookup('tabCases');
  String get tabRewards => _lookup('tabRewards');
  String get filterAllCases => _lookup('filterAllCases');
  String get casesSearchHint => _lookup('casesSearchHint');
  String get casesEmptyTitle => _lookup('casesEmptyTitle');
  String get casesEmptyBody => _lookup('casesEmptyBody');
  String get caseSyncTitle => _lookup('caseSyncTitle');
  String get caseSyncBody => _lookup('caseSyncBody');
  String get caseSyncErrorTitle => _lookup('caseSyncErrorTitle');
  String get tryAgain => _lookup('tryAgain');
  String get rewardsIntro => _lookup('rewardsIntro');
  String get rewardsEmptyTitle => _lookup('rewardsEmptyTitle');
  String get rewardsEmptyBody => _lookup('rewardsEmptyBody');
  String get caseNewUpdate => _lookup('caseNewUpdate');
  String get caseNeedsInfo => _lookup('caseNeedsInfo');
  String get statusPending => _lookup('statusPending');
  String get statusInReview => _lookup('statusInReview');
  String get statusNeedsInfo => _lookup('statusNeedsInfo');
  String get statusApproved => _lookup('statusApproved');
  String get statusRejected => _lookup('statusRejected');
  String get caseNotFound => _lookup('caseNotFound');
  String get statusHistory => _lookup('statusHistory');
  String get receiptImage => _lookup('receiptImage');
  String get receiptHelp => _lookup('receiptHelp');
  String get open => _lookup('open');
  String get receiptLinkCopied => _lookup('receiptLinkCopied');
  String get copy => _lookup('copy');
  String get timelineYou => _lookup('timelineYou');
  String get timelineSupport => _lookup('timelineSupport');
  String get timelineSubmitted => _lookup('timelineSubmitted');
  String get timelineInReview => _lookup('timelineInReview');
  String get timelineNeedsInfo => _lookup('timelineNeedsInfo');
  String get timelineApproved => _lookup('timelineApproved');
  String get timelineRejected => _lookup('timelineRejected');
  String get answerRequired => _lookup('answerRequired');
  String get fileRequired => _lookup('fileRequired');
  String get infoReceived => _lookup('infoReceived');
  String get yes => _lookup('yes');
  String get no => _lookup('no');
  String get uploadedPhoto => _lookup('uploadedPhoto');
  String get uploadPhoto => _lookup('uploadPhoto');
  String get languageEnglish => _lookup('languageEnglish');
  String get languagePolish => _lookup('languagePolish');
  String get voucherExpired => _lookup('voucherExpired');
  String get voucherReadyToUse => _lookup('voucherReadyToUse');
  String get voucherRedeemed => _lookup('voucherRedeemed');
  String get voucherCopied => _lookup('voucherCopied');
  String get voucherReadyToShare => _lookup('voucherReadyToShare');
  String get voucherMarkAsUsed => _lookup('voucherMarkAsUsed');
  String get voucherMarkedAsUsed => _lookup('voucherMarkedAsUsed');
  String get answerOrFileRequired => _lookup('answerOrFileRequired');
  String get fileReceived => _lookup('fileReceived');
  String get fileUploadRequired => _lookup('fileUploadRequired');
  String get responseSubmitted => _lookup('responseSubmitted');
  String get attachFile => _lookup('attachFile');
  String get respond => _lookup('respond');
  String get answerHint => _lookup('answerHint');
  String get submit => _lookup('submit');
  String get cancel => _lookup('cancel');
  String get photoAdded => _lookup('photoAdded');
  String get tapToAdd => _lookup('tapToAdd');
  String get tapToCopy => _lookup('tapToCopy');
  String get selectStore => _lookup('selectStore');
  String get productNamePrompt => _lookup('productNamePrompt');
  String get addPhotosPrompt => _lookup('addPhotosPrompt');
  String get claimSubmittedSuccess => _lookup('claimSubmittedSuccess');
  String get submissionFailed => _lookup('submissionFailed');
  String get back => _lookup('back');
  String get submitClaim => _lookup('submitClaim');
  String get continueLabel => _lookup('continue');
  String get whereBought => _lookup('whereBought');
  String get storeDescription => _lookup('storeDescription');
  String get noStoresConfigured => _lookup('noStoresConfigured');
  String get storeRefreshError => _lookup('storeRefreshError');
  String get retry => _lookup('retry');
  String get whatBought => _lookup('whatBought');
  String get productDescription => _lookup('productDescription');
  String get productName => _lookup('productName');
  String get productHint => _lookup('productHint');
  String get describeWhatHappened => _lookup('describeWhatHappened');
  String get descriptionSubtitle => _lookup('descriptionSubtitle');
  String get descriptionLabel => _lookup('descriptionLabel');
  String get descriptionHint => _lookup('descriptionHint');
  String get photosTitle => _lookup('photosTitle');
  String get photosDescription => _lookup('photosDescription');
  String get productPhoto => _lookup('productPhoto');
  String get receiptPhoto => _lookup('receiptPhoto');
  String get imageSizeMessage => _lookup('imageSizeMessage');
  String get failedToReadFile => _lookup('failedToReadFile');

  String loginFailed(String error) => _format('loginFailed', {'error': error});
  String signUpFailed(String error) =>
      _format('signUpFailed', {'error': error});
  String resetLinkSent(String email) =>
      _format('resetLinkSent', {'email': email});
  String resetEmailFailed(String error) =>
      _format('resetEmailFailed', {'error': error});
  String homeGreeting(String name) => _format('homeGreeting', {'name': name});
  String caseUpdated(DateTime dateTime) =>
      _format('caseUpdated', {'time': formatRelativeTime(dateTime)});
  String infoResponseNoted(String response) =>
      _format('infoResponseNoted', {'response': response});
  String caseCreated(DateTime dateTime) =>
      _format('caseCreated', {'date': formatMediumDate(dateTime)});
  String caseLastUpdate(DateTime dateTime) =>
      _format('caseLastUpdate', {'time': formatRelativeTime(dateTime)});
  String couldNotOpen(String url) => _format('couldNotOpen', {'url': url});
  String filePickFailed(String error) =>
      _format('filePickFailed', {'error': error});
  String voucherExpires(int days) {
    if (days <= 1) {
      return _lookup('voucherExpiresOne');
    }
    return _format('voucherExpiresOther', {'days': days.toString()});
  }

  String submitFailed(String error) =>
      _format('submitFailed', {'error': error});
  String fileSubmitFailed(String error) =>
      _format('fileSubmitFailed', {'error': error});
  String requestedOn(DateTime date) =>
      _format('requestedOn', {'date': formatMediumDate(date)});
  String storeLoadFailed(String error) =>
      _format('storeLoadFailed', {'error': error});
  String imageUploadFailed(String error) =>
      _format('imageUploadFailed', {'error': error});
  String failedToPickFile(String error) =>
      _format('failedToPickFile', {'error': error});

  String homeUnreadCases(int count) {
    if (count <= 0) {
      return _lookup('homeUnreadNone');
    }
    final lang = _languageKey();
    if (lang == 'pl') {
      final mod10 = count % 10;
      final mod100 = count % 100;
      if (count == 1) {
        return _lookup('homeUnreadSingle');
      } else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
        return _format('homeUnreadFew', {'count': count.toString()});
      }
      return _format('homeUnreadMany', {'count': count.toString()});
    } else {
      if (count == 1) {
        return _lookup('homeUnreadSingle');
      }
      return _format('homeUnreadMany', {'count': count.toString()});
    }
  }

  String formatRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return _lookup('relativeJustNow');
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return _format('relativeMinutes', {'count': minutes.toString()});
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return _format('relativeHours', {'count': hours.toString()});
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return _format('relativeDays', {'count': days.toString()});
    }
    return formatMediumDate(dateTime);
  }

  String formatMediumDate(DateTime dateTime) {
    final tag = locale.toLanguageTag();
    return DateFormat.yMMMd(tag).format(dateTime);
  }

  String homeUnreadNone() => _lookup('homeUnreadNone');

  String brandTerms() => termsAndPrivacy;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
