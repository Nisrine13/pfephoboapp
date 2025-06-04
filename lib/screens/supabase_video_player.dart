// lib/screens/supabase_video_player.dart

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
  bool _isEnded = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.network(widget.videoUrl);
    await _videoController!.initialize();

    _videoController!.addListener(() {
      if (_videoController == null) return;
      final position = _videoController!.value.position;
      final duration = _videoController!.value.duration;
      if (position >= duration && !_isEnded) {
        setState(() {
          _isEnded = true;
        });
      }
    });

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: false,
      looping: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.grey.shade200,
        handleColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        bufferedColor: Colors.grey.shade300,
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
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return Column(
        children: [
          // 1) La vidéo
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Chewie(controller: _chewieController!),
          ),

          // 2) Lien stylisé “Passer le QCM”
          if (_isEnded && widget.onVideoEnded != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade700,
                      width: 1.5,
                    ),
                  ),
                ),
                child: InkWell(
                  onTap: () => widget.onVideoEnded!(),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: Text(
                      'Passer le QCM',
                      style: TextStyle(
                        color: Color(0xA9FFCA00),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
