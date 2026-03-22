import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/app_ads_controller.dart';

class BottomBannerAd extends StatefulWidget {
  const BottomBannerAd({super.key});

  @override
  State<BottomBannerAd> createState() => _BottomBannerAdState();
}

class _BottomBannerAdState extends State<BottomBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoading = false;
  int? _loadedWidth;
  String? _loadedAdUnitId;

  @override
  void dispose() {
    _disposeBanner();
    super.dispose();
  }

  void _disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _loadedWidth = null;
    _loadedAdUnitId = null;
    _isLoading = false;
  }

  void _clearBannerIfNeeded() {
    if (_bannerAd == null && !_isLoading) return;
    setState(_disposeBanner);
  }

  Future<void> _loadAd(AppAdsController controller) async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final adUnitId = controller.bannerAdUnitId;

    if (_isLoading ||
        (_bannerAd != null &&
            _loadedWidth == width &&
            _loadedAdUnitId == adUnitId)) {
      return;
    }

    _isLoading = true;
    final previousBanner = _bannerAd;
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (!mounted) {
      previousBanner?.dispose();
      return;
    }

    if (size == null) {
      _isLoading = false;
      return;
    }

    BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          previousBanner?.dispose();
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _loadedWidth = width;
            _loadedAdUnitId = adUnitId;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          debugPrint('Bottom banner failed to load: $error');
          setState(() {
            _isLoading = false;
          });
        },
      ),
    ).load();
  }

  @override
  Widget build(BuildContext context) {
    final adsController = context.watch<AppAdsController?>();
    final shouldShowBanner = adsController != null &&
        adsController.adsSupported &&
        adsController.canRequestAds;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (shouldShowBanner) {
        _loadAd(adsController);
      } else {
        _clearBannerIfNeeded();
      }
    });

    final bannerAd = _bannerAd;
    if (!shouldShowBanner || bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        width: bannerAd.size.width.toDouble(),
        height: bannerAd.size.height.toDouble(),
        child: AdWidget(ad: bannerAd),
      ),
    );
  }
}
