import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BackgroundVideo extends StatefulWidget {
  const BackgroundVideo({super.key});

  @override
  _BackgroundVideoState createState() => _BackgroundVideoState();
}

class _BackgroundVideoState extends State<BackgroundVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/background_video.mp4')
      ..setLooping(true)
      ..initialize().then((_) {
        setState(() {});        // Permet de rebuild une fois la vidéo prête
        _controller.setVolume(0); // Lecture en mode muet (optionnel)
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();  // Libération de la ressource vidéo
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? FittedBox(
      fit: BoxFit.cover,
      alignment: Alignment.center,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    )
        : Container(color: Colors.black); // Placeholder tant que la vidéo n'est pas prête
  }
}
