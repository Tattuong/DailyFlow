import 'package:flutter_test/flutter_test.dart';
import 'package:dailyflow/core/constants/iap_constants.dart';
import 'package:dailyflow/core/services/iap_config_service.dart';
import 'package:dailyflow/models/shop_item.dart';

void main() {
  test('DailyFlow IAP ids and N304 endpoint', () {
    expect(IapConstants.productPrefix, 'df');
    expect(IapConstants.remoteConfigUrl,
        'https://api2.blwsmartware.net/N304.json');
    expect(IapConstants.coinPackIds.first, 'df_pack_1');
    expect(IapConstants.coinPackIds.last, 'df_pack_10');
    expect(IapConstants.coinPackIds, hasLength(10));
    expect(IapConstants.removeAdsProductId, 'df_remove_ads');
    expect(IapConstants.proProductId, 'df_pro');
    expect(IapConstants.allProductIds,
        containsAll([...IapConstants.coinPackIds, 'df_remove_ads', 'df_pro']));
    expect(IapConstants.coinsForProduct('df_pack_5'), 500);
    expect(IapConstants.freeArchiveLimit, 8);
    expect(IapConstants.proArchiveLimit, 99);
  });

  test('disable=1 hides billing only', () {
    final off = IapRemoteConfig.fromJson({'disable': 1, 'name': 'DailyFlow'});
    expect(off.billingDisabled, isTrue);
    final on = IapRemoteConfig.fromJson(
        {'disable': 0, 'name': 'DailyFlow', 'code': 'FULL_IAP'});
    expect(on.billingDisabled, isFalse);
    expect(on.name, 'DailyFlow');
  });

  test('shop catalog extras can be applied and reverted', () {
    expect(
        ShopCatalog.items.where((e) => e.id.startsWith('theme_')), isNotEmpty);
    expect(ShopCatalog.find(ShopCatalog.featPro), isNotNull);
    expect(ShopCatalog.find('remove_ads'), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featHint), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featSound), isNotNull);
    expect(ShopCatalog.isDefaultId(ShopCatalog.defaultThemeId), isTrue);
  });
}
