// ignore_for_file: constant_identifier_names

//region constsnats
import 'dart:ui';

import 'package:flutter/material.dart';

class Constants {
  static const perPageItem = 20;
  static var labelTextSize = 16;
  static var googleMapPrefix = 'https://www.google.com/maps/search/?api=1&query=';
  static const DEFAULT_EMAIL = 'john@gmail.com';
  static const DEFAULT_PASS = '12345678';
  static const appLogoSize = 120.0;
  static const DECIMAL_POINT = 2;
  static const double shimmerTextSize = 12;
  static const String defaultNumber = '+911234567890';

  static const String demoNumber = '1234567890';

  static const double commonDialogBoxRadius = 32;

  static List<String> rtlLanguage = [
    'ar', // Arabic
    'he', // Hebrew
    'fa', // Persian (Farsi)
    'ur', // Urdu
    'yi', // Yiddish
    'dv', // Divehi (Maldivian)
    'ps', // Pashto
    'syr', // Syriac
  ];
}
//endregion

//region DateFormats
class DateFormatConst {
  static const DD_MM_YY = "dd-MM-yy";
  static const MMMM_D_yyyy = "MMMM d, y";
  static const D_MMMM_yyyy = "d MMMM, y";
  static const MMMM_D_yyyy_At_HH_mm_a = "MMMM d, y @ hh:mm a";
  static const EEEE_D_MMMM_At_HH_mm_a = "EEEE d MMMM @ hh:mm a";
  static const dd_MMM_yyyy_HH_mm_a = "dd MMM y, hh:mm a";
  static const yyyy_MM_dd_HH_mm = 'yyyy-MM-dd HH:mm';
  static const yyyy_MM_dd = 'yyyy-MM-dd';
  static const HH_mm12Hour = 'hh:mm a';
  static const HH_mm24Hour = 'HH:mm';
}
//endregion

//region THEME MODE TYPE
const THEME_MODE_LIGHT = 0;
const THEME_MODE_DARK = 1;
const THEME_MODE_SYSTEM = 2;
//endregion

// region Live Stream Constant keys

const podPlayerPauseKey = "pause_pod_player";
const changeVideoInPodPlayer = "changeVideoInPodPlayer";
const mOnWatchVideo = "onWatchVideo";
const onAddVideoQuality = "onAddVideoQuality";
const VIDEO_PLAYER_REFRESH_EVENT = 'video_player_refresh';
//endregion

//region UserKeys
class UserKeys {
  static String firstName = 'first_name';
  static String lastName = 'last_name';
  static String userType = 'user_type';
  static String username = 'username';
  static String email = 'email';
  static String password = 'password';
  static String mobile = 'mobile';
  static String address = 'address';
  static String displayName = 'display_name';
  static String profileImage = 'profile_image';
  static String oldPassword = 'old_password';
  static String newPassword = 'new_password';
  static String loginType = 'login_type';
  static String contactNumber = 'contact_number';
  static String fileUrl = 'file_url';
}
//endregion

//region LOGIN TYPE
class LoginTypeConst {
  static const LOGIN_TYPE_USER = 'user';
  static const LOGIN_TYPE_GOOGLE = 'google';
  static const LOGIN_TYPE_APPLE = 'apple';
  static const LOGIN_TYPE_OTP = 'otp';
}
//endregion

//region SharedPreference Keys
class SharedPreferenceConst {
  static const IS_LOGGED_IN = 'IS_LOGGED_IN';
  static const USER_DATA = 'USER_LOGIN_DATA';
  static const USER_EMAIL = 'USER_EMAIL';
  static const USER_PASSWORD = 'USER_PASSWORD';
  static const FIRST_TIME = 'FIRST_TIME';
  static const IS_REMEMBER_ME = 'IS_REMEMBER_ME';
  static const USER_NAME = 'USER_NAME';
  static const IS_FIRST_TIME = 'IS_FIRST_TIME';

