// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/movie_list/movie_list_controller.dart';
import 'package:streamit_laravel/screens/movie_list/shimmer_movie_list/shimmer_movie_list.dart';
import 'package:streamit_laravel/utils/colors.dart';

import '../../components/app_scaffold.dart';
import '../../main.dart';
import '../../utils/animatedscroll_view_widget.dart';
import '../../utils/empty_error_state_widget.dart';
import '../movie_details/movie_details_screen.dart';

class MovieListScreen extends StatelessWidget {
  String? title = locale.value.movies;

  MovieListScreen({super.key, this.title});

  final MovieListController movieListCont = Get.put(MovieListController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppScaffoldNew(
        isLoading: movieListCont.page.value == 1 ? false.obs : movieListCont.isLoading,
        scaffoldBackgroundColor: appScreenBackgroundDark,
        topBarBgColor: transparentColor,
        currentPage: movieListCont.page,
        appBartitleText: title.validate(),
        body: RefreshIndicator(
          color: appColorPrimary,
          onRefresh: () async {
            return await movieListCont.getMovieDetails();
          },
          child: Obx(
            () => SnapHelperWidget(
              future: movieListCont.getOriginalMovieListFuture.value,
              initialData: cachedMovieList.isNotEmpty ? cachedMovieList : null,
              loadingWidget: const ShimmerMovieList(),
              errorBuilder: (error) {
                return NoDataWidget(
                  titleTextStyle: secondaryTextStyle(color: white),
                  subTitleTextStyle: primaryTextStyle(color: white),
                  title: error,
                  retryText: locale.value.reload,
                  imageWidget: const ErrorStateWidget(),
                  onRetry: () {
                    movieListCont.page(1);
                    movieListCont.getMovieDetails();
                  },
                );
              },
              onSuccess: (res) {
                return Obx(
                  () => movieListCont.originalMovieList.isEmpty && movieListCont.isLoading.isFalse
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
                          isLastPage: movieListCont.isLastPage.value,
                          itemList: movieListCont.originalMovieList,
                          onTap: (posterDet) {
                            Get.to(() => MovieDetailsScreen(), arguments: posterDet);
                          },
                          onNextPage: movieListCont.onNextPage,
                          onSwipeRefresh: () async {
                            movieListCont.page(1);
                            return await movieListCont.getMovieDetails(showLoader: false);
                          },
                          isMovieList: true,
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
