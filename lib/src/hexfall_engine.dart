import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/level_plan.dart';

/// Altıgen Düşen Bloklar: ortadaki altıgen döner; dışarıdan altı yönden
/// renkli bloklar gelir ve altıgenin o yöne bakan kenarına yığılır.
/// Birbirine değen aynı renkten üç ya da daha çok blok silinir.

const double kCx = kWorldW / 2;
const double kCy = kWorldH / 2 + 60;
const double kBaseR = 92; // altıgenin iç yarıçapı (kenara uzaklık)
const double kLayerH = 40;
const int kMaxLayers = 8;
const double kSpawnDist = 720;

class HexFallLevel {
  final ArcadeMeta meta;
  final int colors;
  final int spawnTicks;
  final double speed;
  final int target; // silinecek blok; 0 = hedefsiz
  const HexFallLevel({
    required this.meta,
    required this.colors,
    required this.spawnTicks,
    required this.speed,
    required this.target,
  });
}

HexFallLevel generateHexFallLevel(LevelSpec spec) {
  final m = ArcadeMeta.of(spec);
  final d = spec.difficulty.clamp(1, 10);
  final colors = spec.has('colors5') ? 5 : (d >= 7 ? 4 : 3);
  var spawn = (78 - d * 4).clamp(36, 78);
  if (spec.has('fast')) spawn = (spawn - 8).clamp(30, 78);
  final speed = 3.0 + d * 0.28 + (spec.has('fast') ? 0.8 : 0);
  return HexFallLevel(
    meta: m,
    colors: colors,
    spawnTicks: spawn,
    speed: speed,
    target: m.goal ? 24 + d * 6 : 0,
  );
}

class FallingBlock {
  final int dir; // dünya yönü 0..5 (0 = yukarı, saat yönünde)
  double dist;
  final int color;
  FallingBlock(this.dir, this.dist, this.color);
}

class HexFallSim extends ArcadeSim {
  final HexFallLevel level;

  /// stacks[kenar] = içten dışa renkler.
  final List<List<int>> stacks = List.generate(6, (_) => <int>[]);
  final List<FallingBlock> falling = [];
  int rot = 0; // altıgenin dönüşü (adım)
  double rotVis = 0; // boyama için yumuşak dönüş
  int spawnTimer = 0;
  int cleared = 0, groups = 0, bestGroup = 0, rotations = 0;
  int lastEvent = 0; // 1 kondu, 2 silindi, 3 büyük silme, 4 döndü, 5 taştı
  int flash = 0;

  // Bot hedefi
  int botTarget = 0, botWait = 0;

  HexFallSim(this.level) : super(level.meta);

  int sideFor(int dir) => ((dir - rot) % 6 + 6) % 6;

  void rotate(int step) {
    rot = (rot + step) % 6;
    rotations++;
    lastEvent = lastEvent == 0 ? 4 : lastEvent;
  }

  @override
  void update(ArcadeInput input) {
    lastEvent = 0;
    if (flash > 0) flash--;
    // Girdi: dokunma soldaysa sola, sağdaysa sağa döndür; kaydırma ve oklar da.
    if (input.tap && input.hasPointer) {
      rotate(input.x < kWorldW / 2 ? -1 : 1);
    } else if (input.swipe == 3) {
      rotate(-1);
    } else if (input.swipe == 1) {
      rotate(1);
    }
    // Görsel dönüş
    final targetVis = rot.toDouble();
    var diff = targetVis - rotVis;
    while (diff > 3) {
      diff -= 6;
    }
    while (diff < -3) {
      diff += 6;
    }
    rotVis = (diff.abs() < 0.05) ? targetVis : rotVis + diff * 0.35;

    spawnTimer++;
    if (spawnTimer >= level.spawnTicks) {
      spawnTimer = 0;
      falling.add(FallingBlock(rng.nextInt(6), kSpawnDist, 1 + rng.nextInt(level.colors)));
    }
    final speed = level.meta.goal ? level.speed : level.speed + (cleared ~/ 30) * 0.3;
    for (var i = falling.length - 1; i >= 0; i--) {
      final b = falling[i];
      b.dist -= speed;
      final side = sideFor(b.dir);
      final land = kBaseR + stacks[side].length * kLayerH;
      if (b.dist <= land) {
        falling.removeAt(i);
        stacks[side].add(b.color);
        lastEvent = 1;
        _resolve(side, stacks[side].length - 1);
        if (stacks[side].length > kMaxLayers) {
          lastEvent = 5;
          final before = lives;
          hit();
          if (!over && lives == before) _trim();
        }
        if (over) return;
      }
    }
    if (level.target > 0 && cleared >= level.target) win();
  }

