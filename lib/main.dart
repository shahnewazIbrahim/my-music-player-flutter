import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MusicPlayer(),
    );
  }
}

class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  _MusicPlayerState createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  late AudioPlayer _audioPlayer;
  late Stream<Duration> _positionStream;
  late Stream<Duration> _durationStream;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _positionStream = _audioPlayer.positionStream;
    _durationStream = _audioPlayer.durationStream.map((duration) => duration ?? Duration.zero);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Music Player')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Bar
            StreamBuilder<Duration>(
              stream: _positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: _durationStream,
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? Duration.zero;
                    final progress = position.inMilliseconds.toDouble();
                    final total = duration.inMilliseconds.toDouble();

                    return Column(
                      children: [
                        // Current position and remaining time
                        Text(
                          "${position.inMinutes}:${position.inSeconds.remainder(60).toString().padLeft(2, '0')} / ${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                        ),
                        Slider(
                          value: progress,
                          min: 0.0,
                          max: total,
                          onChanged: (value) {
                            _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            StreamBuilder<PlayerState>(
              stream: _audioPlayer.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final playing = playerState?.playing;

                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  return CircularProgressIndicator();
                } else if (playing != true) {
                  return IconButton(
                    icon: Icon(Icons.play_arrow),
                    iconSize: 64.0,
                    onPressed: _audioPlayer.play,
                  );
                } else if (processingState != ProcessingState.completed) {
                  return IconButton(
                    icon: Icon(Icons.pause),
                    iconSize: 64.0,
                    onPressed: _audioPlayer.pause,
                  );
                } else {
                  return IconButton(
                    icon: Icon(Icons.replay),
                    iconSize: 64.0,
                    onPressed: () => _audioPlayer.seek(Duration.zero),
                  );
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.music_note),
        onPressed: () async {
          await _audioPlayer.setUrl('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
          _audioPlayer.play();
        },
      ),
    );
  }
}
