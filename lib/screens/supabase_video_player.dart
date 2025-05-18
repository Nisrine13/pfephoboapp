import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class SupabaseVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onVideoEnded;

  const SupabaseVideoPlayer({
    super.key,
    required this.videoUrl,
    this.onVideoEnded,
  });



  @override
  State<SupabaseVideoPlayer> createState() => _SupabaseVideoPlayerState();
}

class _SupabaseVideoPlayerState extends State<SupabaseVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.network(widget.videoUrl);

    await _videoController!.initialize();

    _videoController!.addListener(() {
      final isEnded = _videoController!.value.position >= _videoController!.value.duration;

      if (isEnded && widget.onVideoEnded != null) {
        widget.onVideoEnded!();
      }
    });


    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: false,
      looping: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF30B0C7),
        handleColor: const Color(0xFF30B0C7),
        backgroundColor: Colors.grey,
        bufferedColor: Colors.lightBlue.shade100,
      ),
    );

    setState(() {});
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
