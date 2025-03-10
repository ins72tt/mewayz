import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pod_player/pod_player.dart';
import 'package:streamit_laravel/screens/home/home_controller.dart';
import 'package:streamit_laravel/screens/profile/profile_controller.dart';
import 'package:streamit_laravel/screens/tv_show/tv_show_controller.dart';
import 'package:streamit_laravel/utils/common_base.dart';
import 'package:streamit_laravel/utils/extension/string_extention.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
// import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../main.dart';
import '../network/core_api.dart';
import '../screens/live_tv/live_tv_details/model/live_tv_details_response.dart';
import '../screens/subscription/model/subscription_plan_model.dart';
import '../utils/app_common.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'model/video_model.dart';

class VideoPlayersController extends GetxController {
  VideoPlayerModel videoModel;

  final LiveShowModel liveShowModel;

  Rx<PodPlayerController> podPlayerController = PodPlayerController(playVideoFrom: PlayVideoFrom.youtube("")).obs;

  Rx<YoutubePlayerController> youtubePlayerController = YoutubePlayerController(initialVideoId: '').obs;
  int ytSeekPosition = 0;
  RxBool isAutoPlay = true.obs;
  RxBool isTrailer = true.obs;
  RxBool isStoreContinueWatch = false.obs;
  RxBool isBuffering = false.obs;
  RxBool canChangeVideo = true.obs;
  RxBool playNextVideo = false.obs;
  RxBool isVideoCompleted = false.obs;

  RxBool isPipEnable = false.obs;

  RxString currentQuality = 'default'.obs;
  RxString errorMessage = ''.obs;

  RxList<int> availableQualities = <int>[].obs;

  bool hasNextVideo;

  UniqueKey uniqueKey = UniqueKey();

  RxString videoUrlInput = "".obs;
  RxString videoUploadType = "".obs;
  RxBool playerChanging = true.obs;

  VideoPlayersController({
    required this.videoModel,
    required this.liveShowModel,
    this.hasNextVideo = false,
    required this.isTrailer,
  });

  @override
  void onInit() {
    super.onInit();

    initializePlayer(videoModel.videoUrlInput, videoModel.videoUrlInput);

    WakelockPlus.enable();
    pausePodPlayer();
    onChangePodVideo();
    setVideoQuality();
  }

  Future<void> initializePlayer(String videURL, String videoType) async {
    isBuffering(true);
    log("Video Model in Controller ==> ${videoModel.toJson()}");
    log("Watched Duration ==> ${videoModel.watchedTime}");
    log('Live Show data =>> ${liveShowModel.toJson()}');

    if ((videoModel.type == VideoType.video || videoModel.type == VideoType.liveTv) || isAlreadyStartedWatching(videoModel.watchedTime)) {
      isTrailer(false);
    }

    uniqueKey = UniqueKey();

    if (getVideoLinkAndType().$1.toLowerCase() == PlayerTypes.youtube) {
      YoutubePlayerController youtubeController = YoutubePlayerController(
        initialVideoId: getVideoLinkAndType().$2.getYouTubeId(),
        flags: YoutubePlayerFlags(
          autoPlay: isAutoPlay.value,
          enableCaption: false,
          isLive: getVideoLinkAndType().$1.toLowerCase() == PlayerTypes.hls,
        ),
      );
      youtubeController.addListener(
        () {
          isPipModeOn(youtubeController.value.isFullScreen);
        },
      );
      if (youtubeController.value.isReady) {
        if (videoModel.watchedTime.isNotEmpty && videoModel.watchedTime != '00:00:00') {
          try {
            final parts = videoModel.watchedTime.split(':');
            final hours = int.parse(parts[0]);
            final minutes = int.parse(parts[1]);
            final seconds = int.parse(parts[2]);
            final seekPosition = Duration(hours: hours, minutes: minutes, seconds: seconds);

            youtubeController.seekTo(seekPosition);
            ytSeekPosition = seekPosition.inSeconds;
          } catch (e) {
            log("Error parsing continueWatchDuration: ${e.toString()}");
          }
        }
      }
      youtubePlayerController(youtubeController);
      isBuffering(false);
    } else {
      try {
        final controller = PodPlayerController(
          showMoreIcon: false,
          podPlayerConfig: PodPlayerConfig(
            autoPlay: isAutoPlay.value,
            isLooping: false,
            wakelockEnabled: false,
            videoQualityPriority: availableQualities,
          ),
          playVideoFrom: getVideoPlatform(
            type: getVideoLinkAndType().$1.toLowerCase(),
            videoURL: getVideoLinkAndType().$2,
          ),
        );
        controller.initialise().then((_) {
          isBuffering(false);
          if (videoModel.watchedTime.isNotEmpty) {
            try {
              final parts = videoModel.watchedTime.split(':');
              final hours = int.parse(parts[0]);
              final minutes = int.parse(parts[1]);
              final seconds = int.parse(parts[2]);
              final seekPosition = Duration(hours: hours, minutes: minutes, seconds: seconds);

              controller.videoSeekForward(seekPosition);
            } catch (e) {
              log("Error parsing continueWatchDuration: ${e.toString()}");
            }
          }
        }).catchError((error, stackTrace) {
          log("Error during initialization: ${error.toString()}");
          log("Stack trace: ${stackTrace.toString()}");
        });
        podPlayerController(controller);
        listenVideoEvent();
      } catch (e) {
        log("Exception during initialization: ${e.toString()}");
      }
    }

    if (videoModel.videoLinks.isNotEmpty) {
      availableQualities(videoModel.videoLinks.map((link) => link.quality.replaceAll(RegExp(r'[pPkK]'), '').toInt()).toList());
      currentQuality(videoModel.videoLinks.first.quality);
    }
  }

