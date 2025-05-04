import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeThumbnailPlayer extends StatefulWidget {
  final String youtubeUrl;

  const YoutubeThumbnailPlayer({super.key, required this.youtubeUrl});

  @override
  State<YoutubeThumbnailPlayer> createState() => _YoutubeThumbnailPlayerState();
}

class _YoutubeThumbnailPlayerState extends State<YoutubeThumbnailPlayer> {
  late String videoId;
  bool isPlaying = false;
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl) ?? '';
  }

  void _startVideo() {
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: true),
    );
    setState(() {
      isPlaying = true;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (videoId.isEmpty) return const Text("Lien YouTube invalide");

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: isPlaying
          ? YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
      )
          : Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            'https://img.youtube.com/vi/$videoId/0.jpg',
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          InkWell(
            onTap: _startVideo,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
            ),
          ),
        ],
      ),
    );
  }
}
