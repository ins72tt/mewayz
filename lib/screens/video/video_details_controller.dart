import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/video/video_details/model/video_details_resp.dart';
import 'package:streamit_laravel/utils/common_base.dart';
import 'package:streamit_laravel/video_players/model/video_model.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../network/core_api.dart';
import '../../main.dart';
import '../../utils/app_common.dart';
import '../../utils/cast/available_devices_for_cast.dart';
import '../../utils/cast/controller/fc_cast_controller.dart';
import '../../utils/cast/flutter_chrome_cast_widget.dart';
import '../../utils/constants.dart';
import '../../utils/video_download.dart';
import '../download_videos/components/download_component.dart';
import '../download_videos/download_controller.dart';
import '../download_videos/download_video.dart';
import '../profile/profile_controller.dart';
import '../watch_list/watch_list_controller.dart';

class VideoDetailsController extends GetxController {
  Rx<Future<VideoDetailResponse>> getMovieDetailsFuture = Future(() => VideoDetailResponse(data: VideoDetailsModel())).obs;
  Rx<VideoDetailsModel> movieDetailsResp = VideoDetailsModel().obs;
  Rx<VideoPlayerModel> movieData = VideoPlayerModel().obs;

  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  RxBool isDownloaded = false.obs;
  RxBool showDownload = false.obs;

  RxInt downloadPercentage = 0.obs;

  late WebViewController webController;

  @override
  void onInit() {
    if (Get.arguments is VideoPlayerModel) {
      movieData(Get.arguments);
    }
    getMovieDetail(showLoader: false);

    // Add LiveStream listeners
    setupLiveStreamVideoListeners();
    super.onInit();
  }

  ///Get Movie List
  getMovieDetail({bool showLoader = true}) async {
    isLoading(showLoader);
    await getMovieDetailsFuture(CoreServiceApis.getVideoDetails(movieId: movieData.value.id, userId: loginUserData.value.id)).then((value) {
      isSupportedDevice(value.data.isDeviceSupported);
      setValue(SharedPreferenceConst.IS_SUPPORTED_DEVICE, value.data.isDeviceSupported);
      movieDetailsResp(value.data);
      checkIfAlreadyDownloaded();
    }).whenComplete(() => isLoading(false));
  }

  void setupLiveStreamVideoListeners() {
    // Listen for video player refresh events
    LiveStream().on(VIDEO_PLAYER_REFRESH_EVENT, (p0) {
      refreshVideoPlayer();
    });
  }

  void refreshVideoPlayer() {
    // Force a rebuild of the player
    isLoading(true);
    Future.delayed(const Duration(milliseconds: 100), () {
      isLoading(false);
    });
  }

  addLike() {
    int isLike = movieDetailsResp.value.isLiked ? 0 : 1;
    movieDetailsResp.value.isLiked = isLike.getBoolInt() ? true : false;
    movieDetailsResp.refresh();
    hideKeyBoardWithoutContext();
    CoreServiceApis.likeMovie(
      request: {
        "entertainment_id": movieDetailsResp.value.id,
        "is_like": isLike,
        "type": "video",
        if (profileId.value != 0) "profile_id": profileId.value,
      },
    ).then((value) async {
      await getMovieDetail(showLoader: false);
    }).catchError((e) {
      movieDetailsResp.value.isLiked = isLike.getBoolInt() ? false : true;
    });
  }

  saveWatchList({bool addToWatchList = true}) {
    hideKeyBoardWithoutContext();

    if (isLoading.isTrue) return;
    isLoading(true);
    if (addToWatchList) {
      movieDetailsResp.value.isWatchList = true;
      CoreServiceApis.saveWatchList(
        request: {
          "entertainment_id": movieDetailsResp.value.id,
          if (profileId.value != 0) "profile_id": profileId.value,
          "type": "video",
        },
      ).then((value) async {
        await getMovieDetail(showLoader: false);
        successSnackBar(locale.value.addedToWatchList);
        ProfileController profileCont = Get.put(ProfileController());
        profileCont.getProfileDetail(showLoader: false);
        WatchListController watchListCont = Get.put(WatchListController());
        watchListCont.getWatchList(showLoader: false);
      }).catchError((e) {
        movieDetailsResp.value.isWatchList = false;
        errorSnackBar(error: e);
      });
    } else {
      movieDetailsResp.value.isWatchList = false;
      CoreServiceApis.deleteFromWatchlist(idList: [movieDetailsResp.value.id]).then((value) async {
        await getMovieDetail(showLoader: false);
        successSnackBar(locale.value.removedFromWatchList);
        ProfileController profileCont = Get.put(ProfileController());
        profileCont.getProfileDetail(showLoader: false);
        WatchListController watchListCont = Get.put(WatchListController());
        watchListCont.getWatchList(showLoader: false);
      }).catchError((e) {
        movieDetailsResp.value.isWatchList = true;
        errorSnackBar(error: e);
      });
    }
  }