  (String, String) getVideoLinkAndType() {
    if (isTrailer.isTrue) {
      return (videoModel.trailerUrlType, videoModel.trailerUrl);
    } else if (videoModel.type == VideoType.liveTv) {
      return (liveShowModel.streamType, liveShowModel.serverUrl);
    } else {
      if (videoModel.videoUploadType.trim().isEmpty && videoModel.videoUrlInput.trim().isEmpty) {
        return (videoUploadType.value, videoUrlInput.value);
      } else if (videoModel.videoUploadType.trim().isEmpty) {
        return (videoUploadType.value, videoModel.videoUrlInput);
      } else if (videoModel.videoUrlInput.trim().isEmpty) {
        return (videoModel.videoUploadType, videoUrlInput.value);
      }
      return (videoModel.videoUploadType, videoModel.videoUrlInput);
    }
  }

  void checkIfVideoEnded() {
    if (podPlayerController.value.videoPlayerValue != null) {
      if (podPlayerController.value.videoPlayerValue!.position.inSeconds >= (podPlayerController.value.videoPlayerValue!.duration.inSeconds - 10)) {
        playNextVideo(true);
      }
      if (podPlayerController.value.videoPlayerValue?.isCompleted ?? false) {
        storeViewCompleted();
        podPlayerController.value.pause();
      }
    }
  }

  startNextEpisode() {
    pause();
    if (videoModel.type == VideoType.tvshow || videoModel.type == VideoType.episode) {
      playNextEpisode();
    }
  }

  storeViewCompleted() async {
    Map<String, dynamic> request = {
      "entertainment_id": videoModel.id,
      "user_id": loginUserData.value.id,
      "entertainment_type": getVideoType(type: videoModel.type),
      if (profileId.value != 0) "profile_id": profileId.value,
    };

    await CoreServiceApis.saveViewCompleted(request: request);
  }

  playNextEpisode() {
    TvShowController episodeDetailsController = Get.isRegistered<TvShowController>() ? Get.find<TvShowController>() : Get.put(TvShowController());
    if (episodeDetailsController.currentEpisodeIndex.value < episodeDetailsController.episodeList.length) {
      episodeDetailsController.selectedEpisode(episodeDetailsController.episodeList[episodeDetailsController.currentEpisodeIndex.value + 1]);
      episodeDetailsController.getEpisodeDetail(changeVideo: true);
    }
  }

