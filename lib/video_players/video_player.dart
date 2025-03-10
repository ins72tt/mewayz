import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pod_player/pod_player.dart';
import 'package:streamit_laravel/components/device_not_supported_widget.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/extension/string_extention.dart';
import 'package:streamit_laravel/video_players/video_description_widget.dart';

import '../components/cached_image_widget.dart';
import '../components/loader_widget.dart';
import '../components/youtube_webview_iframe.dart';
import '../main.dart';
import '../screens/live_tv/live_tv_details/model/live_tv_details_response.dart';
import '../screens/tv_show/episode/models/episode_model.dart';
import '../utils/colors.dart';
import '../utils/common_base.dart';
import 'embedded_video/embedded_video_player.dart';
import 'model/video_model.dart';
import 'video_player_controller.dart';

class VideoPlayersComponent extends StatelessWidget {
  final VideoPlayerModel videoModel;
  final LiveShowModel? liveShowModel;
  final bool isTrailer;
  final bool isPipMode;
  final bool hasNextEpisode;
  final bool isFromDownloads;
  final bool isLoading;

  List<EpisodeModel> episodeList;

  final VoidCallback? onWatchNow;

  final bool showWatchNow;

  VideoPlayersComponent({
    super.key,
    required this.videoModel,
    this.liveShowModel,
    this.isTrailer = true,
    this.isPipMode = false,
    this.hasNextEpisode = false,
    this.isFromDownloads = false,
    this.isLoading = false,
    this.episodeList = const <EpisodeModel>[],
    this.onWatchNow,
    this.showWatchNow = false,
  });

  late final VideoPlayersController controller = Get.put(
    VideoPlayersController(
      isTrailer: isTrailer.obs,
      videoModel: videoModel,
      liveShowModel: liveShowModel ?? LiveShowModel(),
      hasNextVideo: hasNextEpisode,
    ),
  );

  bool get isLive => liveShowModel != null;

  bool get isVideoTypeYoutube => isLive
      ? liveShowModel?.streamType == PlayerTypes.youtube
      : (controller.isTrailer.isTrue ? videoModel.trailerUrlType.toLowerCase() == PlayerTypes.youtube : videoModel.videoUploadType.toLowerCase() == PlayerTypes.youtube);

  bool get isVideoTypeOther => !isLive && videoModel.type.toLowerCase() != PlayerTypes.youtube && (videoModel.trailerUrl.isNotEmpty || videoModel.videoUrlInput.isNotEmpty);

  bool get isVimeo => (videoModel.videoUploadType == PlayerTypes.vimeo || videoModel.videoUrlInput.contains('vimeo')) && videoModel.videoUrlInput.isNotEmpty;

