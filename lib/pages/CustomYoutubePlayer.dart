import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class CustomYoutubePlayer extends StatefulWidget {
  final String youtubeUrl;

  const CustomYoutubePlayer({super.key, required this.youtubeUrl});

  @override
  State<CustomYoutubePlayer> createState() => _CustomYoutubePlayerState();
}

class _CustomYoutubePlayerState extends State<CustomYoutubePlayer> {
  late String videoId;
  bool showPlayer = false;
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl) ?? '';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    setState(() {
      showPlayer = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (videoId.isEmpty) {
      return const Text('Lien YouTube invalide');
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: showPlayer
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
            onTap: _initializePlayer,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