  void listenVideoEvent() {
    if (youtubePlayerController.value.initialVideoId.isNotEmpty) {
      youtubePlayerController.value.addListener(
        () {
          isPipEnable(youtubePlayerController.value.value.isFullScreen);
        },
      );
    } else {
      podPlayerController.value.addListener(() {
        isBuffering(podPlayerController.value.isVideoBuffering);
        checkIfVideoEnded();
      });
    }
  }

  void handleError(String? errorDescription) {
    log("Video Player Error: $errorDescription");
    errorMessage.value = errorDescription ?? 'An unknown error occurred';
  }

  void changeVideo({required String quality, required bool isQuality, required String type}) async {
    final currentPlaybackPosition = podPlayerController.value.videoPlayerValue?.position ?? Duration.zero;
    currentQuality.value = quality;
    try {
      VideoLinks? selectedLink = isQuality ? videoModel.videoLinks.firstWhereOrNull((link) => link.quality == quality) : VideoLinks(url: quality);
      videoUploadType(type);
      videoUrlInput(quality);
      playerChanging(false);
      Future.delayed(Duration(milliseconds: 500), () {
        playerChanging(true);
      });
      if (selectedLink != null) {
        if (type.toLowerCase() == PlayerTypes.youtube) {
          if (youtubePlayerController.value.value.hasPlayed) {
            youtubePlayerController.value.load(YoutubePlayer.convertUrlToId(selectedLink.url.validate()).validate());
          } else {
            initializePlayer(selectedLink.url, type.toLowerCase());
          }
        } else {
          if (podPlayerController.value.isInitialised) {
            await podPlayerController.value
                .changeVideo(
              playVideoFrom: getVideoPlatform(
                type: type.toLowerCase(),
                videoURL: selectedLink.url,
              ),
            )
                .then((_) {
              if (isQuality) log("Video quality changed to $quality");
              if (isQuality) podPlayerController.value.videoSeekForward(currentPlaybackPosition);
              listenVideoEvent();
            }).onError((error, stackTrace) {
              log("Error during changeVideoQuality: ${error.toString()}");
              handleError(error.toString());
            });
          } else {
            initializePlayer(selectedLink.url, type);
          }
        }
      } else {
        isBuffering(false);
        log("Selected quality not found");
      }
    } catch (e) {
      isBuffering(false);
      log("Exception during changeVideoQuality: ${e.toString()}");
      handleError(e.toString());
    }
  }

  PlayVideoFrom getVideoPlatform({required String type, required String videoURL}) {
    PlayVideoFrom videoPlatform;
    log('Type ---- $type ----------- $videoURL');
    try {
      Map<String, PlayVideoFrom> videoTypeMap = {
        PlayerTypes.vimeo: PlayVideoFrom.vimeo(videoURL.toString().getVimeoVideoId.validate()),
        PlayerTypes.hls: PlayVideoFrom.network(videoURL.validate()),
        PlayerTypes.url: PlayVideoFrom.network(videoURL.validate()),
        PlayerTypes.local: PlayVideoFrom.network(videoURL.validate()),
        PlayerTypes.file: PlayVideoFrom.file(File(videoURL.validate().replaceAll("'", ""))),
        PlayerTypes.youtube: PlayVideoFrom.youtube(videoURL.validate(), live: videoURL.contains('/live/')),
      };
      log(videoTypeMap[type]?.playerType);
      videoPlatform = videoTypeMap[type] ?? PlayVideoFrom.network(videoURL.validate());
    } catch (e) {
      log("Error in getVideoPlatform: ${e.toString()}");
      throw Exception("Invalid video URL or type");
    }

    return videoPlatform;
  }

