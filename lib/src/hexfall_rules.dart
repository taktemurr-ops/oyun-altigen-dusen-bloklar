import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/missions.dart';
import 'package:studio_core/core/stats.dart';

import 'hexfall_engine.dart';

const altigenDusenId = 'oyun-altigen-dusen-bloklar';

class HexFallRules extends ArcadeRules<HexFallLevel> {
  @override
  String get gameId => altigenDusenId;

  @override
  List<String> get optionalMechanics => const ['fast', 'colors5'];

  @override
  List<GameStat> get gameStats => const [
        GameStat('blocks_cleared', 'Silinen blok', 'Blocks cleared', scale: 60),
        GameStat('groups', 'Grup', 'Groups', scale: 15),
        GameStat('best_group', 'En büyük grup', 'Biggest group', scale: 2),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('blocks_cleared', 'blocks_cleared', [40, 120, 300]),
        MissionTemplate('groups', 'groups', [10, 30, 70]),
      ];

  @override
  HexFallLevel generate(LevelSpec spec) => generateHexFallLevel(spec);

  @override
  ArcadeMeta metaOf(HexFallLevel l) => l.meta;

  @override
  ArcadeSim createSim(HexFallLevel l) => HexFallSim(l);

  @override
  ArcadeInput bot(ArcadeSim sim) => hexFallBot(sim);
}
