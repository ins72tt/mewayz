import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/video/shimmer_video.dart';
import 'package:streamit_laravel/screens/video/video_details_screen.dart';
import 'package:streamit_laravel/screens/video/video_list_controller.dart';
import 'package:streamit_laravel/utils/colors.dart';

import '../../components/app_scaffold.dart';
import '../../main.dart';
import '../../utils/animatedscroll_view_widget.dart';
import '../../utils/empty_error_state_widget.dart';

class VideoListScreen extends StatelessWidget {
  VideoListScreen({super.key});

  final VideoListController videoListCont = Get.put(VideoListController());

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      isLoading: videoListCont.isLoading,
      currentPage: videoListCont.page,
      scaffoldBackgroundColor: appScreenBackgroundDark,
      topBarBgColor: transparentColor,
      appBartitleText: locale.value.popularVideos,
      body: Obx(
        () => SnapHelperWidget(
          future: videoListCont.getVideoListFuture.value,
          loadingWidget: const ShimmerVideo(),
          initialData: cachedVideoList.isNotEmpty ? cachedVideoList : null,
          errorBuilder: (error) {
            return NoDataWidget(
              titleTextStyle: secondaryTextStyle(color: white),
              subTitleTextStyle: primaryTextStyle(color: white),
              title: error,
              retryText: locale.value.reload,
              imageWidget: const ErrorStateWidget(),
              onRetry: () {
                videoListCont.page(1);
                videoListCont.getVideoList();
              },
            );
          },
          onSuccess: (res) {
            return Obx(
              () {
                return CustomAnimatedScrollView(
                  paddingLeft: Get.width * 0.04,
                  paddingRight: Get.width * 0.04,
                  paddingBottom: Get.height * 0.10,
                  spacing: Get.width * 0.03,
                  runSpacing: Get.height * 0.02,
                  posterHeight: ContextExtensions(context).isTablet() ? 180 : 150,
                  posterWidth: ContextExtensions(context).isTablet() ? Get.width * 0.45 : Get.width * 0.286,
                  isHorizontalList: false,
                  isLoading: false,
                  isLastPage: videoListCont.isLastPage.value,
                  itemList: videoListCont.videoList,
                  onTap: (poster) {
                    Get.to(() => VideoDetailsScreen(), arguments: poster);
                  },
                  onNextPage: () async {
                    if (!videoListCont.isLastPage.value) {
                      videoListCont.page++;
                      videoListCont.getVideoList();
                    }
                  },
                  onSwipeRefresh: () async {
                    videoListCont.page(1);
                    return await videoListCont.getVideoList(showLoader: false);
                  },
                  isMovieList: false,
                ) ;
              },
            );
          },
        ),
      ),
    );
  }
}