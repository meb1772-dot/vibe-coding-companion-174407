# Convenience make targets for building and copying APK artifacts.
# These targets do not attempt to install dependencies or run interactively.
# The copy script outputs a versioned filename at the repo root:
#   vibe_coding_companion-v<version>-c<code>.apk
# and prints the final destination path on success.

.PHONY: build-debug-apk build-release-apk copy-apk

build-debug-apk:
	flutter build apk --debug

build-release-apk:
	flutter build apk --release

copy-apk:
	dart run tool/copy_apk.dart
