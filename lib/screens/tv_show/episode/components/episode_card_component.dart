import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/tv_show/episode/models/episode_model.dart';
import 'package:streamit_laravel/utils/extension/string_extention.dart';
import 'package:streamit_laravel/generated/assets.dart';

import '../../../../components/cached_image_widget.dart';
import '../../../../utils/app_common.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/common_base.dart';

class EpisodeCardComponent extends StatelessWidget {
  final int season;
  final int episodeNumber;
  final EpisodeModel episode;

  const EpisodeCardComponent({super.key, required this.episode, required this.season, required this.episodeNumber});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: key,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CachedImageWidget(
            url: episode.posterImage.validate(),
            width: 120,
            fit: BoxFit.cover,
            radius: 4,
          ),
          16.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Marquee(
                child: Text(
                  episode.name.getEpisodeTitle(),
                  style: boldTextStyle(size: 16, ),
                ),
              ),
              12.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${locale.value.sAlphabet}$season ${locale.value.eAlphabet}$episodeNumber',
                    style: primaryTextStyle(size: 12, color: darkGrayTextColor),
                  ),
                  6.width,
                  const Icon(Icons.circle, size: 6, color: darkGrayTextColor),
                  6.width,
                  Text(
                    dateFormat(episode.releaseDate),
                    style: primaryTextStyle(size: 12, color: darkGrayTextColor),
                  ).visible(episode.releaseDate.validate().isNotEmpty),
                ],
              ),
              6.height,
              Text(
                episode.shortDesc.validate(),
                style: secondaryTextStyle(size: 12, weight: FontWeight.w500, color: darkGrayTextColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            ],
          ).expand(),
          if ((episode.requiredPlanLevel != 0 && currentSubscription.value.level < episode.requiredPlanLevel)) 16.width,
          if ((episode.requiredPlanLevel != 0 && currentSubscription.value.level < episode.requiredPlanLevel))
            Container(
              height: 14,
              width: 14,
              margin: EdgeInsets.only(top: 4, right: 4),
              padding: const EdgeInsets.all(4),
              decoration: boxDecorationDefault(shape: BoxShape.circle, color: yellowColor),
              child: const CachedImageWidget(
                url: Assets.iconsIcVector,
              ),
            ),
        ],
      ),
    );
  }
}
