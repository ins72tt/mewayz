import 'dart:async';

import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:purchases_flutter/models/offerings_wrapper.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';
import 'package:purchases_flutter/models/store_product_wrapper.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/subscription/model/subscription_plan_model.dart';

import '../../network/core_api.dart';
import '../../utils/app_common.dart';
import '../../utils/common_base.dart';
import '../../utils/constants.dart';

class SubscriptionController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  Rx<Future<RxList<SubscriptionPlanModel>>> getSubscriptionFuture = Future(() => RxList<SubscriptionPlanModel>()).obs;
  RxList<SubscriptionPlanModel> planList = RxList();
  Rx<SubscriptionPlanModel> selectPlan = SubscriptionPlanModel().obs;
  RxDouble price = 0.0.obs;
  RxDouble discount = 0.0.obs;
  RxBool isShowCoupon = false.obs;
  RxDouble totalAmount = 0.0.obs;
  RxDouble tempTotalAmount = 0.0.obs;

  int? requiredLevel;

  Rx<Offerings?> revenueCatSubscriptionOfferings = Rx<Offerings?>(null);

  StoreProduct? selectedRevenueCatPackage;
  RxList<StoreProduct?> storeProductList = <StoreProduct?>[].obs;

  @override
  void onInit() {
    if (Get.arguments is int) {
      requiredLevel = Get.arguments;
    }

    getSubscriptionDetails();
    super.onInit();
  }

  Future<void> getRevenueCatOfferings() async {
    await inAppPurchaseService.init().then(
      (value) async {
        await initRevenueCat();
      },
    );
  }

  Future<void> initRevenueCat() async {
    await inAppPurchaseService.getStoreSubscriptionPlanList().then((value) {
      revenueCatSubscriptionOfferings(value);
      if (revenueCatSubscriptionOfferings.value != null && revenueCatSubscriptionOfferings.value!.current != null && revenueCatSubscriptionOfferings.value!.current!.availablePackages.isNotEmpty) {
        storeProductList.value = revenueCatSubscriptionOfferings.value!.current!.availablePackages.map((e) => e.storeProduct).toList();
        Set<String> revenueCatIdentifiers = revenueCatSubscriptionOfferings.value!.current!.availablePackages.map((package) => package.storeProduct.identifier).toSet();

        // Filter backend plans to match RevenueCat identifiers

        planList.value = planList.where((plan) {
          return (revenueCatIdentifiers.contains(isIOS ? plan.appleInAppPurchaseIdentifier : plan.googleInAppPurchaseIdentifier));
        }).toList();
        planList.refresh();
      }
    }).catchError((e) {
      log("Can't find revenueCat offerings");
    });
  }

  Package? getSelectedPlanFromRevenueCat(SubscriptionPlanModel selectedPlan) {
    if (revenueCatSubscriptionOfferings.value != null && revenueCatSubscriptionOfferings.value!.current != null && revenueCatSubscriptionOfferings.value!.current!.availablePackages.isNotEmpty) {
      int index = revenueCatSubscriptionOfferings.value!.current!.availablePackages
          .indexWhere((element) => element.storeProduct.identifier == (isIOS ? selectedPlan.appleInAppPurchaseIdentifier : selectedPlan.googleInAppPurchaseIdentifier));
      if (index > -1) {
        return revenueCatSubscriptionOfferings.value!.current!.availablePackages[index];
      }
    } else {
      return null;
    }
    return null;
  }

  saveSubscription({required String transactionId}) {
    //int plan_id, int user_id, String identifier, String payment_status, String payment_type, String transaction_id

    isLoading(true);
    Map<String, dynamic> request = {
      "plan_id": selectPlan.value.planId,
      "user_id": loginUserData.value.id,
      "identifier": selectPlan.value.name.validate(),
      "payment_status": PaymentStatus.PAID,
      "payment_type": PaymentMethods.PAYMENT_METHOD_IN_APP_PURCHASE,
      "transaction_id": transactionId,
      'device_id': yourDevice.value.deviceId,
    };

    request.putIfAbsent(
      'active_in_app_purchase_identifier',
      () => isIOS ? selectPlan.value.appleInAppPurchaseIdentifier : selectPlan.value.googleInAppPurchaseIdentifier,
    );
    CoreServiceApis.saveSubscriptionDetails(
      request: request,
    ).then((value) async {
      Get.back();

      setValue(SharedPreferenceConst.USER_DATA, loginUserData.toJson());
      currentSubscription(value.data);
      currentSubscription.value.activePlanInAppPurchaseIdentifier = isIOS ? currentSubscription.value.appleInAppPurchaseIdentifier : currentSubscription.value.googleInAppPurchaseIdentifier;
      if (currentSubscription.value.level > -1 && currentSubscription.value.planType.isNotEmpty && currentSubscription.value.planType.any((element) => element.slug == SubscriptionTitle.videoCast)) {
        isCastingSupported(currentSubscription.value.planType.firstWhere((element) => element.slug == SubscriptionTitle.videoCast).limitationValue.getBoolInt());
      } else {
        isCastingSupported(false);
      }
      setValue(SharedPreferenceConst.USER_SUBSCRIPTION_DATA, value.data.toJson());
      setValue(SharedPreferenceConst.USER_DATA, loginUserData.toJson());

      successSnackBar(value.message.toString());
    }).catchError((e) {
      isLoading(false);
      errorSnackBar(error: e);
    }).whenComplete(() {
      isLoading(false);
    });
  }

  ///Get Subscription List
  Future<void> getSubscriptionDetails({bool showloader = true}) async {
    if (showloader) {
      isLoading(true);
    }

    if (planList.isNotEmpty) {
      planList.clear();
    }
    await getSubscriptionFuture(
      CoreServiceApis.getPlanList(getPlanList: planList),
    ).then((value) {
      if (planList.isNotEmpty) {
        planList.removeWhere((item) => item.planId == currentSubscription.value.planId);

        if (requiredLevel != null && planList.any((element) => element.level == requiredLevel)) {
          selectPlan(planList.firstWhere((element) => element.level == requiredLevel));
          calculateTotalPrice();
        }
        if (appConfigs.value.enableInAppPurchase.getBoolInt()) {
          getRevenueCatOfferings();
        }
      }
    }).catchError((e) {
      log("getPlan List Err : $e");
    }).whenComplete(() => isLoading(false));
  }

  @override
  // ignore: unnecessary_overrides
  void onClose() {
    super.onClose();
  }

//SubScriptionPrice

  calculateTotalPrice() {
    price.value = selectPlan.value.discount.getBoolInt() ? selectPlan.value.totalPrice.toDouble() : selectPlan.value.price.toDouble();

    double totalTax = 0.0;
    double totalTaxWithoutDiscount = 0.0;
    for (var tax in appConfigs.value.taxPercentage) {
      if (tax.type.toLowerCase() == locale.value.percentage) {
        totalTax += (price.value * tax.value / 100);
        totalTaxWithoutDiscount += (selectPlan.value.price.toDouble() * (tax.value / 100));
      } else if (tax.type.toLowerCase() == locale.value.fixed) {
        totalTax += tax.value;
        totalTaxWithoutDiscount += tax.value;
      } else {
        totalTax += tax.value;
        totalTaxWithoutDiscount += tax.value;
      }
    }

    tempTotalAmount(selectPlan.value.price + totalTaxWithoutDiscount);
    totalAmount(price.value + totalTax);
  }
}