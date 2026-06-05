import '../models/player.dart';

/// 时间推进系统
///
/// 管理游戏内时间推进逻辑。
class TimeService {
  /// 春/夏/秋/冬 各季节天数上限
  static const int _daysPerSeason = 90;

  /// 季节轮转顺序
  static const List<String> _seasonCycle = ['春', '夏', '秋', '冬'];

  /// 推进一天，返回新的 Player 状态。
  static Player advanceOneDay(Player player) {
    var newDay = player.day + 1;
    var newSeason = player.season;
    var newYear = player.year;

    // 超过季节天数上限时切换季节
    if (newDay > _daysPerSeason) {
      newDay = 1;
      final currentIndex = _seasonCycle.indexOf(player.season);
      final nextIndex = (currentIndex + 1) % _seasonCycle.length;
      newSeason = _seasonCycle[nextIndex];

      // 冬→春时年份+1，年龄不变
      if (player.season == '冬' && newSeason == '春') {
        newYear = player.year + 1;
      }
    }

    return player.copyWith(
      day: newDay,
      season: newSeason,
      year: newYear,
    );
  }
}
