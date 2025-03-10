// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/_discovery_manager/discovery_manager.dart';
import 'package:flutter_chrome_cast/_session_manager/cast_session_manager.dart';
import 'package:flutter_chrome_cast/entities/cast_session.dart';
import 'package:flutter_chrome_cast/enums/connection_satate.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/custom_icon_button_widget.dart';
import 'package:streamit_laravel/screens/video/video_details_controller.dart';
import 'package:streamit_laravel/generated/assets.dart';

import '../../../../main.dart';
import '../../../../utils/app_common.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/common_base.dart';
import '../../../../utils/constants.dart';
import '../../../auth/sign_in/sign_in_screen.dart';
import '../../../movie_details/components/more_list/more_list_component.dart';
import '../model/video_details_resp.dart';

class VideoDetailsComponent extends StatelessWidget {
  final VideoDetailsModel videoDetail;
  final VideoDetailsController movieDetailCont;

  const VideoDetailsComponent({
    super.key,
    required this.videoDetail,
    required this.movieDetailCont,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
              onTap: () {
                if (isLoggedIn.isTrue) {
                  movieDetailCont.saveWatchList(addToWatchList: !videoDetail.isWatchList);
                } else {
                  LiveStream().emit(podPlayerPauseKey);
                  Get.to(() => SignInScreen())?.then((value) {
                    if (isLoggedIn.isTrue) {
                      movieDetailCont.saveWatchList(addToWatchList: !videoDetail.isWatchList);
                    }
                  });
                }
              },
              isTrue: videoDetail.isWatchList,
              checkIcon: Assets.iconsIcCheck,
            ),
            CustomIconButton(
              icon: Assets.iconsIcShare,
              title: locale.value.share,
              onTap: () {
                shareVideo(type: VideoType.video, videoId: videoDetail.id);
              },
            ),
            Obx(
              () {
                if (movieDetailCont.showDownload.value) {
                  return CustomIconButton(
                    icon: movieDetailCont.isDownloaded.value ? Assets.iconsIcDownloaded : Assets.iconsIcDownload,
                    title: locale.value.download,
                    iconWidget: movieDetailCont.downloadPercentage.value >= 1 && movieDetailCont.downloadPercentage.value < 100
                        ? Text(
                            '${movieDetailCont.downloadPercentage.value}'.suffixText(value: '%'),
                            style: primaryTextStyle(color: appColorPrimary),
                          )
                        : null,
                    color: iconColor,
                    onTap: () async {
                      if (movieDetailCont.isDownloaded.value || movieDetailCont.movieDetailsResp.value.requiredPlanLevel == 0) {
                        movieDetailCont.handleDownload(context);
                      } else {
                        onSubscriptionLoginCheck(
                          videoAccess: movieDetailCont.movieDetailsResp.value.access,
                          callBack: () {
                            if (currentSubscription.value.level >= movieDetailCont.movieDetailsResp.value.requiredPlanLevel) {
                              movieDetailCont.handleDownload(context);
                            }
                          },
                          planId: videoDetail.planId,
                          planLevel: videoDetail.requiredPlanLevel,
                        );
                      }
                    },
                  );
                } else {
                  return Offstage();
                }
              },
            ),
            CustomIconButton(
              icon: Assets.iconsIcThumbsup,
              title: locale.value.like,
              onTap: () {
                if (isLoggedIn.isTrue) {
                  movieDetailCont.addLike();
                } else {
                  LiveStream().emit(podPlayerPauseKey);
                  Get.to(() => SignInScreen())?.then((value) {
                    if (isLoggedIn.isTrue) {
                      movieDetailCont.addLike();
                    }
                  });
                }
              },
              isTrue: videoDetail.isLiked,
              checkIcon: Assets.iconsIcLike,
            ),
            CustomIconButton(
              icon: Assets.iconsIcPictureInPicture,
              color: iconColor,
              title: locale.value.pip,
              onTap: () async {
                /// Handle Picture In Picture Mode
                handlePip(controller: movieDetailCont, context: context);
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
                                    movieDetailCont.openBottomSheetForFCCastAvailableDevices(context);
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
            ),
          ],
        ).paddingSymmetric(horizontal: 10, vertical: 16),
        MoreListComponent(moreList: videoDetail.moreItems).visible(videoDetail.moreItems.isNotEmpty),
      ],
    );
  }
}