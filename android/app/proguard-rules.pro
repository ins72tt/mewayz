# Stripe related rules
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

#VLC
-keep class org.videolan.libvlc.** { *; }

# llfbandit.record related rules
-keep class com.llfbandit.record.** { *; }
-keep class com.llfbandit.record.record.format.Format { *; }

# General rules for Flutter and Kotlin
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**
-dontwarn io.flutter.plugins.**

# Keep all members of sealed classes
-keep class **.SealedClass { *; }

# Razorpay
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }
-keep class com.razorpay.** { *; }
-keepattributes *Annotation*