  @override
  Future<void> onClose() async {
    // if (isTrailer.isFalse && getTypeForContinueWatch(type: videoModel.type.toLowerCase()) != VideoType.liveTv) saveToContinueWatchVideo();
    if (podPlayerController.value.isInitialised) {
      podPlayerController.value.removeListener(() => podPlayerController.value);
      podPlayerController.value.dispose();
    } else if (youtubePlayerController.value.value.hasPlayed && youtubePlayerController.value.value.metaData.videoId.isNotEmpty) {
      if (isTrailer.isFalse) saveToContinueWatchVideo();
      youtubePlayerController.value.removeListener(
        () {},
      );
      youtubePlayerController.value.dispose();
    }

    LiveStream().dispose(podPlayerPauseKey);
    LiveStream().dispose(changeVideoInPodPlayer);
    LiveStream().dispose(mOnWatchVideo);
    LiveStream().dispose(onAddVideoQuality);
    canChangeVideo(true);

    WakelockPlus.disable();
    super.onClose();
  }

  void saveToContinueWatchVideo() async {
    if (videoModel.id != -1) {
      String watchedTime = '';
      String totalWatchedTime = '';
      if (videoModel.videoUploadType.toLowerCase() == PlayerTypes.youtube) {
        if (youtubePlayerController.value.value.hasPlayed) {
          log('----------------------------here------------------- ${youtubePlayerController.value.value.position} ----------- ${youtubePlayerController.value.value.metaData.duration}');
          watchedTime = formatDuration(youtubePlayerController.value.value.position);
          totalWatchedTime = formatDuration(youtubePlayerController.value.value.metaData.duration);
        }
      } else {
        if (podPlayerController.value.videoPlayerValue != null) {
          watchedTime = formatDuration(podPlayerController.value.videoPlayerValue!.position);
          totalWatchedTime = formatDuration(podPlayerController.value.videoPlayerValue!.duration);
        }
      }

      await CoreServiceApis.saveContinueWatch(
        request: {
          "entertainment_id": videoModel.id.toString(),
          "watched_time": watchedTime,

          ///store actual value of video player there is chance duration might be set different then actual duration of video

          "total_watched_time": totalWatchedTime,
          "entertainment_type": getTypeForContinueWatch(type: videoModel.type.toLowerCase()),
          if (profileId.value != 0) "profile_id": profileId.value,
          if (getVideoType(type: videoModel.type) == VideoType.episode) "episode_id": videoModel.episodeId,
        },
      ).then((value) {
        HomeController homeScreenController = Get.find<HomeController>();
        homeScreenController.getDashboardDetail(showLoader: false);
        ProfileController profileController = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : Get.put(ProfileController());

        profileController.getProfileDetail(showLoader: false);
        log("Success ==> $value");
      }).catchError((e) {
        log("Error LOG ==> $e");
      });
    }
  }

  String getTypeForContinueWatch({required String type}) {
    String videoType = "";
    dynamic videoTypeMap = {
      "movie": VideoType.movie,
      "video": VideoType.video,
      "livetv": VideoType.liveTv,
      'tvshow': VideoType.tvshow,
      'episode': VideoType.tvshow,
    };
    videoType = videoTypeMap[type] ?? VideoType.episode;
    return videoType;
  }

  void setVideoQuality() {
    LiveStream().on(onAddVideoQuality, (val) {
      videoModel.videoLinks.clear();
      videoModel.videoLinks.addAll(val as RxList<VideoLinks>);
    });
  }

  void play() {
    podPlayerController.value.play();
  }

  Future<void> pause() async {
    if (podPlayerController.value.isInitialised) {
      podPlayerController.value.pause();
    }
  }

  void pausePodPlayer() {
    LiveStream().on(podPlayerPauseKey, (p0) {
      pause();
    });
  }