  static const IS_FIRST_TIME_18 = 'IS_FIRST_TIME_18';
  static const IS_INDEX_0 = 'IS_INDEX_0';
  static const IS_18_PLUS = 'IS_18_PLUS';
  static const DOWNLOAD_VIDEOS = 'DOWNLOAD_VIDEOS';
  static const LAST_APP_CONFIGURATION_CALL_TIME = 'APP_CONFIGURATION_CALL_TIME';
  static const IS_APP_CONFIGURATION_SYNCED_ONCE = 'IS_APP_CONFIGURATION_SYNCED_ONCE';
  static const IS_PROFILE_ID = 'IS_PROFILE_ID';
  static const SUBSCRIPTION_PLAN_IDENTIFIER = 'SUBSCRIPTION_PLAN_IDENTIFIER';
  static const SUBSCRIPTION_PLAN_GOOGLE_IDENTIFIER = 'SUBSCRIPTION_PLAN_GOOGLE_IDENTIFIER';
  static const SUBSCRIPTION_PLAN_APPLE_IDENTIFIER = 'SUBSCRIPTION_PLAN_APPLE_IDENTIFIER';
  static const SUBSCRIPTION_ENTITLEMENT_ID = 'SUBSCRIPTION_ENTITLEMENT_ID';
  static const SUBSCRIPTION_GOOGLE_API_KEY = 'SUBSCRIPTION_GOOGLE_API_KEY';
  static const SUBSCRIPTION_APPLE_API_KEY = 'SUBSCRIPTION_APPLE_API_KEY';
  static const HAS_IN_APP_PURCHASE_ENABLE = 'HAS_IN_APP_PURCHASE_ENABLE';
  static const HAS_IN_APP_SDK_INITIALISE_AT_LEASE_ONCE = 'HAS_IN_APP_SDK_INITIALISE_AT_LEASE_ONCE';
  static const HAS_IN_APP_USER_LOGIN_DONE_AT_LEASE_ONCE = 'HAS_IN_APP_USER_LOGIN_DONE_AT_LEASE_ONCE';
  static const HAS_PURCHASE_STORED = 'HAS_PURCHASE_STORED';
  static const PURCHASE_REQUEST = 'PURCHASE_REQUEST';
  static const IS_SUBSCRIPTION_PURCHASE_RESTORE_REQUIRED = 'IS_SUBSCRIPTION_PURCHASE_RESTORE_REQUIRED';
  static const IS_SUPPORTED_DEVICE = 'IS_SUPPORTED_DEVICE';

  // locale
  static const SETTINGS_LIST = 'SETTINGS_LIST';
  static const DOWNLOAD_KEY = 'Download';

  static const POPULAR_MOVIE = 'POPULAR_MOVIE';

  static const CONFIGURATION_RESPONSE = 'CONFIGURATION_RESPONSE';

  static const DASHBOARD_DETAIL_LAST_CALL_TIME = 'DASHBOARD_DETAIL_CALL_TIME';

  static const PAGE_LAST_CALL_TIME = 'PAGE_LAST_CALL_TIME';

  static const FAQ_LAST_CALL_TIME = 'FAQ_LAST_CALL_TIME';

  static const CACHE_DASHBOARD = 'CACHE_DASHBOARD';
  static const CACHE_LIVE_TV_DASHBOARD = 'CACHE_LIVE_TV_DASHBOARD';
  static const CACHE_PROFILE_DETAIL = 'CACHE_PROFILE_DETAIL';
  static const CACHE_MOVIE_LIST = 'CACHE_MOVIE_LIST';
  static const CACHE_TV_SHOW_LIST = 'CACHE_TV_SHOW_LIST';
  static const CACHE_VIDEO_LIST = 'CACHE_VIDEO_LIST';
  static const CACHE_GENRE_LIST = 'CACHE_GENRE_LIST';

  static const CACHE_ACTOR_LIST = 'CACHE_ACTOR_LIST';

  static const USER_SUBSCRIPTION_DATA = 'USER_SUBSCRIPTION_DATA';
}
//endregion

//region SettingsLocalConst
class SettingsLocalConst {
  static const THEME_MODE = 'THEME_MODE';
}
//endregion

//region Currency position
class CurrencyPosition {
  static const CURRENCY_POSITION_LEFT = 'left';
  static const CURRENCY_POSITION_RIGHT = 'right';
  static const CURRENCY_POSITION_LEFT_WITH_SPACE = 'left_with_space';
  static const CURRENCY_POSITION_RIGHT_WITH_SPACE = 'right_with_space';
}
//endregion

