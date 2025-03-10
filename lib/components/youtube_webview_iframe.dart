import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomYouTubePlayer extends StatefulWidget {
  final String videoId;
  final double aspectRatio;
  final double seekPosition; // Starting position of the video in seconds
  final Function? onVideoEnded; // Callback when the video ends
  final Widget? thumbnail; // Thumbnail image for the video
  final Color progressIndicatorColor; // Color of the progress indicator

  const CustomYouTubePlayer({
    required this.videoId,
    this.aspectRatio = 16 / 9,
    this.seekPosition = 0,
    this.onVideoEnded,
    this.thumbnail,
    this.progressIndicatorColor = Colors.red,
    super.key,
  });

  @override
  _CustomYouTubePlayerState createState() => _CustomYouTubePlayerState();
}

class _CustomYouTubePlayerState extends State<CustomYouTubePlayer> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  bool _isPlaying = false;
  late String currentVideoId;

  @override
  void initState() {
    super.initState();

    currentVideoId = widget.videoId; // Initialize with the initial videoId

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'flutter_inappwebview',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'onVideoEnded') {
            widget.onVideoEnded?.call();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(_buildVideoUri(currentVideoId, widget.seekPosition));
  }

  Uri _buildVideoUri(String videoId, double seekPosition) {
    return Uri.dataFromString(
      '''
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body {
            margin: 0;
            padding: 0;
            background: black;
            display: flex;
            justify-content: center;
            align-items: center;
          }
        </style>
      </head>
      <body>
        <iframe width="${Get.width * 2.5}" height="${Get.height * 0.8}"
          id="youtube-player"
          src="https://www.youtube.com/embed/$videoId?autoplay=1&enablejsapi=1&rel=0&nologo=1&loop=1&modestbranding=1&start=$seekPosition" 
          frameborder="0"
          allow="gyroscope; autoplay; encrypted-media"
          allowfullscreen>
        </iframe>
        <script>
          var player;
          function onYouTubeIframeAPIReady() {
            player = new YT.Player('youtube-player', {
              events: {
                'onStateChange': onPlayerStateChange
              }
            });
          }
          function onPlayerStateChange(event) {
            if (event.data === YT.PlayerState.ENDED) {
              window.flutter_inappwebview.callHandler('onVideoEnded');
            }
          }
        </script>
        <script src="https://www.youtube.com/iframe_api"></script>
      </body>
      </html>
      ''',
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8'),
    );
  }

  /// Change the video by updating the WebView content
  void changeVideo(String newVideoId, {double seekPosition = 0}) {
    setState(() {
      currentVideoId = newVideoId;
      _isLoading = true;
      _isPlaying = false;
    });

    _webViewController.loadRequest(_buildVideoUri(newVideoId, seekPosition));
  }

  void _playVideo() {
    setState(() {
      _isPlaying = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        children: [
          if (widget.thumbnail != null && !_isPlaying) ...[
            widget.thumbnail ?? Offstage(),
            Center(
              child: IconButton(
                icon: Icon(
                  Icons.play_circle_fill,
                  size: 64,
                  color: Colors.white,
                ),
                onPressed: _playVideo,
              ),
            ),
          ] else
            WebViewWidget(controller: _webViewController),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: widget.progressIndicatorColor,
              ),
            ),
        ],
      ),
    );
  }
}