  handleDownload(BuildContext ctx) async {
    DownloadController downloadCont = Get.put(DownloadController());
    if (movieDetailsResp.value.isDownload) {
      LiveStream().emit(podPlayerPauseKey);
      downloadCont.selectedVideos(
        [
          VideoPlayerModel(
            id: movieData.value.id,
            name: movieData.value.name,
            description: movieData.value.description,
            imdbRating: movieData.value.imdbRating,
            entertainmentId: movieData.value.entertainmentId,
            genres: movieData.value.genres,
            contentRating: movieData.value.contentRating,
            videoLinks: movieDetailsResp.value.videoLinks,
            posterImage: movieData.value.posterImage,
            downloadQuality: movieDetailsResp.value.downloadQuality,
            downloadUrl: movieDetailsResp.value.downloadUrl,
            videoUploadType: movieData.value.videoUploadType,
            videoUrlInput: movieData.value.videoUrlInput,
            type: VideoType.video,
            releaseYear: movieData.value.releaseYear,
            releaseDate: movieData.value.releaseDate,
            language: movieData.value.language,
            thumbnailImage: movieData.value.thumbnailImage,
          )
        ],
      );
      Get.to(() => DownloadVideosScreen())?.then(
        (value) {
          if (value ?? false) checkIfAlreadyDownloaded();
        },
      );
    } else {
      download();
    }
  }

  download() {
    Get.bottomSheet(
      isDismissible: true,
      isScrollControlled: false,
      enableDrag: false,
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: DownloadComponent(
          downloadDet: movieDetailsResp.value.downloadQuality,
          isFromVideo: true,
          videoModel: VideoPlayerModel(
            name: movieData.value.name,
            description: movieData.value.description,
            imdbRating: movieData.value.imdbRating,
            entertainmentId: movieData.value.entertainmentId,
            genres: movieData.value.genres,
            contentRating: movieData.value.contentRating,
            videoLinks: movieDetailsResp.value.videoLinks,
            posterImage: movieData.value.posterImage,
            downloadQuality: movieDetailsResp.value.downloadQuality,
            downloadUrl: movieDetailsResp.value.downloadUrl,
            videoUploadType: movieData.value.videoUploadType,
            videoUrlInput: movieData.value.videoUrlInput,
            type: VideoType.video,
            releaseYear: movieData.value.releaseYear,
            releaseDate: movieData.value.releaseDate,
            language: movieData.value.language,
            thumbnailImage: movieData.value.thumbnailImage,
          ),
          refreshCallback: () {
            checkIfAlreadyDownloaded();
          },
          downloadProgress: (p0) {
            downloadPercentage(p0);
          },
        ),
      ),
    );
  }

  checkIfAlreadyDownloaded() async {
    showDownload(movieDetailsResp.value.downloadStatus && movieDetailsResp.value.downloadQuality.isNotEmpty);
    if (currentSubscription.value.level > -1 && (currentSubscription.value.planType.isNotEmpty)) {
      int index;
      index = currentSubscription.value.planType.indexWhere((element) => (element.limitationSlug == SubscriptionTitle.downloadStatus || element.slug == SubscriptionTitle.downloadStatus));
      if (index > -1) {
        showDownload(showDownload.value && currentSubscription.value.planType[index].limitationValue.getBoolInt());
      }
    }
    bool downloaded = await FileStorage.checkIfAlreadyDownloaded(
      fileName: movieDetailsResp.value.videoUrlInput.split("/").last,
      fileUrl: movieDetailsResp.value.videoUrlInput,
      videoId: movieDetailsResp.value.id,
    );
    isDownloaded(downloaded);
  }

  Future openBottomSheetForFCCastAvailableDevices(BuildContext context) async {
    GoogleCastDevice? device;
    VideoPlayerModel videoModel = getVideoPlayerResp(movieData.value.toJson());
    Get.bottomSheet(
      isDismissible: false,
      AvailableDevicesForCast(
        onTap: (p1) {
          device = p1;
          Get.back(result: true);
        },
      ),
    ).then(
      (value) {
        if (value != null && device != null) {
          FCCast cast = Get.find();
          cast.setChromeCast(
            videoURL: videoModel.videoUrlInput,
            device: device!,
            contentType: videoModel.videoUploadType.toLowerCase(),
            title: videoModel.name,
          );
          Get.to(() => FlutterChromeCastWidget());
        }
      },
    );
  }

  @override
  void onClose() {
    LiveStream().dispose(VIDEO_PLAYER_REFRESH_EVENT);
    videoPlayerDispose();
    super.onClose();
  }
}