import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shorebird Code Push Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

// state of the shorebird updater
final updaterProvider = Provider((ref) => ShorebirdUpdater());

///read current patch
final currentPatchProvider = FutureProvider<Patch?>((ref) {
  final updater = ref.watch(updaterProvider);
  return updater.readCurrentPatch();
});

final isUpdaterAvailableProvider = Provider((ref) {
  final updater = ref.watch(updaterProvider);
  return updater.isAvailable;
});

///track of the update
final updateTrackProvider = StateProvider((ref) => UpdateTrack.stable);
final isCheckingForUpdatesProvider = StateProvider((ref) => false);

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// Read the providers.

    final updater = ref.watch(updaterProvider);
    final currentPatch = ref.watch(currentPatchProvider);
    final isUpdaterAvailable = ref.watch(isUpdaterAvailableProvider);
    final currentTrack = ref.watch(updateTrackProvider);
    final isCheckingForUpdates = ref.watch(isCheckingForUpdatesProvider);

    /// Download an update and show a banner with the result.

    Future<void> downloadUpdate(BuildContext context, ShorebirdUpdater updater,
        UpdateTrack track) async {
      _showBanner(context, 'Downloading...', isLoading: true);
      try {
        await updater.update(track: track);
        if (context.mounted) {
          _showBanner(context, 'Update ready! Please restart your app.');
        }
      } catch (e) {
        if (context.mounted) {
          _showBanner(context, 'Error downloading update: $e');
        }
      }
    }

    /// Check for an update and show a banner with the result.

    Future<void> checkForUpdate() async {
      if (ref.read(isCheckingForUpdatesProvider)) return;
      ref.read(isCheckingForUpdatesProvider.notifier).state = true;

      try {
        final status = await updater.checkForUpdate(track: currentTrack);

        if (context.mounted) {
          switch (status) {
            case UpdateStatus.upToDate:
              _showBanner(context,
                  'No update available on the ${currentTrack.name} track.');
              break;
            case UpdateStatus.outdated:
              _showBanner(context,
                  'Update available for the ${currentTrack.name} track.',
                  actionLabel: 'Download',
                  action: () => downloadUpdate(context, updater, currentTrack));
              break;
            case UpdateStatus.restartRequired:
              _showBanner(
                  context, 'A new patch is ready! Please restart your app.');
              break;
            case UpdateStatus.unavailable:
              _showBanner(context, 'Update unavailable.');
          }
        }
      } catch (e) {
        if (context.mounted) {
          _showBanner(context, 'Error checking for updates: $e');
        }
      } finally {
        ref.read(isCheckingForUpdatesProvider.notifier).state = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shorebird Code Push'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isUpdaterAvailable) const _ShorebirdUnavailable(),
          const Spacer(),
          currentPatch.when(
            data: (patch) => _CurrentPatchVersion(patch: patch),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 12),
          _TrackPicker(
            currentTrack: currentTrack,
            onChanged: (track) =>
                ref.read(updateTrackProvider.notifier).state = track,
          ),
          const Spacer(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isCheckingForUpdates ? null : checkForUpdate,
        tooltip: 'Check for update',
        child: isCheckingForUpdates
            ? const CircularProgressIndicator()
            : const Icon(Icons.refresh),
      ),
    );
  }

  void _showBanner(BuildContext context, String message,
      {String? actionLabel, VoidCallback? action, bool isLoading = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          content: Row(
            children: [
              Expanded(child: Text(message)),
              if (isLoading) const CircularProgressIndicator(),
            ],
          ),
          actions: [
            if (action != null)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  action();
                },
                child: Text(actionLabel ?? 'Dismiss'),
              ),
          ],
        ),
      );
  }
}

class _ShorebirdUnavailable extends StatelessWidget {
  const _ShorebirdUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Shorebird is not available. Please ensure the app was released via `shorebird release` and is running in release mode.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _CurrentPatchVersion extends StatelessWidget {
  const _CurrentPatchVersion({required this.patch});

  final Patch? patch;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Current patch version:'),
        Text(patch != null ? '${patch!.number}' : 'No patch installed'),
      ],
    );
  }
}

class _TrackPicker extends StatelessWidget {
  const _TrackPicker({required this.currentTrack, required this.onChanged});

  final UpdateTrack currentTrack;
  final ValueChanged<UpdateTrack> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Update track:'),
        SegmentedButton<UpdateTrack>(
          segments: const [
            ButtonSegment(label: Text('Stable'), value: UpdateTrack.stable),
            ButtonSegment(
                label: Text('Beta'),
                icon: Icon(Icons.science),
                value: UpdateTrack.beta),
            ButtonSegment(
                label: Text('Staging'),
                icon: Icon(Icons.construction),
                value: UpdateTrack.staging),
          ],
          selected: {currentTrack},
          onSelectionChanged: (tracks) => onChanged(tracks.single),
        ),
      ],
    );
  }
}
