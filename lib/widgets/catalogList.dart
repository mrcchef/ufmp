import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ufmp/data/musicCatalog.dart';
import 'package:ufmp/utils/parseDuration.dart';

import 'home.dart';

class CatalogList extends StatelessWidget {
  final List<MusicCatalog> data;
  final int index;

  const CatalogList(this.data, this.index);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem>(
      stream: AudioService.currentMediaItemStream,
      builder: (context, snapshot) {
        return ListTile(
          selected: snapshot.hasData
              ? (snapshot.data.id == data[index].id ? true : false)
              : false,
          leading: AspectRatio(
            aspectRatio: 1.0,
            child: CachedNetworkImage(
              imageUrl: data[index].image,
              fit: BoxFit.fitHeight,
            ),
          ),
          title: Text(data[index].title),
          subtitle: Text(data[index].artist),
          trailing: Text(
            prettyDuration(Duration(seconds: data[index].duration)),
          ),
          onTap: () => play(data[index].id),
        );
      },
    );
  }

  play(String id) async {
    if (AudioService.running) {
      // The service is already running, hence we begin playback.
      AudioService.playFromMediaId(id);
    } else {
      // Start background music playback.
      if (await AudioService.start(
        backgroundTaskEntrypoint: backgroundTaskEntrypoint,
        androidNotificationChannelName: 'Playback',
        androidNotificationColor: 0xFF2196f3,
        androidStopForegroundOnPause: true,
        androidEnableQueue: true,
      )) {
        /* Process for setting up the queue */

        // 1.Convert music catalog to mediaitem data type.
        final queue = data.map((catalog) {
          return MediaItem(
            id: catalog.id,
            album: catalog.album,
            title: catalog.title,
            artist: catalog.artist,
            duration: Duration(seconds: catalog.duration),
            genre: catalog.genre,
            artUri: catalog.image,
            extras: {'source': catalog.source},
          );
        }).toList();

        // 2.Now we add our queue to audio player task.
        await AudioService.updateQueue(queue);

        // 3.Let's now begin the playback.
        AudioService.playFromMediaId(id);
      }
    }
  }
}