  @override
  void onLifeLost() => _trim();

  void _trim() {
    for (final s in stacks) {
      if (s.length > 3) s.removeRange(3, s.length);
    }
    falling.clear();
  }

  /// (kenar, katman) çevresinde aynı renk grubu; zincirleme silme.
  void _resolve(int side, int layer) {
    var chain = 0;
    var seeds = [(side, layer)];
    while (seeds.isNotEmpty) {
      final remove = <(int, int)>{};
      for (final s in seeds) {
        if (s.$2 >= stacks[s.$1].length) continue;
        final g = _group(s.$1, s.$2);
        if (g.length >= 3) remove.addAll(g);
      }
      if (remove.isEmpty) break;
      chain++;
      final n = remove.length;
      cleared += n;
      groups++;
      if (n > bestGroup) bestGroup = n;
      score += n * 10 * chain + (n - 3) * 15;
      lastEvent = n >= 5 || chain > 1 ? 3 : 2;
      flash = 14;
      // Kenar başına üstten aşağı sil.
      for (var k = 0; k < 6; k++) {
        final idx = [for (final r in remove) if (r.$1 == k) r.$2]..sort((a, b) => b - a);
        for (final i in idx) {
          stacks[k].removeAt(i);
        }
      }
      // Kayan bloklar yeni gruplar oluşturabilir: bütün tahtayı tara.
      seeds = [
        for (var k = 0; k < 6; k++)
          for (var l = 0; l < stacks[k].length; l++) (k, l)
      ];
    }
  }

  Set<(int, int)> _group(int side, int layer) {
    final c = stacks[side][layer];
    final seen = <(int, int)>{(side, layer)};
    final st = [(side, layer)];
    while (st.isNotEmpty) {
      final (s, l) = st.removeLast();
      for (final n in [(s, l - 1), (s, l + 1), ((s + 1) % 6, l), ((s + 5) % 6, l)]) {
        if (n.$2 < 0 || n.$2 >= stacks[n.$1].length) continue;
        if (stacks[n.$1][n.$2] != c || seen.contains(n)) continue;
        seen.add(n);
        st.add(n);
      }
    }
    return seen;
  }

  @override
  double get progress => level.target == 0 ? 0 : (cleared / level.target).clamp(0, 1).toDouble();

  @override
  String get goalText => level.target == 0 ? '$cleared' : '$cleared/${level.target}';

  @override
  Map<String, int> get stats => {
        'blocks_cleared': cleared,
        'groups': groups,
        'best_group': bestGroup,
      };

  @override
  int get stars => lifeStars(this, 3);

  /// Güçlendirici: her kenarın en dış iki bloğunu siler.
  @override
  bool useBooster() {
    if (over) return false;
    for (final s in stacks) {
      if (s.isNotEmpty) s.removeLast();
      if (s.isNotEmpty) s.removeLast();
    }
    flash = 14;
    lastEvent = 2;
    return true;
  }
}

/// Bot: en yakın bloğun en iyi kenara düşmesi için altıgeni döndürür.
ArcadeInput hexFallBot(ArcadeSim s) {
  final g = s as HexFallSim;
  if (g.falling.isEmpty) return ArcadeInput.idle;
  var near = g.falling.first;
  for (final b in g.falling) {
    if (b.dist < near.dist) near = b;
  }
  // Her dönüş için puan.
  var bestRot = g.rot;
  var bestV = -1e9;
  for (var r = 0; r < 6; r++) {
    final side = ((near.dir - r) % 6 + 6) % 6;
    final st = g.stacks[side];
    var v = -st.length * 3.0;
    if (st.isNotEmpty && st.last == near.color) v += 12;
    if (st.length >= 2 && st[st.length - 1] == near.color && st[st.length - 2] == near.color) v += 10;
    final layer = st.length;
    for (final n in [(side + 1) % 6, (side + 5) % 6]) {
      if (layer < g.stacks[n].length && g.stacks[n][layer] == near.color) v += 9;
    }
    if (st.length >= kMaxLayers) v -= 100;
    // Diğer düşen blokları da bozma: dönüş mesafesi küçük olsun.
    final dist = ((r - g.rot) % 6 + 6) % 6;
    v -= (dist > 3 ? 6 - dist : dist) * 0.8;
    if (v > bestV) {
      bestV = v;
      bestRot = r;
    }
  }
  if (bestRot == g.rot) return ArcadeInput.idle;
  if (g.botWait > 0) {
    g.botWait--;
    return ArcadeInput.idle;
  }
  g.botWait = 4;
  final d = ((bestRot - g.rot) % 6 + 6) % 6;
  return ArcadeInput(swipe: d <= 3 ? 1 : 3);
}
