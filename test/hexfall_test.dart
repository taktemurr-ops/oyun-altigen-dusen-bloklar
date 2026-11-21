import 'package:flutter_test/flutter_test.dart';
import 'package:oyun_altigen_dusen_bloklar/oyun_altigen_dusen_bloklar.dart';
import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/level_plan.dart';

void main() {
  final rules = HexFallRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  (HexFallSim, List<List<int>>) play(HexFallLevel l, int ticks) {
    final s = HexFallSim(l);
    final log = <List<int>>[];
    var last = ArcadeInput.idle;
    for (var t = 0; t < ticks && !s.over; t++) {
      final i = rules.bot(s).quantized();
      if (!i.sameAs(last)) {
        log.add([s.ticks + 1, ...i.encode()]);
        last = i;
      }
      s.tick(i);
    }
    return (s, log);
  }

  test('üç aynı renk silinir ve zincir sürer', () {
    final s = HexFallSim(rules.build(planner.spec(1)).puzzle);
    s.stacks[0].addAll([1, 1]);
    s.stacks[1].add(2);
    s.stacks[1].add(2);
    s.falling.add(FallingBlock(0, 50, 1));
    s.tick(ArcadeInput.idle);
    expect(s.stacks[0], isEmpty);
    expect(s.cleared, 3);
  });

  test('girdi kaydı yeniden oynatılınca tur aynen geri gelir', () {
    final l = rules.build(planner.spec(73)).puzzle;
    final (a, log) = play(l, 2500);
    final b = HexFallSim(l);
    replayLog(b, log, a.ticks);
    expect(b.score, a.score);
    expect(b.stacks, a.stacks);
  });

  test('kampanya bölümleri bot tarafından bitirilir', () {
    for (final lv in [1, 15, 40, 77, 120, 260, 555, 999, 4321, 9876, 25000, 49999]) {
      final g = rules.build(planner.spec(lv));
      expect(g.attempts, lessThan(40), reason: 'bölüm $lv kolaylaştırıldı');
      final s = HexFallSim(g.puzzle);
      final r = runBot(s, rules.bot, rules.maxTicks(g.puzzle));
      expect(r.won, isTrue, reason: 'bölüm $lv: ${s.cleared}/${g.puzzle.target}');
    }
  });

  test('dokunma: sol yarı sola, sağ yarı sağa döndürür', () {
    final s = HexFallSim(rules.build(planner.spec(2)).puzzle);
    s.tick(const ArcadeInput(down: true, x: 100, y: 800, tap: true));
    expect(s.rot, 5);
    s.tick(const ArcadeInput(down: true, x: 900, y: 800, tap: true));
    s.tick(const ArcadeInput(down: true, x: 900, y: 800, tap: true));
    expect(s.rot, 1);
  });

  test('her kip üretilir', () {
    for (final m in rules.modes) {
      expect(rules.build(planner.spec(31, mode: m)).puzzle.meta.mode, m);
    }
  });
}
