import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mimir/app.dart';

import 'lang.dart';

export 'package:mimir/r.dart';

export 'lang.dart';

extension I18nBuildContext on BuildContext {
  ///e.g.: Wednesday, September 21, 2022
  String formatYmdWeekText(DateTime date) {
    final curLocale = locale;
    return Lang.ymdWeekText(curLocale.languageCode, curLocale.countryCode).format(date);
  }

  ///e.g.: 9/21/2022
  String formatYmdNum(DateTime date) {
    final curLocale = locale;
    return Lang.ymdNum(curLocale.languageCode, curLocale.countryCode).format(date);
  }

  ///e.g.: 9/21/2022 23:57:23
  String formatYmdhmsNum(DateTime date) {
    final curLocale = locale;
    return Lang.ymdhmsNum(curLocale.languageCode, curLocale.countryCode).format(date);
  }

  String formatYmText(DateTime date) {
    final curLocale = locale;
    return Lang.ymText(curLocale.languageCode, curLocale.countryCode).format(date);
  }

  /// e.g.: 8:32:59
  String formatHms(DateTime date) => Lang.hms.format(date);
}

extension LocaleExtension on Locale {
  String dateText(DateTime date) => DateFormat.yMMMMEEEEd(languageCode).format(date);
}

bool yOrNo(String test, {bool defaultValue = false}) {
  switch (test) {
    case "y":
      return true;
    case "n":
      return false;
    default:
      return defaultValue;
  }
}

///e.g.: Wednesday, September 21, 2022
/// [$Key.currentContext] is used
String dateText(DateTime date) {
  final curLocale = $Key.currentContext!.locale;
  return Lang.ymdWeekText(curLocale.languageCode, curLocale.countryCode).format(date);
}

///e.g.:9/21/2022
/// [$Key.currentContext] is used
String dateNum(DateTime date) {
  final curLocale = $Key.currentContext!.locale;
  return Lang.ymdNum(curLocale.languageCode, curLocale.countryCode).format(date);
}

///e.g.: 9/21/2022 23:57:23
/// [$Key.currentContext] is used
String dateFullNum(DateTime date) {
  final curLocale = $Key.currentContext!.locale;
  return Lang.ymdhmsNum(curLocale.languageCode, curLocale.countryCode).format(date);
}
