import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/profile/model/profile_detail_resp.dart';
import 'package:streamit_laravel/utils/app_common.dart';

import '../../network/core_api.dart';
import '../../utils/constants.dart';
import '../subscription/model/subscription_plan_model.dart';

class ProfileController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  RxBool isProfileLoggedIn = false.obs;
  Rx<Future<ProfileDetailResponse>> getProfileDetailsFuture = Future(() => ProfileDetailResponse(data: ProfileModel(planDetails: SubscriptionPlanModel()))).obs;
  Rx<ProfileModel> profileDetailsResp = ProfileModel(planDetails: SubscriptionPlanModel()).obs;

  @override
  void onInit() {
    if (cachedProfileDetails != null) {
      profileDetailsResp(cachedProfileDetails?.data);
    }
    super.onInit();
    getProfile();
    getProfileDetail();
  }

  getProfile() {
    if (isLoggedIn.isTrue) {
      isProfileLoggedIn(true);
    } else {
      isProfileLoggedIn(false);
    }
  }

  ///Get Profile List
  getProfileDetail({bool showLoader = true}) async {
    if (isLoggedIn.isTrue) {
      if (showLoader) {
        isLoading(true);
      }
      await getProfileDetailsFuture(CoreServiceApis.getProfileDet()).then((value) {
        profileDetailsResp(value.data);
        currentSubscription(value.data.planDetails);
        if (currentSubscription.value.level > -1 && currentSubscription.value.planType.isNotEmpty && currentSubscription.value.planType.any((element) => element.slug == SubscriptionTitle.videoCast)) {
          isCastingSupported(currentSubscription.value.planType.firstWhere((element) => element.slug == SubscriptionTitle.videoCast).limitationValue.getBoolInt());
        } else {
          isCastingSupported(false);
        }
        currentSubscription.value.activePlanInAppPurchaseIdentifier = isIOS ? currentSubscription.value.appleInAppPurchaseIdentifier : currentSubscription.value.googleInAppPurchaseIdentifier;
        setValue(SharedPreferenceConst.USER_SUBSCRIPTION_DATA, value.data.planDetails.toJson());
      }).whenComplete(() {
        isLoading(false);
      });
    }
  }
}