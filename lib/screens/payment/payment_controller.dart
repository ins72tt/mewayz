import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/payment/model/payment_model.dart';
import 'package:streamit_laravel/screens/payment/payment_gateways/pay_pal_service.dart';
import 'package:streamit_laravel/screens/subscription/components/plan_confirmation_dialog.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../network/auth_apis.dart';
import '../../network/core_api.dart';
import '../../utils/common_base.dart';
import '../dashboard/dashboard_screen.dart';
import '../subscription/model/subscription_plan_model.dart';
import 'payment_gateways/flutter_wave_service.dart';
import 'payment_gateways/pay_stack_service.dart';
import 'payment_gateways/razor_pay_service.dart';
import 'payment_gateways/stripe_services.dart';

class PaymentController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isPaymentLoading = false.obs;
  RxString paymentOption = PaymentMethods.PAYMENT_METHOD_STRIPE.obs;
  RxList<PaymentSetting> originalPaymentList = RxList();
  Rx<Future<RxList<PaymentSetting>>> getPaymentFuture = Future(() => RxList<PaymentSetting>()).obs;
  Rx<SubscriptionPlanModel> selectPlan = SubscriptionPlanModel().obs;
  RxDouble price = 0.0.obs;
  RxDouble discount = 0.0.obs;
  Rx<DateTime> currentDate = DateTime.now().obs;
  Rx<PaymentSetting> selectPayment = PaymentSetting().obs;

  // Payment Class
  RazorPayService razorPayService = RazorPayService();
  PayStackService paystackServices = PayStackService();

  PayPalService payPalService = PayPalService();
  FlutterWaveService flutterWaveServices = FlutterWaveService();

  Rx<Future<RxBool>> getPaymentInitialized = Future(() => false.obs).obs;

  RxBool launchDashboard = true.obs;

  @override
  void onInit() {
    if (Get.arguments[0] is SubscriptionPlanModel) {
      selectPlan(Get.arguments[0]);
      price(Get.arguments[1]);
      discount(Get.arguments[2]);
      launchDashboard(Get.arguments[3]);
    }
    allApisCalls();
    super.onInit();
  }

  allApisCalls() async {
    await getAppConfigurations();
  }

  Future<void> getAppConfigurations() async {
    isPaymentLoading(true);
    await AuthServiceApis.getAppConfigurations(forceSync: true).then((value) async {
      getPaymentInitialized(Future(() async {
        return getPayment(); // Wrap the bool in RxBool
      })).whenComplete(() => isLoading(false));
    }).onError((error, stackTrace) {
      toast(error.toString());
    }).whenComplete(() {
      isPaymentLoading(false);
    });
  }

  Future<void> initInAppPurchase() async {}

  ///Get Payment List
  Future<RxBool> getPayment({bool showLoader = true}) async {
    isPaymentLoading(showLoader);
    originalPaymentList.clear();
    if (appConfigs.value.stripePay.stripePublickey.isNotEmpty) {
      originalPaymentList.add(
        PaymentSetting(
          id: 0,
          title: locale.value.stripePay,
          type: PaymentMethods.PAYMENT_METHOD_STRIPE,
          liveValue: LiveValue(stripePublickey: appConfigs.value.stripePay.stripePublickey, stripeKey: appConfigs.value.stripePay.stripeSecretkey),
        ),
      );
    }
    if (appConfigs.value.razorPay.razorpayPublickey.isNotEmpty) {
      originalPaymentList.add(
        PaymentSetting(
          id: 1,
          title: locale.value.razorPay,
          type: PaymentMethods.PAYMENT_METHOD_RAZORPAY,
          liveValue: LiveValue(razorKey: appConfigs.value.razorPay.razorpayPublickey, razorSecret: appConfigs.value.razorPay.razorpaySecretkey),
        ),
      );
    }
    if (appConfigs.value.payStackPay.paystackPublickey.isNotEmpty) {
      originalPaymentList.add(
        PaymentSetting(
          id: 2,
          title: locale.value.payStackPay,
          type: PaymentMethods.PAYMENT_METHOD_PAYSTACK,
          liveValue: LiveValue(paystackPublicKey: appConfigs.value.payStackPay.paystackPublickey, paystackSecrateKey: appConfigs.value.payStackPay.paystackPublickey),
        ),
      );
    }
    if (appConfigs.value.paypalPay.paypalClientid.isNotEmpty) {
      originalPaymentList.add(
        PaymentSetting(
          id: 3,
          title: locale.value.paypalPay,
          type: PaymentMethods.PAYMENT_METHOD_PAYPAL,
          liveValue: LiveValue(payPalClientId: appConfigs.value.paypalPay.paypalClientid, payPalSecretKey: appConfigs.value.paypalPay.paypalSecretkey),
        ),
      );
    }
    if (appConfigs.value.flutterWavePay.flutterwavePublickey.isNotEmpty) {
      originalPaymentList.add(
        PaymentSetting(
          id: 4,
          title: locale.value.flutterWavePay,
          type: PaymentMethods.PAYMENT_METHOD_FLUTTER_WAVE,
          liveValue: LiveValue(flutterwavePublic: appConfigs.value.flutterWavePay.flutterwavePublickey, flutterwaveSecret: appConfigs.value.flutterWavePay.flutterwaveSecretkey),
        ),
      );
    }
    isPaymentLoading(false);

    return true.obs;
  }

  /// handle Payment Click

  handlePayNowClick(BuildContext context) {
    showInDialog(
      context,
      contentPadding: EdgeInsets.zero,
      builder: (context) {
        return PlanConfirmationDialog(
          titleText: "${locale.value.doYouConfirmThisPlan}${selectPlan.value.name} ?",
          onConfirm: () {
            Get.back();
            if (paymentOption.value == PaymentMethods.PAYMENT_METHOD_STRIPE) {
              payWithStripe();
            } else if (paymentOption.value == PaymentMethods.PAYMENT_METHOD_RAZORPAY) {
              payWithRazorPay();
            } else if (paymentOption.value == PaymentMethods.PAYMENT_METHOD_PAYSTACK) {
              payWithPayStack(context);
            } else if (paymentOption.value == PaymentMethods.PAYMENT_METHOD_FLUTTER_WAVE) {
              payWithFlutterWave(context);
            } else if (paymentOption.value == PaymentMethods.PAYMENT_METHOD_PAYPAL) {
              payWithPaypal(context);
            } else if (paymentOption.value == PaymentMethods.PAYMENT_METHOD_IN_APP_PURCHASE) {
              payWithPaypal(context);
            }
          },
        );
      },
    );
  }

  payWithStripe() async {
    await StripeServices.stripePaymentMethod(
      loderOnOFF: (p0) {
        isLoading(p0);
      },
      amount: price.value.validate(),
      onComplete: (res) {
        saveSubscriptionDetails(transactionId: res["transaction_id"].toString(), paymentType: PaymentMethods.PAYMENT_METHOD_STRIPE);
        log('TRANSACTION_ID============================ ${res["transaction_id"]}');
        //saveSubscriptionPlan(paymentType: PaymentMethods.PAYMENT_METHOD_STRIPE, txnId: res["transaction_id"], paymentStatus: PaymentStatus.PAID);
      },
    ).catchError(onError);
  }

  payWithRazorPay() async {
    isLoading(true);
    razorPayService.init(
      razorKey: appConfigs.value.razorPay.razorpaySecretkey, //"rzp_test_CLw7tH3O3P5eQM"
      totalAmount: price.value.validate(),
      onComplete: (res) {
        log("txn id: $res");
        saveSubscriptionDetails(transactionId: res["transaction_id"].toString(), paymentType: PaymentMethods.PAYMENT_METHOD_RAZORPAY);
        //saveSubscriptionPlan(paymentType: PaymentMethods.PAYMENT_METHOD_RAZORPAY, txnId: res["transaction_id"], paymentStatus: PaymentStatus.PAID);
      },
    );
    await Future.delayed(const Duration(seconds: 1));
    razorPayService.razorPayCheckout();
    await Future.delayed(const Duration(seconds: 2));
    isLoading(false);
  }

  payWithPayStack(BuildContext context) async {
    isLoading(true);
    await paystackServices.init(
      loaderOnOff: (p0) {
        isLoading(p0);
      },
      ctx: context,
      totalAmount: price.value.validate(),
      onComplete: (res) {
        saveSubscriptionDetails(transactionId: res["transaction_id"].toString(), paymentType: PaymentMethods.PAYMENT_METHOD_PAYSTACK);
        // toast("==============Completed=================", print: true);
        // saveSubscriptionPlan(paymentType: PaymentMethods.PAYMENT_METHOD_PAYSTACK, txnId: res["transaction_id"], paymentStatus: PaymentStatus.PAID);
      },
    );
    await Future.delayed(const Duration(seconds: 1));
    isLoading(false);
    if (Get.context != null) {
      paystackServices.checkout();
    } else {
      toast(locale.value.contextNotFound);
    }
  }

  payWithPaypal(BuildContext context) {
    isLoading(true);
    payPalService.paypalCheckOut(
      context: context,
      loderOnOFF: (p0) {
        isLoading(p0);
      },
      totalAmount: price.value.validate(),
      onComplete: (res) {
        saveSubscriptionDetails(transactionId: res["transaction_id"].toString(), paymentType: PaymentMethods.PAYMENT_METHOD_PAYPAL);
        // toast("==============Completed=================", print: true);
        //saveSubscriptionPlan(paymentType: PaymentMethods.PAYMENT_METHOD_PAYPAL, txnId: res["transaction_id"], paymentStatus: PaymentStatus.PAID);
      },
    );
  }

  payWithFlutterWave(BuildContext context) async {
    isLoading(true);
    flutterWaveServices.checkout(
      ctx: context,
      loderOnOFF: (p0) {
        isLoading(p0);
      },
      totalAmount: price.value.validate(),
      isTestMode: appConfigs.value.flutterWavePay.flutterwavePublickey.toLowerCase().contains("test"),
      onComplete: (res) {
        saveSubscriptionDetails(transactionId: res["transaction_id"].toString(), paymentType: PaymentMethods.PAYMENT_METHOD_FLUTTER_WAVE);
        // toast("==============Completed=================", print: true);
        //saveSubscriptionDetails(plan_id: res[""], user_id: user_id, identifier: identifier, payment_status: payment_status, payment_type: payment_type, transaction_id: transaction_id)
        //saveSubscriptionPlan(paymentType: PaymentMethods.PAYMENT_METHOD_FLUTTER_WAVE, txnId: res["transaction_id"], p.
        //
        //
        //aymentStatus: PaymentStatus.PAID);
      },
    );
    await Future.delayed(const Duration(seconds: 1));
    isLoading(false);
  }

  handleInAppPurchase({required Map<String, dynamic> res}) {
    saveSubscriptionDetails(
      transactionId: res["transaction_id"].toString(),
      paymentType: PaymentMethods.PAYMENT_METHOD_IN_APP_PURCHASE,
    );
  }

