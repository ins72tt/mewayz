// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/_discovery_manager/discovery_manager.dart';
import 'package:flutter_chrome_cast/_session_manager/cast_session_manager.dart';
import 'package:flutter_chrome_cast/entities/cast_session.dart';
import 'package:flutter_chrome_cast/enums/connection_satate.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/cached_image_widget.dart';
import 'package:streamit_laravel/generated/assets.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/auth/sign_in/sign_in_screen.dart';
import 'package:streamit_laravel/screens/movie_details/model/movie_details_resp.dart';

import '../../../components/custom_icon_button_widget.dart';
import '../../../utils/app_common.dart';
import '../../../utils/colors.dart';
import '../../../utils/common_base.dart';
import '../../../utils/constants.dart';
import '../../review_list/components/remove_review_component.dart';
import '../movie_details_controller.dart';
import 'actor_component.dart';
import 'add_review/add_review_component.dart';
import 'more_list/more_list_component.dart';
import 'review_list/review_list_component.dart';

class MovieDetailsComponent extends StatelessWidget {
  final MovieDetailModel movieDetail;

  final MovieDetailsController movieDetCont;

  const MovieDetailsComponent({super.key, required this.movieDetail, required this.movieDetCont});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomIconButton(
                icon: Assets.iconsIcPlus,
                title: locale.value.watchlist,
                iconHeight: 22,
                iconWidth: 22,
                isTrue: movieDetail.isWatchList,
                checkIcon: Assets.iconsIcCheck,
                onTap: () {
                  if (isLoggedIn.isTrue) {
                    movieDetCont.saveWatchList(addToWatchList: !movieDetail.isWatchList);
                  } else {
                    Get.to(() => SignInScreen())?.then((value) {
                      if (isLoggedIn.isTrue) {
                        movieDetCont.saveWatchList(addToWatchList: !movieDetail.isWatchList);
                      }
                    });
                  }
                },
              ),
              CustomIconButton(
                icon: Assets.iconsIcShare,
                title: locale.value.share,
                onTap: () {
                  shareVideo(type: VideoType.movie, videoId: movieDetail.id);
                  // viewFiles(movieDetail.name);
                },
              ),
              if (movieDetCont.showDownload.isTrue)
                CustomIconButton(
                  icon: movieDetCont.isDownloaded.value ? Assets.iconsIcDelete : Assets.iconsIcDownload,
                  title: locale.value.download,
                  iconWidget: movieDetCont.downloadPercentage.value >= 1 && movieDetCont.downloadPercentage.value < 100
                      ? Marquee(
                          child: Text(
                            '${movieDetCont.downloadPercentage.value}'.suffixText(value: '%'),
                            style: primaryTextStyle(color: appColorPrimary),
                          ),
                        )
                      : null,
                  color: Colors.white54,
                  onTap: () async {
                    if (movieDetCont.isDownloaded.value || movieDetail.requiredPlanLevel == 0) {
                      movieDetCont.handleDownloads();
                    } else {
                      onSubscriptionLoginCheck(
                        videoAccess: movieDetail.movieAccess,
                        callBack: () {
                          if (currentSubscription.value.level >= movieDetCont.movieDetailsResp.value.requiredPlanLevel) {
                            movieDetCont.handleDownloads();
                          }
                        },
                        planId: movieDetail.planId,
                        planLevel: movieDetail.requiredPlanLevel,
                      );
                    }
                  },
                ),
              CustomIconButton(
                icon: Assets.iconsIcThumbsup,
                title: locale.value.like,
                onTap: () {
                  doIfLogin(
                    onLoggedIn: () {
                      if (isLoggedIn.isTrue) {
                        movieDetCont.addLike();
                      }
                    },
                  );
                },
                isTrue: movieDetail.isLike,
                checkIcon: Assets.iconsIcLike,
              ),
              CustomIconButton(
                icon: Assets.iconsIcPictureInPicture,
                color: Colors.grey,
                title: locale.value.pip,
                onTap: () async {
                  /// Handle Picture In Picture Mode
                  handlePip(controller: movieDetCont, context: context);
                },
              ),
              Obx(
                () {
                  if (isCastingAvailable.value) {
                    return StreamBuilder<GoogleCastSession?>(
                      stream: GoogleCastSessionManager.instance.currentSessionStream,
                      builder: (context, snapshot) {
                        final bool isConnected = GoogleCastSessionManager.instance.connectionState == GoogleCastConnectState.ConnectionStateConnected;
                        return CustomIconButton(
                          icon: '',
                          title: locale.value.videoCast,
                          iconWidget: Icon(
                            isConnected ? Icons.cast_connected : Icons.cast,
                            size: 20,
                            color: white,
                          ),
                          onTap: () {
                            doIfLogin(
                              onLoggedIn: () {
                                checkCastSupported(
                                  onCastSupported: () {
                                    if (isConnected) {
                                      GoogleCastDiscoveryManager.instance.stopDiscovery();
                                      GoogleCastSessionManager.instance.endSessionAndStopCasting();
                                    } else {
                                      LiveStream().emit(podPlayerPauseKey);
                                      movieDetCont.openBottomSheetForFCCastAvailableDevices(context);
                                    }
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  } else {
                    return Offstage();
                  }
                },
              )
            ],
          ).paddingSymmetric(vertical: 16, horizontal: 2),
          ActorComponent(castDetails: movieDetail.casts, title: locale.value.cast),
          ActorComponent(castDetails: movieDetail.directors, title: locale.value.directors),
          AddReviewComponent(
            isMovie: true,
            editReviewCallback: () {
              movieDetCont.editReview();
            },
            deleteReviewCallback: () {
              LiveStream().emit(podPlayerPauseKey);
              Get.bottomSheet(
                isDismissible: true,
                isScrollControlled: false,
                RemoveReviewComponent(
                  onRemoveTap: () {
                    Get.back();
                    LiveStream().emit(podPlayerPauseKey);
                    movieDetCont.deleteReview();
                  },
                ),
              );
            },
          ).visible(isLoggedIn.isTrue),
          ReviewListComponent(
            reviewList: movieDetail.reviews,
            movieName: movieDetail.name,
            movieId: movieDetail.id,
            isMovie: true,
          ).visible(movieDetail.reviews.isNotEmpty),
          MoreListComponent(moreList: movieDetail.moreItems).visible(movieDetail.moreItems.isNotEmpty),
        ],
      ),
    );
  }

  Widget commonType({required String icon, required Function() onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: boxDecorationDefault(
          color: circleColor,
          shape: BoxShape.circle,
        ),
        child: CachedImageWidget(
          url: icon,
          height: 18,
          width: 18,
        ),
      ),
    );
  }
}