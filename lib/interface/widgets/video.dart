import 'dart:math';

import 'package:e1547/interface/interface.dart';
import 'package:e1547/settings/data/settings.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';

export 'package:media_kit/media_kit.dart';
export 'package:media_kit_video/media_kit_video.dart';

class VideoHandler extends ChangeNotifier {
  VideoHandler({bool muteVideos = false}) : _muteVideos = muteVideos;

  // To prevent the app from crashing due tue OutOfMemoryErrors,
  // the list of all loaded videos is global.
  static final Map<VideoConfig, Player> _videos = {};

  final int maxLoaded = 3;

  // 50mb
  final int maxSize = 5 * pow(10, 7).toInt();

  bool _muteVideos;

  bool get muteVideos => _muteVideos;

  set muteVideos(bool value) {
    _muteVideos = value;
    _videos.values.forEach((e) => e.setVolume(muteVideos ? 0 : 100));
    notifyListeners();
  }

  Player getVideo(VideoConfig key) {
    while (true) {
      Map<VideoConfig, Player> loaded = Map.of(_videos);
      int loadedSize =
          loaded.keys.fold<int>(0, (current, config) => current + config.size);
      if (loaded.length < maxLoaded && loadedSize < maxSize) {
        break;
      }
      disposeVideo(loaded.keys.first);
    }
    return _videos.putIfAbsent(
      key,
      () {
        Player player = Player();
        player.open(Media(key.url), play: false);
        player.setPlaylistMode(PlaylistMode.single);
        player.setVolume(_muteVideos ? 0 : 100);
        player.streams.playing.listen((event) => _handleWakelock());
        return player;
      },
    );
  }

  void _handleWakelock() {
    for (final player in _videos.values) {
      if (player.state.playing) {
        Wakelock.enable();
        return;
      }
    }
    Wakelock.disable();
  }

  Future<void> disposeVideo(VideoConfig key) async {
    Player? controller = _videos[key];
    if (controller != null) {
      _videos.remove(key);
      await controller.pause();
      await controller.dispose();
      notifyListeners();
    }
  }
}

@immutable
class VideoConfig {
  const VideoConfig({required this.url, required this.size});

  final String url;
  final int size;

  @override
  bool operator ==(Object other) =>
      other is VideoConfig && other.url == url && other.size == size;

  @override
  int get hashCode => Object.hash(url.hashCode, size.hashCode);
}

class VideoHandlerProvider
    extends SubChangeNotifierProvider<Settings, VideoHandler> {
  VideoHandlerProvider({super.child, super.builder})
      : super(
          create: (context, settings) => VideoHandler(
            muteVideos: settings.muteVideos.value,
          ),
        );
}

class VideoHandlerVolumeControl extends StatefulWidget {
  const VideoHandlerVolumeControl();

  @override
  State<VideoHandlerVolumeControl> createState() =>
      _VideoHandlerVolumeControlState();
}

class _VideoHandlerVolumeControlState extends State<VideoHandlerVolumeControl> {
  @override
  Widget build(BuildContext context) {
    VideoHandler handler = context.watch<VideoHandler>();
    bool muted = handler.muteVideos;
    return InkWell(
      onTap: () => handler.muteVideos = !muted,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          muted ? Icons.volume_off : Icons.volume_up,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}