  String getVideoURLLink() {
    String url = "";
    if (isLive) {
      url = controller.liveShowModel.posterImage;
    } else {
      if (videoModel.thumbnailImage.isNotEmpty) {
        url = videoModel.thumbnailImage;
      } else if (videoModel.posterImage.isNotEmpty) {
        url = videoModel.posterImage;
      } else {}
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: isPipModeOn.value ? 110 : 220,
              width: Get.width,
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  if (isLoggedIn.value) ...[
                    if (controller.isTrailer.isFalse && !isSupportedDevice.value)
                      DeviceNotSupportedComponent(title: videoModel.name)
                    else ...[
                      if (controller.isBuffering.isTrue)
                        SizedBox(
                          height: isPipModeOn.value ? 110 : 220,
                          width: Get.width,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (getVideoURLLink().isNotEmpty)
                                Image.network(
                                  getVideoURLLink(),
                                  height: isPipModeOn.value ? 110 : 200,
                                  width: Get.width,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium,
                                )
                              else
                                Container(
                                  height: isPipModeOn.value ? 110 : 200,
                                  width: Get.width,
                                  decoration: boxDecorationDefault(color: context.cardColor, borderRadius: radius(0)),
                                ),
                              Container(
                                height: 45,
                                width: 45,
                                decoration: boxDecorationDefault(
                                  shape: BoxShape.circle,
                                  color: btnColor,
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (controller.isTrailer.isFalse && isMoviePaid(requiredPlanLevel: videoModel.requiredPlanLevel))
                        GestureDetector(
                          onTap: () {
                            onSubscriptionLoginCheck(
                              callBack: () {},
                              videoAccess: videoModel.movieAccess,
                              planId: videoModel.planId,
                              planLevel: videoModel.requiredPlanLevel,
                            );
                          },
                          child: SizedBox(
                            height: isPipModeOn.value ? 110 : 220,
                            width: Get.width,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (getVideoURLLink().isNotEmpty)
                                  Image.network(
                                    getVideoURLLink(),
                                    height: isPipModeOn.value ? 110 : 200,
                                    width: Get.width,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.medium,
                                  )
                                else
                                  Container(
                                    height: isPipModeOn.value ? 110 : 200,
                                    width: Get.width,
                                    decoration: boxDecorationDefault(color: context.cardColor, borderRadius: radius(0)),
                                  ),
                                Container(
                                  height: 45,
                                  width: 45,
                                  decoration: boxDecorationDefault(
                                    shape: BoxShape.circle,
                                    color: btnColor,
                                  ),
                                  child: Icon(
                                    Icons.play_arrow,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (isLive && liveShowModel?.streamType == PlayerTypes.embedded)
                        liveShowModel?.serverUrl.isNotEmpty ?? false
                            ? WebViewContentWidget(uri: Uri.parse(getVideoLink(liveShowModel?.serverUrl ?? ""))).visible(liveShowModel?.serverUrl.isNotEmpty ?? false)
                            : Container(
                                height: 180,
                                width: double.infinity,
                                decoration: boxDecorationDefault(
                                  color: appScreenBackgroundDark,
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, size: 34, color: white),
                                    10.height,
                                    Text(
                                      locale.value.videoNotFound,
                                      style: boldTextStyle(size: 16, color: white),
                                    ),
                                  ],
                                ),
                              )
                      else if (isVimeo)
                        WebViewContentWidget(uri: Uri.parse("https://player.vimeo.com/video/${videoModel.videoUrlInput.split("/").last}")).visible(videoModel.videoUrlInput.isNotEmpty)
                      else if (isVideoTypeYoutube)
                        Obx(
                          () => controller.playerChanging.value
                              ? CustomYouTubePlayer(
                                  videoId: controller.getVideoLinkAndType().$2.getYouTubeId(),
                                  aspectRatio: 16 / 9,
                                  thumbnail: getVideoURLLink().isNotEmpty && !getVideoURLLink().contains("/data/user")
                                      ? CachedImageWidget(
                                          url: getVideoURLLink(),
                                          fit: BoxFit.cover,
                                          width: Get.width,
                                          height: isPipMode ? Get.height : 220,
                                        )
                                      : null,
                                  progressIndicatorColor: appColorPrimary,
                                  onVideoEnded: () {
                                    if (!isTrailer) {
                                      controller.storeViewCompleted();
                                    }
                                  },
                                )
                              : Offstage(),
                        )
                      else if (isVideoTypeOther)
                        Theme(
                          data: ThemeData(
                            brightness: Brightness.dark,
                            bottomSheetTheme: const BottomSheetThemeData(
                              backgroundColor: appScreenBackgroundDark,
                            ),
                            primaryColor: Colors.white,
                            textTheme: const TextTheme(
                              bodyLarge: TextStyle(color: Colors.white),
                              bodyMedium: TextStyle(color: Colors.white),
                              bodySmall: TextStyle(color: Colors.white),
                            ),
                            iconTheme: const IconThemeData(color: Colors.white),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(0),
                            child: Obx(
                              () => controller.podPlayerController.value.videoUrl?.isEmpty ?? false
                                  ? Container(
                                      height: isPipModeOn.value ? 110 : 200,
                                      width: Get.width,
                                      decoration: boxDecorationDefault(
                                        color: appScreenBackgroundDark,
                                      ),
                                      alignment: Alignment.center,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.error_outline_rounded, size: 34, color: white),
                                          10.height,
                                          Text(
                                            locale.value.videoNotFound,
                                            style: boldTextStyle(size: 16, color: white),
                                          ),
                                        ],
                                      ),
                                    )
                                  : PodVideoPlayer(
                                      alwaysShowProgressBar: false,
                                      videoAspectRatio: 16 / 9,
                                      frameAspectRatio: 16 / 9,
                                      onToggleFullScreen: (isFullScreen) {
                                        return Future(() {
                                          controller.isPipEnable(isFullScreen);
                                        });
                                      },
                                      podProgressBarConfig: const PodProgressBarConfig(
                                        circleHandlerColor: appColorPrimary,
                                        backgroundColor: borderColorDark,
                                        playingBarColor: appColorPrimary,
                                        bufferedBarColor: appColorSecondary,
                                        circleHandlerRadius: 6,
                                        height: 2.6,
                                        alwaysVisibleCircleHandler: false,
                                        padding: EdgeInsets.only(bottom: 16, left: 8, right: 8),
                                      ),
                                      controller: controller.podPlayerController.value,
                                      videoThumbnail: getVideoURLLink().isNotEmpty && !getVideoURLLink().contains("/data/user")
                                          ? DecorationImage(
                                              image: NetworkImage(getVideoURLLink()),
                                              fit: BoxFit.cover,
                                              colorFilter: ColorFilter.mode(
                                                Colors.black.withValues(alpha: 0.4),
                                                BlendMode.darken,
                                              ),
                                            )
                                          : null,
                                      onVideoError: () {
                                        return Container(
                                          height: isPipModeOn.value ? 110 : 200,
                                          width: Get.width,
                                          decoration: boxDecorationDefault(
                                            color: appScreenBackgroundDark,
                                          ),
                                          alignment: Alignment.center,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.error_outline_rounded, size: 34, color: white),
                                              10.height,
                                              Text(
                                                locale.value.videoNotFound,
                                                style: boldTextStyle(size: 16, color: white),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      onLoading: (context) {
                                        return LoaderWidget(
                                          loaderColor: appColorPrimary.withValues(alpha: 0.4),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        )
                      else if (isLive && liveShowModel!.serverUrl.isNotEmpty)
                        Theme(
                          data: ThemeData(
                            brightness: Brightness.dark,
                            bottomSheetTheme: const BottomSheetThemeData(
                              backgroundColor: appScreenBackgroundDark,
                            ),
                            primaryColor: Colors.white,
                            textTheme: const TextTheme(
                              bodyLarge: TextStyle(color: Colors.white),
                              bodyMedium: TextStyle(color: Colors.white),
                              bodySmall: TextStyle(color: Colors.white),
                            ),
                            iconTheme: const IconThemeData(color: Colors.white),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(0),
                            child: Obx(
                              () => PodVideoPlayer(
                                alwaysShowProgressBar: false,
                                videoAspectRatio: 16 / 9,
                                frameAspectRatio: 16 / 9,
                                onToggleFullScreen: (isFullScreen) {
                                  return Future(() {
                                    controller.isPipEnable(isFullScreen);
                                  });
                                },
                                podProgressBarConfig: const PodProgressBarConfig(
                                  circleHandlerColor: appColorPrimary,
                                  backgroundColor: borderColorDark,
                                  playingBarColor: appColorPrimary,
                                  bufferedBarColor: appColorSecondary,
                                  circleHandlerRadius: 6,
                                  height: 2.6,
                                  alwaysVisibleCircleHandler: false,
                                  padding: EdgeInsets.only(bottom: 16, left: 8, right: 8),
                                ),
                                controller: controller.podPlayerController.value,
                                videoThumbnail: getVideoURLLink().isNotEmpty && !getVideoURLLink().contains("/data/user")
                                    ? DecorationImage(
                                        image: NetworkImage(getVideoURLLink()),
                                        fit: BoxFit.cover,
                                        colorFilter: ColorFilter.mode(
                                          Colors.black.withValues(alpha: 0.4),
                                          BlendMode.darken,
                                        ),
                                      )
                                    : null,
                                onVideoError: () {
                                  return Container(
                                    height: isPipModeOn.value ? 110 : 200,
                                    width: Get.width,
                                    decoration: boxDecorationDefault(
                                      color: appScreenBackgroundDark,
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error_outline_rounded, size: 34, color: white),
                                        10.height,
                                        Text(
                                          locale.value.videoNotFound,
                                          style: boldTextStyle(size: 16, color: white),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onLoading: (context) {
                                  return LoaderWidget(
                                    loaderColor: appColorPrimary.withValues(alpha: 0.4),
                                  );
                                },
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: isPipModeOn.value ? 110 : 200,
                          width: Get.width,
                          decoration: boxDecorationDefault(
                            color: appScreenBackgroundDark,
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 34, color: white),
                              10.height,
                              Text(
                                locale.value.videoNotFound,
                                style: boldTextStyle(size: 16, color: white),
                              ),
                            ],
                          ),
                        )
                    ]
                  ] else
                    GestureDetector(
                      onTap: () {
                        doIfLogin(
                          onLoggedIn: () {},
                        );
                      },
                      child: SizedBox(
                        height: isPipModeOn.value ? 110 : 220,
                        width: Get.width,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (getVideoURLLink().isNotEmpty)
                              Image.network(
                                getVideoURLLink(),
                                height: isPipModeOn.value ? 110 : 200,
                                width: Get.width,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                              )
                            else
                              Container(
                                height: isPipModeOn.value ? 110 : 200,
                                width: Get.width,
                                decoration: boxDecorationDefault(color: context.cardColor, borderRadius: radius(0)),
                              ),
                            Container(
                              height: 45,
                              width: 45,
                              decoration: boxDecorationDefault(
                                shape: BoxShape.circle,
                                color: btnColor,
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Obx(
                    () => const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: LoaderWidget(),
                    ).visible(controller.isBuffering.value),
                  ),
                  if (isPipMode)
                    Positioned(
                      top: 10,
                      left: 0,
                      child: IconButton(
                        onPressed: () {
                          isPipModeOn(false);
                          setOrientationPortrait();
                        },
                        icon: Icon(
                          Icons.arrow_back_ios_new_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    left: 24,
                    child: Obx(
                      () {
                        if ((controller.isTrailer.value && isTrailer) && !isLive) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: boxDecorationDefault(
                              borderRadius: BorderRadius.circular(4),
                              color: btnColor,
                            ),
                            child: Text(
                              locale.value.trailer,
                              style: secondaryTextStyle(color: white),
                            ),
                          );
                        } else {
                          return const Offstage();
                        }
                      },
                    ),
                  ).visible(!isPipMode),
                  Positioned(
                    top: 10,
                    right: videoModel.videoLinks.isNotEmpty || isFromDownloads ? 16 : 48,
                    child: IgnorePointer(
                      ignoring: !isLoggedIn.value,
                      child: Row(
                        children: [
                          if (!videoModel.videoUrlInput.validate().isVimeoVideLink && videoModel.videoLinks.isNotEmpty) 16.width,
                          if (!videoModel.videoUrlInput.validate().isVimeoVideLink && videoModel.videoLinks.isNotEmpty)
                            Container(
                              height: 26,
                              width: 26,
                              decoration: boxDecorationDefault(
                                shape: BoxShape.circle,
                                color: btnColor,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  controller.openBottomSheet(context);
                                },
                                icon: const Icon(
                                  Icons.settings,
                                  size: 16,
                                ),
                              ),
                            ).visible((videoModel.videoLinks.isNotEmpty && !(isTrailer && controller.isTrailer.value) || !isPipModeOn.value)),
                        ],
                      ),
                    ),
                  ).visible(!isPipModeOn.value && !isLive),
                ],
              ),
            ),
            if (!isPipMode)
              VideoDescriptionWidget(
                videoDescription: isLive ? VideoPlayerModel.fromJson(liveShowModel!.toJson()) : videoModel,
                onWatchNow: () async {
                  await controller.pause();

                  onWatchNow?.call();
                },
                isTrailer: isTrailer,
                showWatchNow: isTrailer || showWatchNow,
              )
          ],
        );
      },
    );
  }
}