//region Gender TYPE
class GenderTypeConst {
  static const MALE = 'male';
  static const FEMALE = 'female';
}
//endregion

//region PaymentStatus
class PaymentStatus {
  static const PAID = 'paid';
  static const pending = 'pending';
  static const failed = 'failed';
}
//endregion

//region Firebase Topic keys
class FirebaseMsgConst {
  //Other Consts
  static const topicSubscribed = 'topic-----subscribed---->';
  static const topicUnSubscribed = 'topic-----UnSubscribed---->';
  static const userWithUnderscoreKey = 'user_';

  static const additionalDataKey = 'additional_data';
  static const notificationGroupKey = 'notification_group';
  static const idKey = 'id';
  static const notificationDataKey = 'Notification Data';
  static const fcmNotificationTokenKey = 'FCM Notification Token';
  static const apnsNotificationTokenKey = 'APNS Notification Token';
  static const notificationErrorKey = 'Notification Error';
  static const notificationTitleKey = 'Notification Title';

  static const notificationKey = 'Notification';

  static const onClickListener = "Error On Notification Click Listener";
  static const onMessageListen = "Error On Message Listen";
  static const onMessageOpened = "Error On Message Opened App";
  static const onGetInitialMessage = 'Error On Get Initial Message';

  static const messageDataCollapseKey = 'MessageData Collapse Key';

  static const messageDataMessageIdKey = 'MessageData Message Id';

  static const messageDataMessageTypeKey = 'MessageData Type';
  static const notificationBodyKey = 'Notification Body';
  static const backgroundChannelIdKey = 'background_channel';
  static const backgroundChannelNameKey = 'background_channel';

  static const notificationChannelIdKey = 'notification';
  static const notificationChannelNameKey = 'Notification';
  static const postTypeKey = 'post_type';
  static const movieKey = 'movie';
  static const tvShowKey = 'tv_show';
  static const episodeKey = 'episode';
  static const videoKey = 'video';

  static const notificationType = 'type';

  static const newContentType = 'new-content';
}
//endregion

//region Payment Methods
class PaymentMethods {
  static const PAYMENT_METHOD_CASH = 'cash';
  static const PAYMENT_METHOD_STRIPE = 'stripe';
  static const PAYMENT_METHOD_RAZORPAY = 'razorpay';
  static const PAYMENT_METHOD_PAYPAL = 'paypal';
  static const PAYMENT_METHOD_PAYSTACK = 'paystack';
  static const PAYMENT_METHOD_FLUTTER_WAVE = 'flutterwave';
  static const PAYMENT_METHOD_AIRTEL = 'airtel';
  static const PAYMENT_METHOD_PHONEPE = 'phonepe';
  static const PAYMENT_METHOD_MIDTRANS = 'midtrans';
  static const PAYMENT_METHOD_IN_APP_PURCHASE = 'IN_APP_PURCHASE';
}
//endregion

//region Page slug
class AppPages {
  static const termsAndCondition = 'terms-conditions';
  static const privacyPolicy = 'privacy-policy';
  static const helpAndSupport = 'help-and-support';
  static const refundAndCancellation = 'refund-and-cancellation-policy';
  static const dataDeletion = 'data-deletation-request';
  static const faq = 'faq';
  static const aboutUs = 'about-us';
}
//endregion

//region Theme Constants

class ThemeConstants {
  //region FontWeight
  static const FontWeight genreFontWeight = FontWeight.w600;

  static const FontWeight titleFontWeight = FontWeight.w500;

//endregion
}
//endregion

class SubscriptionTitle {
  static const videoCast = 'video-cast';
  static const ads = 'ads';
  static const deviceLimit = 'device-limit';
  static const downloadStatus = 'download-status';
  static const supportedDeviceType = 'supported-device-type';
  static const profileLimit = 'profile-limit';
}

class VideoType {
  static const movie = 'movie';
  static const tvshow = 'tvshow';
  static const episode = 'episode';
  static const liveTv = 'livetv';
  static const video = 'video';
}

class SubscriptionStatus {
  static const active = 'active';
  static const cancel = 'cancel';
  static const inActive = 'inactive';

  static const deActive = 'deactivated';
}

class MovieAccess {
  static const paidAccess = 'paid';
  static const freeAccess = 'free';
}
