// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import 'app_common.dart';
import 'colors.dart';
import 'common_base.dart';

class PriceWidget extends StatelessWidget {
  final num price;
  final String? priceText;
  final num? discountedPrice;
  final double? size;
  final Color? color;
  final Color? hourlyTextColor;
  final bool isBoldText;
  final bool isSemiBoldText;
  final bool isExtraBoldText;
  final bool isLineThroughEnabled;
  final bool isDiscountedPrice;
  final bool isPercentage;
  final String formatedPrice;

  const PriceWidget({
    super.key,
    required this.price,
    this.size = 16.0,
    this.color,
    this.hourlyTextColor,
    this.isLineThroughEnabled = false,
    this.isBoldText = true,
    this.isSemiBoldText = false,
    this.isExtraBoldText = false,
    this.isDiscountedPrice = false,
    this.isPercentage = false,
    this.priceText,
    this.discountedPrice,
    this.formatedPrice = "",
  });

  @override
  Widget build(BuildContext context) {
    TextStyle _textStyle({int? aSize, bool isOriginalPrice = false}) {
      // Apply line-through decoration only for the original price when a discount exists
      bool applyLineThrough = isOriginalPrice && isDiscountedPrice;

      // If it's the original price and a discount exists, apply secondaryTextStyle with line-through
      if (applyLineThrough) {
        return secondaryTextStyle(
          size: aSize ?? size!.toInt(),
          color: color ?? darkGrayTextColor,
          decoration: TextDecoration.lineThrough, // Line-through for original price
          decorationColor: darkGrayTextColor,
        );
      }

      // For discounted price or normal price, return appropriate styles
      if (isSemiBoldText) {
        return primaryTextStyle(
          size: aSize ?? size!.toInt(),
          color: color ?? context.primaryColor,
          decoration: null, // No decoration for discounted price or regular price
        );
      }
      if (isExtraBoldText) {
        return boldTextStyle(
          size: aSize ?? size!.toInt(),
          color: color ?? context.primaryColor,
          fontFamily: fontFamilyWeight700,
          decoration: null, // No decoration for discounted price or regular price
        );
      }

      return isBoldText
          ? boldTextStyle(
              size: aSize ?? size!.toInt(),
              color: color ?? context.primaryColor,
              decoration: null, // No decoration for discounted price or regular price
            )
          : secondaryTextStyle(
              size: aSize ?? size!.toInt(),
              color: color ?? context.primaryColor,
              decoration: null, // No decoration for discounted price or regular price
            );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Original price with line-through when discounted price is available
        if (appConfigs.value.enableInAppPurchase.getBoolInt() && formatedPrice.isNotEmpty)
          Text(
            formatedPrice,
            style: _textStyle(),
          )
        else ...[
          if (isDiscountedPrice)
            Text(
              "${isPercentage ? '' : leftCurrencyFormat()}${price.toStringAsFixed(appCurrency.value.noOfDecimal).formatNumberWithComma(seperator: appCurrency.value.thousandSeparator)}${isPercentage ? '' : rightCurrencyFormat()}",
              style: _textStyle(isOriginalPrice: true, aSize: 18), // Only original price gets line-through
            ).paddingOnly(right: 6, top: 3),

          // Discounted price with no line-through
          Text(
            isDiscountedPrice
                ? "${isPercentage ? '' : leftCurrencyFormat()}${discountedPrice.validate().toStringAsFixed(appCurrency.value.noOfDecimal).formatNumberWithComma(seperator: appCurrency.value.thousandSeparator)}${isPercentage ? '' : rightCurrencyFormat()}  "
                : priceText ??
                    "${isPercentage ? '' : leftCurrencyFormat()}${price.validate().toStringAsFixed(appCurrency.value.noOfDecimal).formatNumberWithComma(seperator: appCurrency.value.thousandSeparator)}${isPercentage ? '' : rightCurrencyFormat()}",
            style: _textStyle(), // Discounted price gets normal styling with no line-through
            textAlign: TextAlign.center,
          ),

          // Percentage symbol if applicable
          if (isPercentage)
            Text(
              '%',
              style: _textStyle(),
            ),
        ]
      ],
    );
  }
}

String leftCurrencyFormat() {
  if (isCurrencyPositionLeft || isCurrencyPositionLeftWithSpace) {
    return isCurrencyPositionLeftWithSpace ? '${appCurrency.value.currencySymbol} ' : appCurrency.value.currencySymbol;
  }
  return '';
}

String rightCurrencyFormat() {
  if (isCurrencyPositionRight || isCurrencyPositionRightWithSpace) {
    return isCurrencyPositionRightWithSpace ? ' ${appCurrency.value.currencySymbol}' : appCurrency.value.currencySymbol;
  }
  return '';
}
