import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/monetization_config.dart';
import 'progress_provider.dart';

class MonetizationState {
  final bool storeAvailable;
  final bool hasFullGame;
  final bool purchasePending;
  final ProductDetails? productDetails;
  final String? errorMessage;

  const MonetizationState({
    required this.storeAvailable,
    required this.hasFullGame,
    required this.purchasePending,
    required this.productDetails,
    required this.errorMessage,
  });

  String get priceLabel => productDetails?.price ?? 'Unlock Full Game';

  MonetizationState copyWith({
    bool? storeAvailable,
    bool? hasFullGame,
    bool? purchasePending,
    ProductDetails? productDetails,
    bool clearProductDetails = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return MonetizationState(
      storeAvailable: storeAvailable ?? this.storeAvailable,
      hasFullGame: hasFullGame ?? this.hasFullGame,
      purchasePending: purchasePending ?? this.purchasePending,
      productDetails: clearProductDetails
          ? null
          : productDetails ?? this.productDetails,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class MonetizationNotifier extends AsyncNotifier<MonetizationState> {
  static const _unlockPrefKey = 'vantage_full_game_unlocked';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  SharedPreferences? _prefs;
  ProductDetails? _productDetails;

  @override
  Future<MonetizationState> build() async {
    ref.onDispose(() => _purchaseSub?.cancel());

    _prefs = await ref.watch(sharedPreferencesProvider.future);
    _purchaseSub ??= _inAppPurchase.purchaseStream.listen(
      (purchases) {
        unawaited(_handlePurchaseUpdates(purchases));
      },
      onError: (Object error, StackTrace stackTrace) {
        final current = state.valueOrNull;
        if (current == null) return;
        state = AsyncData(
          current.copyWith(
            purchasePending: false,
            errorMessage: 'Purchase stream failed: $error',
          ),
        );
      },
    );

    return _loadState(cachedUnlock: _prefs?.getBool(_unlockPrefKey) ?? false);
  }

  Future<void> buyFullGame() async {
    final current = state.valueOrNull;
    if (current == null) return;

    if (_productDetails == null) {
      state = AsyncData(
        current.copyWith(
          purchasePending: false,
          errorMessage: 'The unlock product is not available yet.',
        ),
      );
      return;
    }

    state = AsyncData(
      current.copyWith(purchasePending: true, clearErrorMessage: true),
    );

    final launched = await _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: _productDetails!),
    );

    if (!launched) {
      state = AsyncData(
        _currentState.copyWith(
          purchasePending: false,
          errorMessage: 'Unable to start the purchase flow.',
        ),
      );
    }
  }

  Future<void> restorePurchases() async {
    state = AsyncData(
      _currentState.copyWith(purchasePending: true, clearErrorMessage: true),
    );

    await _inAppPurchase.restorePurchases();

    Future<void>.delayed(const Duration(milliseconds: 900), () async {
      final current = state.valueOrNull;
      if (current == null || current.hasFullGame || !current.purchasePending) {
        return;
      }

      final refreshed = await _loadState(
        cachedUnlock: _prefs?.getBool(_unlockPrefKey) ?? false,
      );
      state = AsyncData(
        refreshed.copyWith(
          purchasePending: false,
          errorMessage: 'No prior purchase was found to restore.',
        ),
      );
    });
  }

  Future<void> grantDebugUnlock() async {
    if (!kDebugMode) return;
    await _prefs?.setBool(_unlockPrefKey, true);
    final refreshed = await _loadState(cachedUnlock: true);
    state = AsyncData(refreshed.copyWith(clearErrorMessage: true));
  }

  MonetizationState get _currentState =>
      state.valueOrNull ??
      const MonetizationState(
        storeAvailable: false,
        hasFullGame: false,
        purchasePending: false,
        productDetails: null,
        errorMessage: null,
      );

  Future<MonetizationState> _loadState({required bool cachedUnlock}) async {
    final storeAvailable = await _inAppPurchase.isAvailable();
    String? errorMessage;
    _productDetails = null;

    if (storeAvailable) {
      final response = await _inAppPurchase.queryProductDetails({
        MonetizationConfig.fullGameProductId,
      });
      if (response.error != null) {
        errorMessage = response.error!.message;
      }
      for (final details in response.productDetails) {
        if (details.id == MonetizationConfig.fullGameProductId) {
          _productDetails = details;
          break;
        }
      }
      if (_productDetails == null && errorMessage == null) {
        errorMessage = 'The full-game product is not configured yet.';
      }
    } else {
      errorMessage = 'Store access is unavailable on this device.';
    }

    return MonetizationState(
      storeAvailable: storeAvailable,
      hasFullGame: cachedUnlock,
      purchasePending: false,
      productDetails: _productDetails,
      errorMessage: errorMessage,
    );
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    var hasFullGame = _prefs?.getBool(_unlockPrefKey) ?? false;
    var purchasePending = false;
    String? errorMessage;

    for (final purchase in purchases) {
      if (purchase.productID != MonetizationConfig.fullGameProductId) {
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          purchasePending = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          hasFullGame = true;
          await _prefs?.setBool(_unlockPrefKey, true);
          break;
        case PurchaseStatus.error:
          errorMessage = purchase.error?.message ?? 'Purchase failed.';
          break;
        case PurchaseStatus.canceled:
          errorMessage = 'Purchase cancelled.';
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }

    final refreshed = await _loadState(cachedUnlock: hasFullGame);
    state = AsyncData(
      refreshed.copyWith(
        purchasePending: purchasePending,
        errorMessage: errorMessage,
      ),
    );
  }
}

final monetizationProvider =
    AsyncNotifierProvider<MonetizationNotifier, MonetizationState>(
      MonetizationNotifier.new,
    );