//saveSubscriptionDetails

  saveSubscriptionDetails({required String transactionId, required String paymentType}) {
    isLoading(true);
    Map<String, dynamic> request = {
      "plan_id": selectPlan.value.planId,
      "user_id": loginUserData.value.id,
      "identifier": selectPlan.value.name.validate(),
      "payment_status": PaymentStatus.PAID,
      "payment_type": paymentType,
      "transaction_id": transactionId.validate(),
      'device_id': yourDevice.value.deviceId,
    };

    if (paymentType == PaymentMethods.PAYMENT_METHOD_IN_APP_PURCHASE) {
      request.putIfAbsent(
        'active_in_app_purchase_identifier',
        () => isIOS ? selectPlan.value.appleInAppPurchaseIdentifier : selectPlan.value.googleInAppPurchaseIdentifier,
      );
    }
    CoreServiceApis.saveSubscriptionDetails(
      request: request,
    ).then((value) async {
      if (launchDashboard.value) {
        Get.offAll(() => DashboardScreen(dashboardController: getDashboardController()));
      } else {
        Get.back();
        Get.back();
      }

      setValue(SharedPreferenceConst.USER_DATA, loginUserData.toJson());
      // successSnackBar(value.message.toString());
      currentSubscription(value.data);
      if (currentSubscription.value.level > -1 && currentSubscription.value.planType.isNotEmpty && currentSubscription.value.planType.any((element) => element.slug == SubscriptionTitle.videoCast)) {
        isCastingSupported(currentSubscription.value.planType.firstWhere((element) => element.slug == SubscriptionTitle.videoCast).limitationValue.getBoolInt());
      } else {
        isCastingSupported(false);
      }
      currentSubscription.value.activePlanInAppPurchaseIdentifier = isIOS ? currentSubscription.value.appleInAppPurchaseIdentifier : currentSubscription.value.googleInAppPurchaseIdentifier;
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
}