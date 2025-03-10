import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/cached_image_widget.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/common_base.dart';
import 'package:streamit_laravel/generated/assets.dart';
import '../model/profile_watching_model.dart';
import '../watching_profile_controller.dart';

class ProfileComponent extends StatelessWidget {
  final WatchingProfileModel profile;
  final WatchingProfileController profileWatchingController;
  final double height;
  final double width;
  final EdgeInsets padding;
  final double imageSize;

  const ProfileComponent({
    super.key,
    required this.profile,
    required this.profileWatchingController,
    required this.height,
    required this.width,
    required this.padding,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        profileWatchingController.handleSelectProfile(profile);
      },
      child: Container(
        height: height,
        width: width,
        padding: padding,
        alignment: Alignment.center,
        decoration: boxDecorationDefault(
          borderRadius: radius(4),
          color: cardColor,
          border: Border.all(color: profile.id == profileId.value ? appColorPrimary.withValues(alpha: 0.6) : borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile image
            Container(
              height: imageSize,
              width: imageSize,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: CachedImageWidget(
                url: profile.avatar,
                height: 35,
                width: 35,
                fit: BoxFit.cover,
              ),
            ),
            10.height,
            // Profile name
            Marquee(
              child: Text(
                profile.name.capitalizeEachWord(),
                textAlign: TextAlign.center,
                style: primaryTextStyle(size: 14),
              ),
            ),
            4.height,
            // Edit button
            TextIcon(
              onTap: () {
                profileWatchingController.handleAddEditProfile(profile, true);
              },
              prefix: Image.asset(
                Assets.iconsIcEdit,
                width: 14,
                height: 14,
                color: iconColor,
              ),
              text: locale.value.edit,
              maxLine: 1,
              spacing: 4,
              textStyle: commonW500SecondaryTextStyle(size: 12, color: iconColor),
              useMarquee: true,
            )
          ],
        ),
      ),
    );
  }
}
