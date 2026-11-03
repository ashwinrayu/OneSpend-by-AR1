import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final navigationIndexProvider = StateProvider<int>((ref) => 0);

final sidebarExpandedProvider = StateProvider<bool>((ref) => true);

