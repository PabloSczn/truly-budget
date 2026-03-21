import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const bool _useLiveAds = bool.fromEnvironment('USE_LIVE_ADS');

class AppAdsController extends ChangeNotifier {
  static const String _androidLiveBannerAdUnitId =
      'ca-app-pub-1687902853404140/8325340124';
  static const String _androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/9214589741';

  bool _initialized = false;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;

  bool get adsSupported => !kIsWeb && Platform.isAndroid;
  bool get canRequestAds => adsSupported && _canRequestAds;
  bool get privacyOptionsRequired => adsSupported && _privacyOptionsRequired;

  String get bannerAdUnitId =>
      _useLiveAds ? _androidLiveBannerAdUnitId : _androidTestBannerAdUnitId;

  Future<void> initialize() async {
    if (_initialized || !adsSupported) return;
    _initialized = true;

    try {
      await MobileAds.instance.initialize();
      await _refreshConsentStatus();
    } catch (error, stackTrace) {
      debugPrint('Ads initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _refreshConsentStatus() {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        _privacyOptionsRequired = await _isPrivacyOptionsRequired();
        await _loadAndShowConsentFormIfRequired();
        _canRequestAds = await ConsentInformation.instance.canRequestAds();
        notifyListeners();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      (FormError error) async {
        debugPrint(
          'Consent info update failed (${error.errorCode}): ${error.message}',
        );
        _privacyOptionsRequired = await _isPrivacyOptionsRequired();
        _canRequestAds = await ConsentInformation.instance.canRequestAds();
        notifyListeners();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    return completer.future;
  }

  Future<void> _loadAndShowConsentFormIfRequired() {
    final completer = Completer<void>();

    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (error != null) {
        debugPrint(
          'Consent form failed (${error.errorCode}): ${error.message}',
        );
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    return completer.future;
  }

  Future<bool> _isPrivacyOptionsRequired() async {
    return await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  }

  Future<String?> showPrivacyOptionsForm() async {
    if (!privacyOptionsRequired) return null;

    final completer = Completer<String?>();

    ConsentForm.showPrivacyOptionsForm((FormError? error) async {
      _privacyOptionsRequired = await _isPrivacyOptionsRequired();
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      notifyListeners();
      if (!completer.isCompleted) {
        completer.complete(error?.message);
      }
    });

    return completer.future;
  }
}
