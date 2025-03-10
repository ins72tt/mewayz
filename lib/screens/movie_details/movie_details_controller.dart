import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/download_videos/download_video.dart';
import 'package:streamit_laravel/screens/home/home_controller.dart';
import 'package:streamit_laravel/screens/movie_details/model/movie_details_resp.dart';
import 'package:streamit_laravel/screens/profile/profile_controller.dart';
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
import '../review_list/model/review_model.dart';
import '../watch_list/watch_list_controller.dart';
import 'components/add_review/add_review_controller.dart';

class MovieDetailsController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  RxBool isDownloaded = false.obs;
  RxBool showDownload = false.obs;
  RxBool isTrailer = true.obs;

  Rx<Future<MovieDetailResponse>> getMovieDetailsFuture = Future(() => MovieDetailResponse(data: MovieDetailModel(yourReview: ReviewModel()))).obs;
  Rx<MovieDetailModel> movieDetailsResp = MovieDetailModel(yourReview: ReviewModel()).obs;
  Rx<VideoPlayerModel> movieData = VideoPlayerModel().obs;

  RxInt downloadPercentage = 0.obs;

  late WebViewController webController;

  @override
  void onInit() {
    if (Get.arguments is VideoPlayerModel) {
      movieData(Get.arguments);
      isTrailer(!isAlreadyStartedWatching(movieData.value.watchedTime));
    }

    getMovieDetail(showLoader: false);

    // Add LiveStream listeners
    setupLiveStreamMovieListeners();
    super.onInit();
  }

  ///Get Movie List
  getMovieDetail({bool showLoader = true}) async {
    isLoading(showLoader);
    await getMovieDetailsFuture(CoreServiceApis.getMovieDetails(
      movieId: movieData.value.entertainmentId != -1 ? movieData.value.entertainmentId : movieData.value.id,
      userId: loginUserData.value.id,
    )).then((value) {
      isSupportedDevice(value.data.isDeviceSupported);
      setValue(SharedPreferenceConst.IS_SUPPORTED_DEVICE, value.data.isDeviceSupported);
      movieDetailsResp(value.data);
      checkIfAlreadyDownloaded();
      checkYourReview();
    }).whenComplete(() => isLoading(false));
  }

  void setupLiveStreamMovieListeners() {
    // Listen for video player refresh events
    LiveStream().on(VIDEO_PLAYER_REFRESH_EVENT, (p0) {
      refreshMoviePlayer();
    });
  }

  void refreshMoviePlayer() {
    // Force a rebuild of the player
    isLoading(true);
    Future.delayed(const Duration(milliseconds: 100), () {
      isLoading(false);
    });
  }

  checkYourReview() {
    AddReviewController movieDetCont = Get.put(AddReviewController());
    movieDetCont.isMovies(true);
    movieDetCont.movieId(movieDetailsResp.value.id);
  }

  editReview() {
    AddReviewController movieDetCont = Get.put(AddReviewController());
    movieDetCont.ratingVal(double.parse(movieDetailsResp.value.yourReview.rating.toString()));
    movieDetCont.reviewCont.text = movieDetailsResp.value.yourReview.review;
  }

  deleteReview() {
    isLoading(true);
    CoreServiceApis.deleteRating(
      request: {
        "id": movieDetailsResp.value.yourReview.id,
      },
    ).then((value) async {
      await getMovieDetail(showLoader: false);
      final AddReviewController movieDetCont = Get.find<AddReviewController>();
      movieDetCont.onReviewCheck();
      successSnackBar(value.message.toString());
    }).catchError((e) {
      errorSnackBar(error: e);
    }).whenComplete(() {
      Get.back();
      isLoading(false);
    });
  }

  addLike() {
    int isLike = movieDetailsResp.value.isLike ? 0 : 1;
    movieDetailsResp.value.isLike = isLike.getBoolInt() ? true : false;
    isLoading(true);
    hideKeyBoardWithoutContext();
    CoreServiceApis.likeMovie(
      request: {
        "entertainment_id": movieDetailsResp.value.id,
        "is_like": isLike,
        if (profileId.value != 0) "profile_id": profileId.value,
      },
    ).then((value) async {
      await getMovieDetail(showLoader: false);
    }).catchError((e) {
      movieDetailsResp.value.isLike = isLike.getBoolInt() ? false : true;
    }).whenComplete(() {
      isLoading(false);
    });
  }

  saveWatchList({bool addToWatchList = true}) async {
    if (isLoading.isTrue) return;
    isLoading(true);
    movieDetailsResp.value.isWatchList = true;
    hideKeyBoardWithoutContext();
    if (addToWatchList) {
      CoreServiceApis.saveWatchList(
        request: {
          "entertainment_id": movieDetailsResp.value.id,
          if (profileId.value != 0) "profile_id": profileId.value,
        },
      ).then((value) async {
        await getMovieDetail(showLoader: false);
        successSnackBar(locale.value.addedToWatchList);
        updateWatchList(movieDetailsResp.value.id);
      }).catchError((e) {
        movieDetailsResp.value.isWatchList = false;
      }).whenComplete(() {
        isLoading(false);
      });
    } else {
      movieDetailsResp.value.isWatchList = false;
      await CoreServiceApis.deleteFromWatchlist(idList: [movieDetailsResp.value.id]).then((value) async {
        await getMovieDetail(showLoader: false);
        successSnackBar(locale.value.removedFromWatchList);
        updateWatchList(movieDetailsResp.value.id);
      }).catchError((e) {
        movieDetailsResp.value.isWatchList = true;
      }).whenComplete(() {
        isLoading(false);
      });
    }
  }

  updateWatchList(int id) {
    Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : Get.put(ProfileController());
    Get.isRegistered<WatchListController>() ? Get.find<WatchListController>() : Get.put(WatchListController());
    HomeController homeController = Get.isRegistered<HomeController>() ? Get.find<HomeController>() : Get.put(HomeController());

    if (homeController.dashboardDetail.value.slider.any((element) => element.id == id)) {
      homeController.getDashboardDetail();
    }
  }

  storeView() {
    if (isLoading.isTrue || movieDetailsResp.value.id < 0) return;
    hideKeyBoardWithoutContext();
    CoreServiceApis.storeViewDetails(
      request: {
        "entertainment_id": movieDetailsResp.value.id,
        if (profileId.value != 0) "profile_id": profileId.value,
      },
    ).then((value) async {
      log("Response is ==> $value");
    }).catchError((e) {
      log("Response Error ==> $e");
    }).whenComplete(() {
      log("Response Completed");
    });
  }

  handleDownloads() async {
    DownloadController downloadCont = Get.put(DownloadController());

    if (isDownloaded.value) {
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
            type: VideoType.movie,
            releaseYear: movieData.value.releaseYear,
            releaseDate: movieData.value.releaseDate,
            language: movieData.value.language,
            thumbnailImage: movieData.value.thumbnailImage,
          ),
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
    afterBuildCreated(() {
      LiveStream().emit(podPlayerPauseKey);
      Get.bottomSheet(
        isDismissible: true,
        isScrollControlled: true,
        enableDrag: false,
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: DownloadComponent(
            downloadDet: movieDetailsResp.value.downloadQuality,
            videoModel: VideoPlayerModel(
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
              type: VideoType.movie,
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
    });
  }

  checkIfAlreadyDownloaded() async {
    showDownload(movieDetailsResp.value.downloadStatus && movieDetailsResp.value.downloadQuality.isNotEmpty);
    if (currentSubscription.value.level > -1 && currentSubscription.value.planType.isNotEmpty) {
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
            videoURL: isTrailer.isTrue && videoModel.watchedTime.isEmpty ? videoModel.trailerUrl : videoModel.videoUrlInput,
            device: device!,
            contentType: isTrailer.isTrue && videoModel.watchedTime.isEmpty ? videoModel.trailerUrlType.toLowerCase() : videoModel.videoUploadType.toLowerCase(),
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