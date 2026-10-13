# Install on an iPod touch

## Direct Xcode development

The app requires iOS 15.0. On your iPod, check Settings → General → About → Software Version. Use a full Xcode whose **Device Support** includes that iOS version and whose macOS requirements match the Mac.

The inspected Mac runs macOS 27.0.1 with Xcode 27. It detects `iPod9,1` but reports unsupported pairing; the iPod is not a usable Run destination. Apple lists iOS 15 deployment targets for Xcode 27, but device support starts at iOS 17. Xcode 26.3 supports iOS 15 devices on Sequoia 15.6 through Tahoe 26.x; check the current [Apple compatibility table](https://developer.apple.com/xcode/system-requirements). Do not assume Xcode 26 can run on macOS 27.

On a compatible Mac/Xcode setup:

1. Connect an unlocked iPod with a Lightning data cable. Select it in Finder and complete the Trust prompts on the Mac and iPod.
2. Open `OfflineMusicPlayer.xcodeproj`. In Xcode's Devices and Simulators (or Device Hub), wait for pairing/preparation.
3. Sign into your Apple Account in Xcode Settings → Accounts/Apple Accounts. Select the OfflineMusicPlayer target → Signing & Capabilities → Automatically manage signing → your Team. A free account supplies a Personal Team.
4. Use a unique bundle identifier if necessary, and keep iOS deployment at 15.0. For tests, choose the same team for OfflineMusicPlayerTests with its own identifier.
5. Select the physical iPod as the destination and press Command-R. This creates a signed device build and installs/launches it. Complete developer-profile trust in Settings → General → VPN & Device Management if requested. iOS 15 has no iOS 16-style Developer Mode switch.
6. Add actual local music, then test navigation, playback, screen lock, Control Center and headphones. Disconnect and open Cassette from the Home Screen to test standalone use. Command-U runs the automated suite on a supported device setup.

Free Personal Team provisioning expires after seven days; reconnect and run again with the same bundle identifier. Initial signing setup may require internet, but the music app itself stays offline. See [Apple's device-run guide](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices), [Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account), and [Developer Mode version guidance](https://developer.apple.com/news/?id=r1sz7dke).

## IPA sideloading on the current Mac

The generated IPA is unsigned. [Sideloadly](https://sideloadly.io/) can sign/provision an IPA with a free or paid Apple Account and install it to an iOS 15 device. Its macOS 27 behavior has not been verified here.

1. Install Sideloadly from its official website.
2. Keep the iPod unlocked, connected and trusted by Finder.
3. Choose `Cassette-unsigned-<version>.ipa` in Sideloadly.
4. Select the iPod as destination, enter the Apple Account, and start. Enter passwords and two-factor codes yourself; never save them in this repository or chat.
5. Trust the developer profile on the iPod if prompted, then open Cassette. Free signing needs renewal after seven days. Keep the same account/bundle identifier when renewing to preserve app data. [Sideloadly FAQ](https://sideloadly.io/faq.html)

A properly provisioned/signed IPA can also be installed with Apple Configurator; the unsigned package alone cannot. [Apple's registered-device distribution guide](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices)

## File transfer and troubleshooting

Once Cassette is installed and opened, it creates its Documents directory and a small `Cassette Guide.txt` transfer guide so the folder is not empty. `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` stay enabled and are checked in both source and compiled app metadata. Other apps can choose Cassette through the Files picker; they do not receive unrestricted private app storage access.

To transfer from your Mac:

1. Connect, unlock and trust the iPod in Finder.
2. Select the iPod in Finder’s sidebar, then the **Files** tab.
3. Expand **Cassette** and drag MP3/M4A/WAV files from the Mac onto that app entry. For nested music/playlist/lyrics layouts, transfer the containing folder together.
4. Open Cassette or tap **Settings → Rescan Library** to discover the transferred files.

On the iPod, copy files into **Files → Browse → On My iPod → Cassette**. This is Finder file sharing, not a disk volume mounted in the Mac sidebar. If the app entry is missing, launch the installed app once, reconnect the trusted device, and confirm you installed the updated build without changing its identifier. No Music subfolder is required; the next opening/rescan discovers local audio recursively. Other local folders must be explicitly selected through Add Music Folder.

If Finder cannot see the iPod, unlock it and check the cable/trust prompts. If Finder sees it but Xcode does not offer it, check device-support compatibility. Missing signing profiles require account/team setup. Neither the unsigned build nor the Catalyst ad-hoc signature is an installable iPod signing profile. Deleting the app deletes its Documents and index, so reinstall/renew using the same identifier instead of removing it unnecessarily.
