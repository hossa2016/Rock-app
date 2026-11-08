import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.hernan.rock_app.audio',
    androidNotificationChannelName: 'Reproducción',
    androidNotificationOngoing: true,
  );
  runApp(const RockApp());
}

class RockApp extends StatelessWidget {
  const RockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.redAccent,
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final yt = YoutubeExplode();
  final player = AudioPlayer();
  final controller = TextEditingController();

  static const generos = [
    'Rock clásico',
    'Rock alternativo',
    'Rock en español',
    'Indie rock',
    'Punk rock',
    'Hard rock',
    'Metal',
    'Grunge',
  ];

  List<Video> results = [];
  int current = -1;
  bool loading = false;
  bool loadingTrack = false;
  String? error;

  @override
  void initState() {
    super.initState();
    player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed && current + 1 < results.length) {
        playAt(current + 1);
      }
    });
    search('Rock clásico');
  }

  @override
  void dispose() {
    player.dispose();
    yt.close();
    controller.dispose();
    super.dispose();
  }

  Future<void> search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final query = q.toLowerCase().contains('rock') ||
              q.toLowerCase().contains('metal') ||
              q.toLowerCase().contains('grunge')
          ? q
          : '$q rock';
      final list = await yt.search.search(query);
      final filtered = list
          .where((v) =>
              !v.isLive &&
              v.duration != null &&
              v.duration!.inMinutes < 12)
          .toList();
      setState(() {
        results = filtered;
        current = -1;
      });
    } catch (e) {
      setState(() => error = 'Error al buscar: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> playAtOld(int i) async {
    if (i < 0 || i >= results.length) return;
    final v = results[i];
    setState(() {
      current = i;
      loadingTrack = true;
      error = null;
    });
    try {
      final manifest = await yt.videos.streamsClient.getManifest(v.id);
      final audios = manifest.audioOnly.toList();
      final mp4 = audios.where((a) => a.container.name == 'mp4').toList();
      final pool = mp4.isNotEmpty ? mp4 : audios;
      pool.sort((a, b) =>
          b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
      final stream = pool.first;
      await player.setAudioSource(
        AudioSource.uri(
          stream.url,
          tag: MediaItem(
            id: v.id.value,
            title: v.title,
            artist: v.author,
            artUri: Uri.parse(v.thumbnails.highResUrl),
            duration: v.duration,
          ),
        ),
      );
      player.play();
    } catch (e) {
      setState(() => error = 'No se pudo reproducir: $e');
    } finally {
      setState(() => loadingTrack = false);
    }
  }

   Future<void> playAt(int i) async {
        if (i < 0 || i >= results.length) return;
            final v = results[i];
                setState(() {
                      current = i;
                            loadingTrack = true;
                                  error = null;
                                      });
                                          final attempts = <(YoutubeApiClient, String?)>[
                                                (
                                                        YoutubeApiClient.androidVr,
                                                                'com.google.android.apps.youtube.vr.oculus/1.62.27 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip'
                                                                      ),
                                                                            (
                                                                                    YoutubeApiClient.ios,
                                                                                            'com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)'
                                                                                                  ),
                                                                                                        (YoutubeApiClient.tv, null),
                                                                                                            ];
                                                                                                                String? lastError = 'No hay audio disponible';
                                                                                                                    for (final (client, ua) in attempts) {
                                                                                                                          try {
                                                                                                                                  final manifest = await yt.videos.streamsClient
                                                                                                                                              .getManifest(v.id, ytClients: [client]);
                                                                                                                                                      final audios = manifest.audioOnly.toList();
                                                                                                                                                              if (audios.isEmpty) continue;
                                                                                                                                                                      final mp4 = audios.where((a) => a.container.name == 'mp4').toList();
                                                                                                                                                                              final pool = mp4.isNotEmpty ? mp4 : audios;
                                                                                                                                                                                      pool.sort((a, b) =>
                                                                                                                                                                                                  b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
                                                                                                                                                                                                          final stream = pool.first;
                                                                                                                                                                                                                  await player.setAudioSource(
                                                                                                                                                                                                                            AudioSource.uri(
                                                                                                                                                                                                                                        stream.url,
                                                                                                                                                                                                                                                    headers: ua == null ? null : {'User-Agent': ua},
                                                                                                                                                                                                                                                                tag: MediaItem(
                                                                                                                                                                                                                                                                              id: v.id.value,
                                                                                                                                                                                                                                                                                            title: v.title,
                                                                                                                                                                                                                                                                                                          artist: v.author,
                                                                                                                                                                                                                                                                                                                        artUri: Uri.parse(v.thumbnails.highResUrl),
                                                                                                                                                                                                                                                                                                                                      duration: v.duration,
                                                                                                                                                                                                                                                                                                                                                  ),
                                                                                                                                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                                                                                                                                                                                    );
                                                                                                                                                                                                                                                                                                                                                                            player.play();
                                                                                                                                                                                                                                                                                                                                                                                    lastError = null;
                                                                                                                                                                                                                                                                                                                                                                                            break;
                                                                                                                                                                                                                                                                                                                                                                                                  } catch (e) {
                                                                                                                                                                                                                                                                                                                                                                                                          lastError = '$e';
                                                                                                                                                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                                                                                                                                                        if (lastError != null) {
                                                                                                                                                                                                                                                                                                                                                                                                                              setState(() => error = 'No se pudo reproducir: $lastError');
                                                                                                                                                                                                                                                                                                                                                                                                                                  }
                                                                                                                                                                                                                                                                                                                                                                                                                                      setState(() => loadingTrack = false);
                                                                                                                                                                                                                                                                                                                                                                                                                                        }
   } String fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🤘 Rock')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: search,
              decoration: InputDecoration(
                hintText: 'Busca una banda o canción',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: generos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ActionChip(
                label: Text(generos[i]),
                onPressed: () {
                  controller.text = generos[i];
                  search(generos[i]);
                },
              ),
            ),
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error!,
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (_, i) {
                final v = results[i];
                final activo = i == current;
                return ListTile(
                  selected: activo,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      v.thumbnails.lowResUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.music_note, size: 40),
                    ),
                  ),
                  title: Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${v.author} · ${fmt(v.duration ?? Duration.zero)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => playAt(i),
                );
              },
            ),
          ),
          if (current >= 0) _miniPlayer(),
        ],
      ),
    );
  }

  Widget _miniPlayer() {
    final v = results[current];
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (_, snap) {
                final pos = snap.data ?? Duration.zero;
                final dur = player.duration ?? Duration.zero;
                final max = dur.inMilliseconds.toDouble();
                final val = pos.inMilliseconds
                    .toDouble()
                    .clamp(0.0, max > 0 ? max : 1.0);
                return Row(
                  children: [
                    const SizedBox(width: 12),
                    Text(fmt(pos), style: const TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: val,
                        max: max > 0 ? max : 1.0,
                        onChanged: (x) =>
                            player.seek(Duration(milliseconds: x.toInt())),
                      ),
                    ),
                    Text(fmt(dur), style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      v.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: current > 0 ? () => playAt(current - 1) : null,
                  ),
                  loadingTrack
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        )
                      : StreamBuilder<PlayerState>(
                          stream: player.playerStateStream,
                          builder: (_, snap) {
                            final playing = snap.data?.playing ?? false;
                            return IconButton(
                              iconSize: 40,
                              icon: Icon(playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled),
                              onPressed: () =>
                                  playing ? player.pause() : player.play(),
                            );
                          },
                        ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: current + 1 < results.length
                        ? () => playAt(current + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
