/// Platform detection utilities.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Whether the app is running on Android.
bool get isAndroid => !kIsWeb && Platform.isAndroid;

/// Whether the app is running on Windows desktop.
bool get isWindows => !kIsWeb && Platform.isWindows;

/// Whether the app is running on a desktop platform.
bool get isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// Whether the app is running on a mobile platform.
bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
