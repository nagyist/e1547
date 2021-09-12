import 'package:e1547/interface/interface.dart';
import 'package:e1547/settings/settings.dart';
import 'package:flutter/material.dart';

mixin TileSizeMixin<T extends StatefulWidget> on State<T> {
  double tileHeightFactor = 1.2;
  int? tileSize;

  void updateTileSize() {
    setState(() {
      tileSize = settings.tileSize.value;
    });
  }

  int crossAxisCount(double width) {
    assert(tileSize != null);
    return notZero(width / tileSize!).round();
  }

  @override
  void initState() {
    super.initState();
    settings.tileSize.addListener(updateTileSize);
    updateTileSize();
  }

  @override
  void reassemble() {
    super.reassemble();
    settings.tileSize.removeListener(updateTileSize);
    settings.tileSize.addListener(updateTileSize);
  }

  @override
  void dispose() {
    super.dispose();
    settings.tileSize.removeListener(updateTileSize);
  }
}

mixin TileStaggerMixin<T extends StatefulWidget> on State<T> {
  GridState? stagger;

  void updateStagger() {
    setState(() {
      stagger = settings.stagger.value;
    });
  }

  @override
  void initState() {
    super.initState();
    settings.stagger.addListener(updateStagger);
    updateStagger();
  }

  @override
  void reassemble() {
    super.reassemble();
    settings.stagger.removeListener(updateStagger);
    settings.stagger.addListener(updateStagger);
  }

  @override
  void dispose() {
    super.dispose();
    settings.stagger.removeListener(updateStagger);
  }
}
