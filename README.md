# shore_bird_installation_in_cli

1. copy paste to Terminal
Set-ExecutionPolicy RemoteSigned -scope CurrentUser # Needed to execute remote scripts
iwr -UseBasicParsing 'https://raw.githubusercontent.com/shorebirdtech/install/main/install.ps1'|iex

2. Configure Flavors
    Next, edit the android/app/build.gradle to contain two productFlavors:

    defaultConfig {
    ...
}

    flavorDimensions "track"
    productFlavors {
        internal {
            dimension "track"
            applicationIdSuffix ".internal"
            manifestPlaceholders = [applicationLabel: "[Internal] Shorebird Example"]
        }
        stable {
            dimension "track"
            manifestPlaceholders = [applicationLabel: "Shorebird Example"]
        }
    }

buildTypes {
  ...
}

3. Lastly, edit android/app/src/main/AndroidManifest.xml to use the applicationLabel so that we can differentiate the two apps easily:
    remove this line   <application android:label="flavors" android:name="${applicationName}" android:icon="@mipmap/ic_launcher">
    and add this line <application android:label="${applicationLabel}" android:name="${applicationName}" android:icon="@mipmap/ic_launcher">
4. Login ShoreBird
    shorebird login
5. add in pubspec.yaml
flutter:
  assets:
    - shorebird.yaml
6. Initialize Shorebird 
    shorebird init
    
# it will automatically generate shorebird.yaml file

7. flutter pub get
8. create release
    shorebird release android
    shorebird preview
9. create a patch
    Change Application codes
10. After making this change, save the file and run:
    shorebird patch android 
    
11. Fore More Details :- https://docs.shorebird.dev/

# shore_bird_hot_push

1. State Management with Riverpod
Providers:
updaterProvider: Provides an instance of ShorebirdUpdater, which handles the update process.
currentPatchProvider: Reads the currently installed patch using readCurrentPatch (asynchronous).
isUpdaterAvailableProvider: Checks if the updater is available.
updateTrackProvider: Maintains the selected update track (e.g., stable, beta).
isCheckingForUpdatesProvider: Tracks if an update check is in progress.

2.Core Logic:

Check for Updates:
Calls checkForUpdate when the floating action button is pressed.
Handles UpdateStatus (e.g., upToDate, outdated, restartRequired) and displays appropriate banners using _showBanner.
Download Updates:
Triggered if an update is available. Downloads the patch and shows banners for progress and errors.
Banner Notifications:

_showBanner handles UI feedback for actions such as checking for updates, downloading patches, and error handling.
Supports optional loading indicators and action buttons.

3. Supporting Widgets
_ShorebirdUnavailable:

Displays a message when Shorebird is unavailable (e.g., not in release mode).
_CurrentPatchVersion:

Shows the current patch version or a message if no patch is installed. It utilizes Riverpod’s currentPatchProvider for data handling.
_TrackPicker:

Allows the user to switch between update tracks (e.g., stable, beta, staging) using a segmented button.