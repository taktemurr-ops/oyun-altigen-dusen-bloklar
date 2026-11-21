import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:studio_core/app/arcade_stage.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/app/play_kit.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/core/arcade.dart';

import 'hexfall_engine.dart';

const _cbMarks = ['', '●', '▲', '■', '◆', '★'];

/// Yön k için açı: 0 yukarı, saat yönünde 60°.
double _angle(double k) => (-90 + k * 60) * math.pi / 180;

Path _segment(double dir, double inner, double outer) {
  final a0 = _angle(dir) - math.pi / 6, a1 = _angle(dir) + math.pi / 6;
  final k = 1 / math.cos(math.pi / 6);
  Offset p(double a, double r) => Offset(kCx + math.cos(a) * r * k, kCy + math.sin(a) * r * k);
  return Path()
    ..moveTo(p(a0, inner).dx, p(a0, inner).dy)
    ..lineTo(p(a1, inner).dx, p(a1, inner).dy)
    ..lineTo(p(a1, outer).dx, p(a1, outer).dy)
    ..lineTo(p(a0, outer).dx, p(a0, outer).dy)
    ..close();
}

void paintHexFall(Canvas c, ArcadeSim sim, ArcadePalette p, double t) {
  final s = sim as HexFallSim;
  // Sınır çizgisi
  final limit = kBaseR + kMaxLayers * kLayerH;
  final ring = Path();
  for (var k = 0; k < 6; k++) {
    ring.addPath(_segment(k.toDouble(), limit - 3, limit), Offset.zero);
  }
  c.drawPath(ring, Paint()..color = Colors.white.withValues(alpha: 0.12));
  // Yön çizgileri
  for (var k = 0; k < 6; k++) {
    final a = _angle(k + 0.5);
    c.drawLine(Offset(kCx, kCy), Offset(kCx + math.cos(a) * 760, kCy + math.sin(a) * 760),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04)
          ..strokeWidth = 3);
  }
  // Altıgen ve yığınlar (dönmüş halde)
  for (var side = 0; side < 6; side++) {
    final dir = side + s.rotVis;
    c.drawPath(_segment(dir, 0, kBaseR - 4), Paint()..color = Colors.white.withValues(alpha: 0.16 + 0.04 * (side % 2)));
    final st = s.stacks[side];
    for (var l = 0; l < st.length; l++) {
      final inner = kBaseR + l * kLayerH + 2, outer = kBaseR + (l + 1) * kLayerH - 2;
      final col = p.piece(st[l] - 1);
      c.drawPath(_segment(dir, inner, outer), Paint()..color = col);
      if (p.colorBlind) {
        final a = _angle(dir), r = (inner + outer) / 2;
        paintText(c, _cbMarks[st[l] % _cbMarks.length], Offset(kCx + math.cos(a) * r, kCy + math.sin(a) * r), 22,
            Colors.black.withValues(alpha: 0.5));
      }
    }
  }
  if (s.flash > 0 && !p.reducedMotion) {
    c.drawCircle(Offset(kCx, kCy), kBaseR * (1 + s.flash / 14 * 0.25),
        Paint()..color = Colors.white.withValues(alpha: s.flash / 14 * 0.25));
  }
  // Düşen bloklar (dünya yönünde, dönmez)
  for (final b in s.falling) {
    final col = p.piece(b.color - 1);
    c.drawPath(_segment(b.dir.toDouble(), b.dist, b.dist + kLayerH - 4), Paint()..color = col);
    if (p.colorBlind) {
      final a = _angle(b.dir.toDouble()), r = b.dist + kLayerH / 2;
      paintText(c, _cbMarks[b.color % _cbMarks.length], Offset(kCx + math.cos(a) * r, kCy + math.sin(a) * r), 22,
          Colors.black.withValues(alpha: 0.5));
    }
  }
  // Döndürme ipucu okları
  paintText(c, '⟲', const Offset(90, kWorldH - 110), 70, Colors.white.withValues(alpha: 0.25));
  paintText(c, '⟳', const Offset(kWorldW - 90, kWorldH - 110), 70, Colors.white.withValues(alpha: 0.25));
}

Sfx? hexFallSound(ArcadeSim sim) => switch ((sim as HexFallSim).lastEvent) {
      1 => Sfx.place,
      2 => Sfx.clear,
      3 => Sfx.combo,
      4 => Sfx.tap,
      5 => Sfx.lose,
      _ => null,
    };

Widget buildHexFallStage(PlayContext ctx, HexFallLevel level) => ArcadeStage(
      ctx: ctx,
      create: () => HexFallSim(level),
      paint: paintHexFall,
      sound: hexFallSound,
      boosterIcon: Icons.layers_clear,
      boosterLabel: (l) => l == 'tr' ? 'Dış katmanları sil' : 'Clear outer layers',
      howTo: const [
        'Ekranın soluna dokun: sola döndür · Sağına dokun: sağa döndür',
        'Tap left: turn left · Tap right: turn right',
        'Links tippen: nach links drehen · Rechts tippen: nach rechts',
        'Toca a la izquierda: girar a la izquierda · Derecha: a la derecha',
        'Touchez à gauche : tourner à gauche · À droite : à droite',
      // ar fa he ur ru uk pl cs ro hu el it pt nl sv da nb fi ja ko zh hi bn id ms th vi fil
      'المس اليسار: دوران لليسار · اليمين: دوران لليمين',
      'لمس چپ: چرخش به چپ · لمس راست: چرخش به راست',
      'שמאל: סיבוב שמאלה · ימין: סיבוב ימינה',
      'بائیں: بائیں گھمائیں · دائیں: دائیں گھمائیں',
      'Слева: поворот влево · Справа: поворот вправо',
      'Зліва: поворот ліворуч · Справа: поворот праворуч',
      'Lewa strona: obrót w lewo · Prawa: obrót w prawo',
      'Vlevo: otočit doleva · Vpravo: otočit doprava',
      'Stânga: rotire la stânga · Dreapta: rotire la dreapta',
      'Bal: balra fordul · Jobb: jobbra fordul',
      'Αριστερά: στροφή αριστερά · Δεξιά: στροφή δεξιά',
      'Tocca a sinistra: ruota a sinistra · A destra: ruota a destra',
      'Toque à esquerda: girar à esquerda · À direita: girar à direita',
      'Tik links: linksom · Tik rechts: rechtsom',
      'Vänster: vrid åt vänster · Höger: vrid åt höger',
      'Venstre: drej til venstre · Højre: drej til højre',
      'Venstre: snu mot venstre · Høyre: snu mot høyre',
      'Vasen: käänny vasemmalle · Oikea: käänny oikealle',
      '左タップ:左回転・右タップ:右回転',
      '왼쪽: 왼쪽 회전 · 오른쪽: 오른쪽 회전',
      '点左：向左转 · 点右：向右转',
      'बाएँ: बाएँ घुमाएँ · दाएँ: दाएँ घुमाएँ',
      'বাঁ: বাঁয়ে ঘোরান · ডান: ডানে ঘোরান',
      'Ketuk kiri: putar kiri · Ketuk kanan: putar kanan',
      'Ketik kiri: putar kiri · Ketik kanan: putar kanan',
      'แตะซ้าย: หมุนซ้าย · แตะขวา: หมุนขวา',
      'Chạm trái: xoay trái · Chạm phải: xoay phải',
      'Kaliwa: ikot pakaliwa · Kanan: ikot pakanan',
    ],
    );
