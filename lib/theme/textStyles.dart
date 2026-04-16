
import 'package:flutter/material.dart';

import 'colors.dart';

class ThemeTextStyles{

  static TextStyle normalTitle = const TextStyle( color: Colors.black);

  static TextStyle heading = const TextStyle(
    color: ThemeColor.black,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  static TextStyle splashScreen = const TextStyle(
    color: ThemeColor.white,
    fontSize: 25,
    fontWeight: FontWeight.bold,
  );


  static TextStyle label = const TextStyle(
    color: ThemeColor.black,
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  static TextStyle hint = const TextStyle(
    color: ThemeColor.black54,
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );



  static TextStyle keys = const TextStyle(
    color: ThemeColor.black,
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  static TextStyle values = const TextStyle(
    color: ThemeColor.black,
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
}