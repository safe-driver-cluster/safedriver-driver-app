// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

Widget buildWebMapEmbed({
  required double latitude,
  required double longitude,
  required String markerLabel,
}) {
  final safeLat = latitude.clamp(-85.0, 85.0).toDouble();
  final safeLng = longitude.clamp(-180.0, 180.0).toDouble();
  final viewType =
      'safedriver-osm-${safeLat.toStringAsFixed(5)}-${safeLng.toStringAsFixed(5)}';

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    const delta = 0.035;
    final bbox = [
      safeLng - delta,
      safeLat - delta,
      safeLng + delta,
      safeLat + delta,
    ].map((value) => value.toStringAsFixed(6)).join(',');
    final src = Uri.https('www.openstreetmap.org', '/export/embed.html', {
      'bbox': bbox,
      'layer': 'mapnik',
      'marker': '${safeLat.toStringAsFixed(6)},${safeLng.toStringAsFixed(6)}',
    }).toString();

    return html.IFrameElement()
      ..src = src
      ..title = markerLabel.isEmpty ? 'SafeDriver map' : markerLabel
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'block';
  });

  return HtmlElementView(viewType: viewType);
}
