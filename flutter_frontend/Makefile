# Convenience make targets for building and copying APK artifacts.
# These targets do not attempt to install dependencies or run interactively.

.PHONY: build-debug-apk build-release-apk copy-apk

build-debug-apk:
\tflutter build apk --debug

build-release-apk:
\tflutter build apk --release

copy-apk:
\tdart run tool/copy_apk.dart
