import 'package:flutter/material.dart';
import 'package:here_sdk/consent.dart';
import 'package:here_sdk/core.dart';
import 'package:searches_demo/pages/map_view.dart';

import 'values/strings.dart';

void main() {
  SdkContext.init(IsolateOrigin.main);
  runApp(const MySearchApp());
}

class MySearchApp extends StatelessWidget {
  const MySearchApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Add consent localization delegates.
      localizationsDelegates: HereSdkConsentLocalizations.localizationsDelegates,
      // Add supported locales.
      supportedLocales: HereSdkConsentLocalizations.supportedLocales,
      title: titleApp,
      home: MyMapViewPage(title: titleApp),
    );
  }
}