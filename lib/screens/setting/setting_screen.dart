import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/download_videos/download_video.dart';
import 'package:streamit_laravel/screens/setting/faq/f_a_q_screen.dart';
import 'package:streamit_laravel/screens/setting/language/language_screen.dart';
import 'package:streamit_laravel/screens/setting/setting_controller.dart';
import 'package:streamit_laravel/screens/setting/subscription_history/subscription_history_screen.dart';
import 'package:streamit_laravel/screens/watch_list/watch_list_screen.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart';

import '../../components/app_scaffold.dart';
import '../../main.dart';
import '../../utils/constants.dart';
import '../auth/change_password/change_password_screen.dart';
import 'account_setting/account_setting_screen.dart';
import 'account_setting/components/logout_account_component.dart';
import 'account_setting/shimmer_account_setting.dart';

class SettingScreen extends StatelessWidget {
  final SettingController settingCont;

  const SettingScreen({super.key, required this.settingCont});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      isLoading: settingCont.isLoading,
      scaffoldBackgroundColor: appScreenBackgroundDark,
      appBartitleText: locale.value.helpSetting,
      body: AnimatedScrollView(
        padding: EdgeInsets.only(bottom: 120, top: 8),
        physics: AlwaysScrollableScrollPhysics(),
        refreshIndicatorColor: appColorPrimary,
        onSwipeRefresh: () async {
          await settingCont.init(true);
        },
        children: [
          Obx(
            () => SnapHelperWidget(
              future: settingCont.getSettingInitialize.value,
              loadingWidget: const ShimmerAccountSetting(),
              onSuccess: (data) {
                if (data.isFalse && settingCont.isLoading.isTrue) {
                  return const ShimmerAccountSetting();
                } else {
                  return ListView.builder(
                      itemCount: settingCont.settingList.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        SettingModel settingData = settingCont.settingList[index];
                        return InkWell(
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onTap: () {
                            navigateScreen(aboutDataModel: settingData);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: boxDecorationDefault(
                              color: canvasColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  settingData.icon,
                                  height: 16,
                                  width: 16,
                                  fit: BoxFit.cover,
                                  color: iconColor,
                                ),
                                16.width,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Marquee(
                                      child: Text(
                                        settingData.title,
                                        style: primaryTextStyle(),
                                      ),
                                    ),
                                    6.height.visible(settingData.subTitle?.isNotEmpty ?? false),
                                    Text(
                                      settingData.subTitle ?? "",
                                      style: secondaryTextStyle(),
                                    ).visible(settingData.subTitle?.isNotEmpty ?? false),
                                  ],
                                ).expand(),
                                if (settingData.showArrow)
                                  const Icon(
                                    Icons.keyboard_arrow_right_rounded,
                                    size: 18,
                                    color: iconColor,
                                  )
                              ],
                            ),
                          ),
                        );
                      }).visible(data.isTrue && settingCont.isLoading.isFalse);
                }
              },
            ),
          ),
        ],
      ),
      bottomNavBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          VersionInfoWidget(
            prefixText: '${locale.value.version}: ',
            textStyle: boldTextStyle(
              size: 14,
            ),
          ).paddingSymmetric(vertical: 16),
        ],
      ),
    );
  }

  void navigateScreen({required SettingModel aboutDataModel}) {
    if (aboutDataModel.title == locale.value.appLanguage) {
      Get.to(() => LanguageScreen(settingController: settingCont));
    } else if (aboutDataModel.title == locale.value.accountSettings) {
      log(settingCont.profileDetailsResp.value.toJson());
      Get.to(() => AccountSettingScreen(profileInfo: settingCont.profileDetailsResp.value, settingController: settingCont));
    } else if (aboutDataModel.title == locale.value.changePassword) {
      Get.to(() => ChangePasswordScreen());
    } else if (aboutDataModel.title == locale.value.subscriptionHistory) {
      Get.to(() => SubscriptionHistoryScreen());
    } else if (aboutDataModel.title == locale.value.yourDownloads) {
      Get.to(() => DownloadVideosScreen());
    } else if (aboutDataModel.title == locale.value.watchlist) {
      Get.to(() => WatchListScreen());
    } else if ((aboutDataModel.slug == AppPages.aboutUs ||
        aboutDataModel.slug == AppPages.privacyPolicy ||
        aboutDataModel.slug == AppPages.termsAndCondition ||
        aboutDataModel.slug == AppPages.aboutUs ||
        aboutDataModel.slug == AppPages.dataDeletion ||
        aboutDataModel.slug == AppPages.refundAndCancellation)) {
      if (aboutDataModel.url.isNotEmpty) launchUrlCustomURL(aboutDataModel.url);
    } else if (aboutDataModel.title == locale.value.faqs) {
      Get.to(
        () => FAQScreen(
          faqList: settingCont.faqList,
          settingController: settingCont,
        ),
      );
    } else if (aboutDataModel.title == locale.value.logout) {
      Get.bottomSheet(
        isDismissible: true,
        isScrollControlled: true,
        enableDrag: false,
        LogoutAccountComponent(
          device: yourDevice.value.deviceId,
          deviceName: yourDevice.value.deviceName,
          onLogout: (logoutAll) async {
            settingCont.logoutCurrentUser();
          },
        ),
      );
    } else {
      if (aboutDataModel.url.isNotEmpty) launchUrlCustomURL(aboutDataModel.url);
    }
  }
}

class SettingModel {
  final String title;
  final String? subTitle;
  final String icon;
  final String url;
  final String slug;
  final bool showArrow;

  SettingModel({
    required this.title,
    required this.icon,
    this.subTitle,
    this.showArrow = false,
    this.slug = '',
    this.url = '',
  });
}
