import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const bool _adsEnabled = bool.fromEnvironment('ENABLE_ADS');
const String _androidAppId = String.fromEnvironment('ADMOB_ANDROID_APP_ID');
const bool _useLiveAds = bool.fromEnvironment('USE_LIVE_ADS');
const String _androidLiveBannerAdUnitId =
    String.fromEnvironment('ADMOB_ANDROID_LIVE_BANNER_AD_UNIT_ID');
const String _androidTestBannerAdUnitId =
    String.fromEnvironment('ADMOB_ANDROID_TEST_BANNER_AD_UNIT_ID');

class AppAdsController extends ChangeNotifier {
  bool _initialized = false;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;

  String? get _configuredBannerAdUnitId {
    final adUnitId =
        (_useLiveAds ? _androidLiveBannerAdUnitId : _androidTestBannerAdUnitId)
            .trim();
    return adUnitId.isEmpty ? null : adUnitId;
  }

  bool get adsSupported =>
      _adsEnabled &&
      !kIsWeb &&
      Platform.isAndroid &&
      _androidAppId.trim().isNotEmpty &&
      _configuredBannerAdUnitId != null;
  bool get canRequestAds => adsSupported && _canRequestAds;
  bool get privacyOptionsRequired => adsSupported && _privacyOptionsRequired;

  String get bannerAdUnitId => _configuredBannerAdUnitId!;

  Future<void> initialize() async {
    if (_adsEnabled && !adsSupported) {
      debugPrint(
        'Ads are enabled, but AdMob IDs are missing. Provide '
        'ADMOB_ANDROID_APP_ID and the matching banner ad unit ID via '
        '--dart-define or --dart-define-from-file.',
      );
    }

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