  void openBottomSheet(BuildContext context) {
    Get.bottomSheet(
      isDismissible: true,
      isScrollControlled: true,
      enableDrag: false,
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: boxDecorationDefault(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
            color: appBackgroundSecondaryColorDark2,
          ),
          child: AnimatedScrollView(
            crossAxisAlignment: CrossAxisAlignment.start,
            listAnimationType: commonListAnimationType,
            refreshIndicatorColor: appColorPrimary,
            children: <Widget>[
              Row(
                children: [
                  Text(
                    locale.value.settings,
                    style: commonW500PrimaryTextStyle(size: 22),
                  ),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsetsDirectional.only(start: 16),
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: iconColor,
                    ),
                  )
                ],
              ),
              Divider(
                height: 16,
                color: dividerColor,
              ),
              if (videoModel.videoLinks.isEmpty) buildQualityOption('Auto', '480p', videoModel.videoUploadType),
              if (videoModel.videoLinks.isNotEmpty)
                ...videoModel.videoLinks.map((link) {
                  return Column(
                    children: [
                      link.quality == "480p" ? buildQualityOption(locale.value.lowQuality, '480p', videoModel.videoUploadType) : const Offstage(),
                      link.quality == "720p" ? buildQualityOption(locale.value.mediumQuality, '720p', videoModel.videoUploadType) : const Offstage(),
                      link.quality == "1080p" ? buildQualityOption(locale.value.highQuality, '1080p', videoModel.videoUploadType) : const Offstage(),
                      link.quality == "1440p" ? buildQualityOption(locale.value.veryHighQuality, '1440p', videoModel.videoUploadType) : const Offstage(),
                      link.quality == "2K" ? buildQualityOption(locale.value.ultraQuality, '2K', videoModel.videoUploadType) : const Offstage(),
                      link.quality == "4K" ? buildQualityOption(locale.value.ultraQuality, '4K', videoModel.videoUploadType) : const Offstage(),
                      link.quality == "8K" ? buildQualityOption(locale.value.ultraQuality, '8K', videoModel.videoUploadType) : const Offstage(),
                    ],
                  );
                })
            ],
          ),
        ),
      ),
    );
  }

  bool checkQualitySupported({required String quality, required int requirePlanLevel}) {
    bool supported = false;
    PlanLimit currentPlanLimit = PlanLimit();
    int index = -1;
    index = currentSubscription.value.planType.indexWhere((element) => (element.slug == SubscriptionTitle.downloadStatus || element.limitationSlug == SubscriptionTitle.downloadStatus));
    if (requirePlanLevel == 0) {
      supported = true;
    } else {
      if (index > -1) {
        currentPlanLimit = currentSubscription.value.planType[index].limit;

        switch (quality) {
          case "480p":
            supported = currentPlanLimit.four80Pixel.getBoolInt();
            break;
          case "720p":
            supported = currentPlanLimit.seven20p.getBoolInt();
            break;
          case "1080p":
            supported = currentPlanLimit.one080p.getBoolInt();
            break;
          case "1440p":
            supported = currentPlanLimit.oneFourFour0Pixel.getBoolInt();
            break;
          case "2K":
            supported = currentPlanLimit.twoKPixel.getBoolInt();
            break;
          case "4K":
            supported = currentPlanLimit.fourKPixel.getBoolInt();
            break;
          case "8K":
            supported = currentPlanLimit.eightKPixel.getBoolInt();
            break;
          default:
            break;
        }
      }
    }

    return supported;
  }

  void onChangePodVideo() {
    LiveStream().on(changeVideoInPodPlayer, (val) {
      isAutoPlay(false);
      isTrailer(false);
      isStoreContinueWatch(true);
      if ((val as List)[0] != null) changeVideo(quality: (val)[0], isQuality: (val)[1], type: (val)[2]);
    });
    LiveStream().on(mOnWatchVideo, (val) {
      isTrailer(false);
      isAutoPlay(false);
      isStoreContinueWatch(true);
      if (((val as List)[0] != null)) {
        changeVideo(quality: (val)[0], isQuality: (val)[1], type: (val)[2]);
      } else {}
    });
  }

  Widget buildQualityOption(String label, String quality, String type) {
    if (checkQualitySupported(
      quality: quality,
      requirePlanLevel: videoModel.requiredPlanLevel,
    )) {
      return InkWell(
        onTap: () {
          Get.back();
          changeVideo(quality: quality, isQuality: true, type: type);
        },
        child: Row(
          children: [
            Text("$label ($quality)", style: commonW600SecondaryTextStyle()),
            const Spacer(),
            Obx(() {
              return currentQuality.value == quality
                  ? const Icon(
                      Icons.check,
                      color: appColorPrimary,
                    )
                  : const SizedBox.shrink();
            }),
          ],
        ).paddingSymmetric(vertical: 16),
      );
    } else {
      return Offstage();
    }
  }
}