import 'package:flutter/material.dart';

class LanguageUtils {
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
      case 'pt':
        return 'Português';
      case 'ru':
        return 'Русский';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return 'Unknown';
    }
  }

  static String getLanguageCode(String languageName) {
    switch (languageName.toLowerCase()) {
      case 'english':
        return 'en';
      case 'español':
      case 'spanish':
        return 'es';
      case 'français':
      case 'french':
        return 'fr';
      case 'deutsch':
      case 'german':
        return 'de';
      case 'italiano':
      case 'italian':
        return 'it';
      case 'português':
      case 'portuguese':
        return 'pt';
      case 'русский':
      case 'russian':
        return 'ru';
      case '中文':
      case 'chinese':
        return 'zh';
      case '日本語':
      case 'japanese':
        return 'ja';
      case '한국어':
      case 'korean':
        return 'ko';
      default:
        return 'en';
    }
  }

  static String getTrafficAlertText(String languageCode) {
    switch (languageCode) {
      case 'es':
        return 'Alerta de Tráfico';
      case 'fr':
        return 'Alerte de Circulation';
      case 'de':
        return 'Verkehrswarnung';
      case 'it':
        return 'Allerta Traffico';
      case 'pt':
        return 'Alerta de Trânsito';
      case 'ru':
        return 'Предупреждение о Движении';
      case 'zh':
        return '交通警告';
      case 'ja':
        return '交通警報';
      case 'ko':
        return '교통 경보';
      default:
        return 'Traffic Alert';
    }
  }
} 