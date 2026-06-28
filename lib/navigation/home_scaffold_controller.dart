import 'package:flutter/material.dart';

final homeScaffoldKey = GlobalKey<ScaffoldState>();

void openHomeDrawer() {
  homeScaffoldKey.currentState?.openDrawer();
}
