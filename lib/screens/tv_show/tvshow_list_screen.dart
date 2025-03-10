// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/tv_show/tv_show_screen.dart';
import 'package:streamit_laravel/utils/colors.dart';

import '../../components/app_scaffold.dart';
import '../../main.dart';
import '../../utils/animatedscroll_view_widget.dart';
import '../../utils/empty_error_state_widget.dart';
import '../movie_list/shimmer_movie_list/shimmer_movie_list.dart';
import 'tvshow_list_controller.dart';

class TvShowListScreen extends StatelessWidget {
  String? title = locale.value.movies;

  TvShowListScreen({super.key, this.title});

  final TvShowListController tvShowListCont = Get.put(TvShowListController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppScaffoldNew(
        isLoading: tvShowListCont.page.value == 1 ? false.obs : tvShowListCont.isLoading,
        currentPage: tvShowListCont.page,
        scaffoldBackgroundColor: appScreenBackgroundDark,
        topBarBgColor: transparentColor,
        appBartitleText: title.validate(),
        body: Obx(
          () => SnapHelperWidget(
            future: tvShowListCont.getTvShowFuture.value,
            loadingWidget: const ShimmerMovieList(),
            initialData: cachedTvShowList.isNotEmpty ? cachedTvShowList : null,
            errorBuilder: (error) {
              return NoDataWidget(
                titleTextStyle: secondaryTextStyle(color: white),
                subTitleTextStyle: primaryTextStyle(color: white),
                title: error,
                retryText: locale.value.reload,
                imageWidget: const ErrorStateWidget(),
                onRetry: () {
                  tvShowListCont.page(1);
                  tvShowListCont.getTvShowDetails();
                },
              );
            },
            onSuccess: (res) {
              return Obx(
                () => !tvShowListCont.isLoading.value && tvShowListCont.tvShowList.isEmpty
                    ? NoDataWidget(
                        titleTextStyle: boldTextStyle(color: white),
                        subTitleTextStyle: primaryTextStyle(color: white),
                        title: locale.value.noDataFound,
                        retryText: "",
                        imageWidget: const EmptyStateWidget(),
                      ).paddingSymmetric(horizontal: 16)
                    : CustomAnimatedScrollView(
                        paddingLeft: Get.width * 0.04,
                        paddingRight: Get.width * 0.04,
                        paddingBottom: Get.height * 0.10,
                        spacing: Get.width * 0.03,
                        runSpacing: Get.height * 0.02,
                        posterHeight: 150,
                        posterWidth: Get.width * 0.286,
                        isHorizontalList: false,
                        isLoading: false,
                        isLastPage: tvShowListCont.isLastPage.value,
                        itemList: tvShowListCont.tvShowList,
                        onTap: (posterDet) {
                          Get.to(() => TvShowScreen(key: UniqueKey()), arguments: posterDet);
                        },
                        onNextPage: () async {
                          if (!tvShowListCont.isLastPage.value) {
                            tvShowListCont.page++;
                            tvShowListCont.getTvShowDetails(viewShimmer: false, showLoader: true);
                          }
                        },
                        onSwipeRefresh: () async {
                          tvShowListCont.page(1);
                          return await tvShowListCont.getTvShowDetails(showLoader: false);
                        },
                        isMovieList: false,
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
