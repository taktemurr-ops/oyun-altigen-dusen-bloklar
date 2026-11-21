/// Altıgen Düşen Bloklar: altıgeni döndür, aynı renkleri buluştur.
/// Blok Oyunları merkez uygulamasının oyunu.
library;

import 'package:flutter/material.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/core/game_rules.dart';

import 'src/hexfall_engine.dart';
import 'src/hexfall_rules.dart';
import 'src/hexfall_view.dart';

export 'src/hexfall_engine.dart';
export 'src/hexfall_rules.dart';

final altigenDusenConfig = GameConfig(
  gameId: altigenDusenId,
  title: const ['Altıgen Yağmuru', 'Hex Rain', 'Hex-Regen', 'Lluvia Hexagonal', 'Pluie Hexagonale'],
  tagline: const [
    'Altıgeni döndür, renkleri buluştur!',
    'Spin the hexagon, match the colors!',
    'Dreh das Sechseck, finde Farben!',
    '¡Gira el hexágono y une colores!',
    'Tournez l\'hexagone, associez les couleurs !',
  ],
  seedColor: const Color(0xFFEC407A),
  icon: Icons.change_history_rounded,
  rules: HexFallRules(),
  buildPlay: (ctx) => buildHexFallStage(ctx, (ctx.generated as GeneratedLevel<HexFallLevel>).puzzle),
  tutorial: const [
    TutorialStep(Icons.rotate_right, [
      'Ekranın sağına ya da soluna dokunarak ortadaki altıgeni döndür.',
      'Tap the right or left side to spin the hexagon.',
      'Tippe rechts oder links, um das Sechseck zu drehen.',
      'Toca a la derecha o izquierda para girar el hexágono.',
      'Touchez à droite ou à gauche pour tourner l\'hexagone.',
    ]),
    TutorialStep(Icons.palette, [
      'Gelen blok altıgenin o yöne bakan kenarına konur. Değen 3 aynı renk silinir.',
      'Blocks stack on the facing side. Three touching of one color clear.',
      'Blöcke stapeln sich. Drei gleiche Farben verschwinden.',
      'Los bloques se apilan. Tres del mismo color desaparecen.',
      'Les blocs s\'empilent. Trois de même couleur disparaissent.',
    ]),
    TutorialStep(Icons.warning_amber, [
      'Bir kenar dış çizgiyi aşarsa can gider.',
      'If a side passes the outer line you lose a life.',
      'Überschreitet eine Seite die Linie, verlierst du ein Leben.',
      'Si un lado pasa la línea, pierdes una vida.',
      'Si un côté dépasse la ligne, vous perdez une vie.',
    ]),
  ],
);
