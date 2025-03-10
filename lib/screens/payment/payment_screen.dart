import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/payment/components/payment_card_component.dart';
import 'package:streamit_laravel/screens/payment/payment_controller.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/generated/assets.dart';

import '../../components/app_scaffold.dart';
import '../../components/cached_image_widget.dart';
import '../../components/loader_widget.dart';
import '../../main.dart';
import '../../utils/common_base.dart';
import '../../utils/empty_error_state_widget.dart';
import 'components/selected_plan_component.dart';

class PaymentScreen extends StatelessWidget {
  PaymentScreen({super.key});

  final PaymentController paymentCont = Get.put(PaymentController());

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      isLoading: false.obs,
      scaffoldBackgroundColor: appScreenBackgroundDark,
      appBartitleText: locale.value.subscrption,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectedPlanComponent(planDetails: paymentCont.selectPlan.value, price: paymentCont.price.value),
          24.height,
          Text(
            locale.value.choosePaymentMethod,
            style: boldTextStyle(size: 18, color: white),
          ),
          24.height,
          Obx(
            () {
              return SnapHelperWidget(
                future: paymentCont.getPaymentInitialized.value,
                loadingWidget: paymentCont.isPaymentLoading.isTrue
                    ? SizedBox(
                        width: Get.width,
                        height: Get.height * 0.20,
                        child: const LoaderWidget(),
                      ).center()
                    : Offstage(),
                onSuccess: (data) {
                  if (paymentCont.originalPaymentList.isEmpty && paymentCont.isPaymentLoading.isFalse) {
                    return NoDataWidget(
                      titleTextStyle: secondaryTextStyle(color: white, size: 16),
                      subTitleTextStyle: primaryTextStyle(color: white),
                      title: locale.value.noPaymentMethodsFound,
                      retryText: locale.value.reload,
                      imageWidget: const EmptyStateWidget(),
                      onRetry: () {
                        paymentCont.getPayment(showLoader: true); // Retry fetching payment methods
                      },
                    ).center();
                  } else {
                    return AnimatedListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: paymentCont.originalPaymentList.length,
                      // Number of payment methods
                      itemBuilder: (context, index) {
                        return PaymentCardComponent(
                          paymentDetails: paymentCont.originalPaymentList[index], // Payment method details
                        ).paddingBottom(12); // Add padding between items
                      },
                    );
                  }
                },
              );
            },
          )
        ],
      ).paddingSymmetric(horizontal: 16),
      bottomNavBar: Obx(
        () => Container(
          height: 100,
          width: double.infinity,
          color: appScreenBackgroundDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              12.height,
              AppButton(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                text: locale.value.proceedPayment,
                color: paymentCont.selectPayment.value.title?.isNotEmpty ?? false ? appColorPrimary : lightBtnColor,
                textStyle: appButtonTextStyleWhite,
                shapeBorder: RoundedRectangleBorder(borderRadius: radius(6)),
                onTap: () {
                  if (isLoggedIn.isTrue) {
                    if (paymentCont.selectPayment.value.id != null) {
                      if (paymentCont.isLoading.isFalse) {
                        paymentCont.handlePayNowClick(context);
                      } else {
                        return;
                      }
                    } else {
                      // toast(locale.value.pleaseSelectPaymentMethod);
                    }
                  } else {
                    // toast(locale.value.pleaseLogInFirstThenProceedToSubscribe);
                  }
                },
              ),
              10.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CachedImageWidget(
                    url: Assets.iconsIcShieldCheck,
                    height: 16,
                    width: 16,
                    color: darkGrayTextColor,
                  ),
                  10.width,
                  Text(
                    locale.value.secureCheckoutInSeconds,
                    style: secondaryTextStyle(
                      size: 14,
                      color: darkGrayTextColor,
                      weight: FontWeight.w500,
                    ),
                  )
                ],
              ),
              12.height,
            ],
          ).paddingSymmetric(horizontal: 16),
        ),
      ),
    );
  }
}
