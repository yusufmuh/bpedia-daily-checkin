import 'package:flutter/painting.dart';

import 'kit/sprite_sheet.dart';

const String _package = 'daily_checkin';

/// Seni 3D, pose Bipy, dan stiker milik modul (dirujuk dengan `package:`).
abstract final class CheckInArt {
  /// Koin Kelopak 3D.
  static const AssetImage coin = AssetImage(
    'assets/art/coin.webp',
    package: _package,
  );

  /// Kotak hadiah tertutup.
  static const AssetImage giftClosed = AssetImage(
    'assets/art/gift_closed.webp',
    package: _package,
  );

  /// Kotak hadiah terbuka dengan koin menyembur.
  static const AssetImage giftOpen = AssetImage(
    'assets/art/gift_open.webp',
    package: _package,
  );

  /// Kalender bercentang.
  static const AssetImage calendar = AssetImage(
    'assets/art/calendar.webp',
    package: _package,
  );

  /// Pot tulip, lima tahap tumbuh (indeks 0 = tunas, 4 = mekar penuh).
  static const List<AssetImage> tulips = <AssetImage>[
    AssetImage('assets/art/tulip_1.webp', package: _package),
    AssetImage('assets/art/tulip_2.webp', package: _package),
    AssetImage('assets/art/tulip_3.webp', package: _package),
    AssetImage('assets/art/tulip_4.webp', package: _package),
    AssetImage('assets/art/tulip_5.webp', package: _package),
  ];

  /// Bipy memegang tongkat bintang (klaim berhasil).
  static const AssetImage poseStar = AssetImage(
    'assets/bipy/bipy_pose_bintang.webp',
    package: _package,
  );

  /// Bipy memegang mawar (bonus hari ke-7).
  static const AssetImage poseRose = AssetImage(
    'assets/bipy/bipy_pose_mawar.webp',
    package: _package,
  );

  /// Bipy melompat gembira.
  static const AssetImage poseCelebrate = AssetImage(
    'assets/bipy/bipy_pose_rayakan.webp',
    package: _package,
  );

  /// Bipy melompat memegang bintang (produk gratis 30 hari).
  static const AssetImage poseStarJump = AssetImage(
    'assets/bipy/bipy_pose_lompat_bintang.webp',
    package: _package,
  );

  /// Stiker bunga pink.
  static const AssetImage stickerFlowerPink = AssetImage(
    'assets/fx/stiker_bunga_pink.webp',
    package: _package,
  );

  /// Stiker bunga kuning.
  static const AssetImage stickerFlowerYellow = AssetImage(
    'assets/fx/stiker_bunga_kuning.webp',
    package: _package,
  );

  /// Stiker kilau empat sudut.
  static const AssetImage stickerSparkle = AssetImage(
    'assets/fx/stiker_kilau.webp',
    package: _package,
  );

  /// Stiker bintang.
  static const AssetImage stickerStar = AssetImage(
    'assets/fx/stiker_bintang.webp',
    package: _package,
  );

  /// Stiker hati.
  static const AssetImage stickerHeart = AssetImage(
    'assets/fx/stiker_hati.webp',
    package: _package,
  );

  /// Tahap tulip 0..4 untuk [monthDay] hari terisi (0–6, 7–13, 14–20,
  /// 21–29, 30).
  static int tulipStage(int monthDay) {
    if (monthDay >= 30) return 4;
    if (monthDay >= 21) return 3;
    if (monthDay >= 14) return 2;
    if (monthDay >= 7) return 1;
    return 0;
  }
}

/// Lembar sprite Bipy milik modul.
abstract final class CheckInSprites {
  /// Bipy berdiri dan berkedip (bolak-balik).
  static const SpriteSheetSpec idle = SpriteSheetSpec(
    asset: 'assets/bipy/bipy_diam.webp',
    package: _package,
    columns: 8,
    rows: 3,
    frameCount: 22,
    frameSize: Size(188, 340),
    loopMode: SpriteLoopMode.pingPong,
  );

  /// Bipy melompat dengan tangan terbuka (sekali).
  static const SpriteSheetSpec jump = SpriteSheetSpec(
    asset: 'assets/bipy/bipy_lompat.webp',
    package: _package,
    columns: 7,
    rows: 3,
    frameCount: 21,
    frameSize: Size(200, 372),
    loopMode: SpriteLoopMode.once,
  );
}
