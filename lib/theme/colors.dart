import 'package:flutter/material.dart';




class ThemeColor {


  //static const Color backGroundColor = Color(0xFFF6F6EE);
  static const Color backGroundColor = Color(0xFFFFF8EC);

  //static const Color black = Color(0xFF000000);
  static const Color black = Color(0xFF1C1C30);
  static const Color black54 = Colors.black54;
  static const Color white = Color(0xFFFFFFFF);

 // static const Color cyan = Color(0xFFACD1BF);
  static const Color primary = Color(0xFFD27146);

  //static const Color yellow = Color(0xFFE9DA73);
  static const Color yellow = Color(0xFF1C1C30);
}

class ThemeGradient {
  static LinearGradient primary = LinearGradient(colors: [HexColor("#EF5656"), HexColor("#FC333F")], begin: Alignment.centerLeft, end: Alignment.centerRight);
  static LinearGradient blueBlack = LinearGradient(colors: [HexColor("#373B44"), HexColor("#4286F4")], begin: Alignment.centerLeft, end: Alignment.centerRight);
  static LinearGradient secondary = LinearGradient(colors: [HexColor("#A62929"), HexColor("#FE1010")], begin: Alignment.centerLeft, end: Alignment.centerRight);
  static LinearGradient red = LinearGradient(colors: [HexColor("#D96565"), HexColor("#B91A1A")], begin: Alignment.centerLeft, end: Alignment.centerRight);
  static LinearGradient chokmoke = LinearGradient(colors: [HexColor("#FA4A4E"), HexColor("#6457F5")], begin: Alignment.centerLeft, end: Alignment.centerRight);
  static LinearGradient pink = LinearGradient(colors: [HexColor("#D4488B"), HexColor("#FF2876")], begin: Alignment.centerLeft, end: Alignment.centerRight);
  static LinearGradient lite = LinearGradient(colors: [HexColor("#D8D3D3"), HexColor("#EE6C6C")], begin: Alignment.centerLeft, end: Alignment.centerRight);
  static LinearGradient orange = LinearGradient(colors: [HexColor("#ED8A6B"), HexColor("#D15353")], begin: Alignment.topLeft, end: Alignment.bottomRight, stops: const [0.25, 0.75]);
  static LinearGradient advancedSearch = LinearGradient(colors: [HexColor("#dd6161"), HexColor("#ea8686")], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.5, 1]);
  static LinearGradient gold = LinearGradient(colors: [HexColor("#FFFFFF"), HexColor("#e0dbc0"), HexColor("#C7BE8E")], begin: Alignment.topCenter, end: Alignment.bottomCenter);
  static LinearGradient semiTransparentBlack = LinearGradient(colors: [Colors.transparent, HexColor("#181717").withValues(alpha: .7)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
  static LinearGradient semiTransparentWhite =
      LinearGradient(colors: [HexColor("#ffffff").withValues(alpha: 0), HexColor("#ffffff").withValues(alpha: 1)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.2, .8]);
  static LinearGradient qtrTransparentWhite =
      LinearGradient(colors: [HexColor("#ffffff").withValues(alpha: 0), HexColor("#ffffff").withValues(alpha: 1)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.6, 1]);
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }

    final hexNum = int.parse(hexColor, radix: 16);

    if (hexNum == 0) {
      return 0xff000000;
    }

    return hexNum;
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

class ColorToHex extends Color {
  ///convert material colors to hexcolor
  static int _convertColorTHex(Color color) {
    var hex = '${color.value}';
    return int.parse(
      hex,
    );
  }

  ColorToHex(final Color color) : super(_convertColorTHex(color));
}
