import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:streamit_laravel/main.dart';

import '../../network/core_api.dart';
import '../../utils/app_common.dart';
import '../../video_players/model/video_model.dart';

class VideoListController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool showShimmer = false.obs;
  RxBool isRefresh = false.obs;
  RxBool isLastPage = false.obs;
  RxInt page = 1.obs;
  Rx<Future<RxList<VideoPlayerModel>>> getVideoListFuture = Future(() => RxList<VideoPlayerModel>()).obs;
  RxList<VideoPlayerModel> videoList = RxList();
  RxBool isDelete = false.obs;

  @override
  void onInit() {
    if (cachedVideoList.isNotEmpty) {
      videoList = cachedVideoList;
    }
    getVideoList(showLoader: false);
    super.onInit();
  }

  ///Get Video List
  Future<void> getVideoList({bool showLoader = true, bool showShimmers = true}) async {
    if (showLoader) {
      isLoading(true);
    }

    showShimmer(showShimmers);

    await getVideoListFuture(
      CoreServiceApis.getVideoList(
        page: page.value,
        userId: loginUserData.value.id,
        getVideoList: videoList,
        lastPageCallBack: (p0) {
          isLastPage(p0);
        },
      ),
    ).then((value) {
      cachedVideoList = videoList;
      log('value.length ==> ${value.length}');
      showShimmer(false);
    }).catchError((e) {
      log("getVideo List Err : $e");
    }).whenComplete(() => isLoading(false));
  }
}
