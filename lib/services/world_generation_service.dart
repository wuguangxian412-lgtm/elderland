import '../models/player.dart';
import 'save_service.dart';
import 'world_service.dart';

/// 初始世界生成服务。
///
/// 创建角色后、进入主页面前调用。加载页会等待这个服务完成，
/// 因此后续 AI 生成世界内容、生成 NPC 初始记忆、写入 world_save 等逻辑，
/// 都应该优先放到这里，而不是塞进 GameMainPage。
class WorldGenerationService {
  const WorldGenerationService();

  /// 生成新角色进入游戏前所需的初始世界内容。
  ///
  /// 当前版本先使用 3 秒占位加载，后续接入 AI 后改为真实异步生成耗时。
  /// 后续接入 AI 时，可以把这里替换成真实异步任务：
  /// - AI 生成人物背景 / 初始经历；
  /// - AI 生成 NPC 初始记忆；
  /// - AI 生成村庄近期状态；
  /// - 保存 player_save / world_save；
  /// - 返回更新后的 Player。
  Future<Player> generateInitialWorld({
    required Player player,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('世界生成中...');

    // 先初始化世界基础数据，避免把这一步完全留到 GameMainPage。
    await WorldService().initialize();

    // 临时模拟 AI 世界生成耗时。
    // 后续这里会替换为真正的 AI / 世界生成异步流程，不再固定 3 秒。
    await Future<void>.delayed(const Duration(seconds: 3));

    // 当前占位阶段不修改 player，先保存初始玩家状态。
    await SaveService().savePlayer(player);
    await WorldService().saveWorldState();

    return player;
  }
}
